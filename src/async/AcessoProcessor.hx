package async;

import Environment.*;
import acesso.*;
import acesso.Data;
import db.types.CardRequestError;
import db.types.CardRequestState;

class AcessoProcessor {
	var key:String;
	var card:db.CardRequest;
	var token:TokenAcesso;

	public function new(key)
	{
		this.key = key;
	}

	public function execute()
	{
		card = db.CardRequest.manager.select($requestId == key);
		assert(card != null, key);
		try {
			loop();
		} catch (err:CardRequestError) {
			card.state = Failed(err, card.state);
			card.update();

			switch err {
			case TransportError(msg):
				trace('processor: network error, waiting a bit and reenqueuing');
				Sys.sleep(60);
				async.Queue.global().addTask(key);  // renqueue this task
			case AcessoTokenError(_) | AcessoTemporaryError({ Message:(_.indexOf("ValidarToken") >= 0)=>true, ResultCode: 99 }):
				trace('processor: bad AcessoCard acess token, discarding and reenqueing');
				token = null;
				async.Queue.global().addTask(key);  // renqueue this task
			case _:
				trace('processor: cannot recover from $err');
			}
		}
	}

	function loop()
	{
		while (true) {
			rateLimit(card.state);

			switch card.state {
			case Failed(AcessoUserOrDataError(_), _) | CardRequested:
				// nothing to do for user errors or if request has finished processing
				break;

			case Failed(_, onState):
				// consider that, if reenqueued, some errors that were otherwise
				// permanent might have been fixed by an upgrade
				card.state = onState;
				continue;

			case SendEmail:
				new sendgrid.Email(card.userData.NomeCompleto, card.userData.Email, 'https://lbelcard.com.br/novo/status/${card.requestId}').execute();
				card.state = AcessoCard(SolicitarAdesaoCliente);
				card.update();

			case AcessoCard(_) if (token == null):
				var params = { Email:ACESSO_USERNAME, Senha:ACESSO_PASSWORD };
				token = GestaoBase.CriarToken(params);

			case AcessoCard(SolicitarAdesaoCliente):
				var data:SolicitarAdesaoClienteData = {
					CodEspecieProduto : card.product,
					Usuario : card.userData
				}
				var client = new GestaoAquisicaoCartao(token).SolicitarAdesaoCliente(data);
				if (client.newUser)
					card.state = AcessoCard(SolicitarCartaoIdentificado(client.client));
				else
					card.state = AcessoCard(AlterarEnderecoPortador(client.client));
				card.update();
			case AcessoCard(AlterarEnderecoPortador(client)):
				var data:AlterarEnderecoPortadorData = {
					CodCliente : card.userData.CodCliente,
					NovoEndereco : card.userData.Endereco,
					TokenAdesao : client,
					TpCliente : card.userData.TpCliente
				}
				new GestaoPortador(token).AlterarEnderecoPortador(data);
				card.state = AcessoCard(SolicitarAlteracaoEmailPortador(client));
				card.update();

			case AcessoCard(SolicitarAlteracaoEmailPortador(client)):
				var data:SolicitarAlteracaoEmailPortadorData = {
					CodCliente : card.userData.CodCliente,
					NovoEmail : {
						EnderecoEmail : card.userData.Email,
						Principal : true,
						TpEmail : Residencial
					},
					TokenAdesao : client,
					TpCliente : card.userData.TpCliente
				}
				var tounce = new GestaoPortador(token).SolicitarAlteracaoEmailPortador(data);
				card.state = AcessoCard(ConfirmarSolicitacaoAlteracaoEmailPortador(client, tounce));
				card.update();

			case AcessoCard(ConfirmarSolicitacaoAlteracaoEmailPortador(client, tounce)):
				var data:ConfirmarSolicitarAlteracaoEmailPortadorData = {
					CodCliente : card.userData.CodCliente,
					TokenSolicitacaoAlteracao : tounce,
					TokenAdesao : client,
					TpCliente : card.userData.TpCliente
				}
				var confirmTounce = new GestaoPortador(token).ConfirmarSolicitarAlteracaoEmailPortador(data);
				card.state = AcessoCard(EfetivarAlteracaoEmailPortador(client, confirmTounce));
				card.update();

			case AcessoCard(EfetivarAlteracaoEmailPortador(client, tounce)):
				var data:EfetivarAlteracaoEmailPortadorData = {
					CodCliente : card.userData.CodCliente,
					TokenEfetivacaoAlteracao : tounce,
					TokenAdesao : client,
					TpCliente : card.userData.TpCliente
				}
				new GestaoPortador(token).EfetivarAlteracaoEmailPortador(data);
				card.state = AcessoCard(SolicitarAlteracaoTelefonePortador(client));
				card.update();

			case AcessoCard(SolicitarAlteracaoTelefonePortador(client)):
				var data:SolicitarAlteracaoTelefonePortadorData = {
					CodCliente : card.userData.CodCliente,
					DDD : card.userData.Celular.DDD,
					DDI : card.userData.Celular.DDI,
					Numero : card.userData.Celular.Numero,
					TokenAdesao : client,
					TpCliente : card.userData.TpCliente
				}
				var tounce = new GestaoPortador(token).SolicitarAlteracaoTelefonePortador(data);
				card.state = AcessoCard(ConfirmarAlteracaoTelefonePortador(client, tounce));

			case AcessoCard(ConfirmarAlteracaoTelefonePortador(client, tounce)):
				var data:ConfirmarAlteracaoTelefonePortadorData = {
					CodCliente : card.userData.CodCliente,
					Token : tounce,
					TokenAdesao : client,
					TpCliente : card.userData.TpCliente
				}
				new GestaoPortador(token).ConfirmarAlteracaoTelefonePortador(data);
				card.state = AcessoCard(ComplementarDadosPrincipais(client));
				card.update();

			case AcessoCard(ComplementarDadosPrincipais(client)):
				var data:ComplementarDadosPrincipaisData = {
					Documento : card.userData.Documento,
					DtNascimento : card.userData.DtNascimento,
					NomeMae : card.userData.NomeMae,
					TpSexo : card.userData.TpSexo,
					Portador : {
						CodCliente : card.userData.CodCliente,
						TokenAdesao : client,
						TpCliente : card.userData.TpCliente
					}
				}
				new GestaoPortador(token).ComplementarDadosPrincipais(data);
				card.state = AcessoCard(SolicitarCartaoIdentificado(client));
				card.update();

			case AcessoCard(_):
				trace('acesso: stopping on ${card.state} (not implemented or unsafe at the moment)');
				break;  // FIXME remove

			case AcessoCard(SolicitarCartaoIdentificado(client)):
				var data:SolicitarCartaoIdentificadoData = {
					CodCliente : card.userData.CodCliente,
					CodEspecieProduto : card.product,
					TokenAdesao : client,
					TpCliente : card.userData.TpCliente,
					TpEntrega : Carta_Simples,
					ValorCarga : 0.
				}
				var req = new GestaoAquisicaoCartao(token).SolicitarCartaoIdentificado(data);
				card.state = AcessoCard(ConfirmarPagamento(req.card, req.cost));
				card.update();

			case AcessoCard(ConfirmarPagamento(req, cost)):
				var data:ConfirmarPagamentoData = {
					AgenciaRecebedora : "",
					AgenciaRecebedoraDV : "",
					BancoRecebedor : "",
					DataPagamento : Date.now(),
					TokenOperacao : req,
					TpMeioPagamento : Outros,
					TpOperacao : Embossing_Carga_Cartao,
					ValorPagamento : cost
				}
				new GestaoAquisicaoCartao(token).ConfirmarPagamento(data);
				card.state = CardRequested;
				card.queued = false;

			case AwaitingBearerData, AwaitingBearerConfirmation:
				assert(false, card.state);
				break;
			}
		}
	}

	static function rateLimit(state:CardRequestState)
	{
		switch state {
		case SendEmail:
			Sys.sleep(0.01);  // less than SendGrid's 1000 req/s max
		case AcessoCard(_):
			Sys.sleep(0.2);  // at most AcessoCard's 5 req/s max
		case _:
			// nothing to do
		}
	}
}

