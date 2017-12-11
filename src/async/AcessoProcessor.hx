package async;

import Environment.*;
import acesso.*;
import acesso.Data;
import db.Types.AcessoError;

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
		} catch (err:AcessoError) {
			trace('acesso: returned $err (${card.requestId})');
			card.state = Failed(err, card.state);
			card.update();
			switch err {
			case TransportError(msg):
				// network error: wait a bit and then resume working
				Sys.sleep(60);
				async.Queue.global().addTask(key);  // renqueue this task
			case TemporarySystemError({ Message:msg, ResultCode: 99 }) if (msg.indexOf("ValidarToken") > 0):
				// token must have expired: wait a bit, refresh it, and resume working
				Sys.sleep(3);
				token = null;
				async.Queue.global().addTask(key);  // renqueue this task
			case _:
				// nothing to do for user/data or other system errors
			}
		}
	}

	function loop()
	{
		while (true) {
			switch card.state {
			case Failed(TransportError(_)|TemporarySystemError(_), onState):
				card.state = onState;
				continue;

			case Queued(_) if (token == null):
				var params = { Email:ACESSO_USERNAME, Senha:ACESSO_PASSWORD };
				token = GestaoBase.CriarToken(params);

			case Queued(SolicitarAdesaoCliente):
				var data:SolicitarAdesaoClienteData = {
					CodEspecieProduto : card.product,
					Usuario : card.userData
				}
				var client = new GestaoAquisicaoCartao(token).SolicitarAdesaoCliente(data);
				if (client.newUser)
					card.state = Queued(SolicitarCartaoIdentificado(client.client));
				else
					card.state = Queued(AlterarEnderecoPortador(client.client));
				card.update();
			case Queued(AlterarEnderecoPortador(client)):
				var data:AlterarEnderecoPortadorData = {
					CodCliente : card.userData.CodCliente,
					NovoEndereco : card.userData.Endereco,
					TokenAdesao : client,
					TpCliente : card.userData.TpCliente
				}
				new GestaoPortador(token).AlterarEnderecoPortador(data);
				card.state = Queued(SolicitarAlteracaoEmailPortador(client));
				card.update();

			case Queued(SolicitarAlteracaoEmailPortador(client)):
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
				card.state = Queued(ConfirmarSolicitacaoAlteracaoEmailPortador(client, tounce));
				card.update();

			case Queued(ConfirmarSolicitacaoAlteracaoEmailPortador(client, tounce)):
				var data:ConfirmarSolicitarAlteracaoEmailPortadorData = {
					CodCliente : card.userData.CodCliente,
					TokenSolicitacaoAlteracao : tounce,
					TokenAdesao : client,
					TpCliente : card.userData.TpCliente
				}
				var confirmTounce = new GestaoPortador(token).ConfirmarSolicitarAlteracaoEmailPortador(data);
				card.state = Queued(EfetivarAlteracaoEmailPortador(client, confirmTounce));
				card.update();

			case Queued(EfetivarAlteracaoEmailPortador(client, tounce)):
				var data:EfetivarAlteracaoEmailPortadorData = {
					CodCliente : card.userData.CodCliente,
					TokenEfetivacaoAlteracao : tounce,
					TokenAdesao : client,
					TpCliente : card.userData.TpCliente
				}
				new GestaoPortador(token).EfetivarAlteracaoEmailPortador(data);
				card.state = Queued(SolicitarAlteracaoTelefonePortador(client));
				card.update();

			case Queued(SolicitarAlteracaoTelefonePortador(client)):
				var data:SolicitarAlteracaoTelefonePortadorData = {
					CodCliente : card.userData.CodCliente,
					DDD : card.userData.Celular.DDD,
					DDI : card.userData.Celular.DDI,
					Numero : card.userData.Celular.Numero,
					TokenAdesao : client,
					TpCliente : card.userData.TpCliente
				}
				var tounce = new GestaoPortador(token).SolicitarAlteracaoTelefonePortador(data);
				card.state = Queued(ConfirmarAlteracaoTelefonePortador(client, tounce));

			case Queued(ConfirmarAlteracaoTelefonePortador(client, tounce)):
				var data:ConfirmarAlteracaoTelefonePortadorData = {
					CodCliente : card.userData.CodCliente,
					Token : tounce,
					TokenAdesao : client,
					TpCliente : card.userData.TpCliente
				}
				new GestaoPortador(token).ConfirmarAlteracaoTelefonePortador(data);
				card.state = Queued(ComplementarDadosPrincipais(client));
				card.update();

			case Queued(ComplementarDadosPrincipais(client)):
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
				card.state = Queued(SolicitarCartaoIdentificado(client));
				card.update();

			case Queued(_):
				trace('acesso: stopping on ${card.state} (not implemented or unsafe at the moment)');
				break;  // FIXME remove

			case Queued(SolicitarCartaoIdentificado(client)):
				var data:SolicitarCartaoIdentificadoData = {
					CodCliente : card.userData.CodCliente,
					CodEspecieProduto : card.product,
					TokenAdesao : client,
					TpCliente : card.userData.TpCliente,
					TpEntrega : Carta_Simples,
					ValorCarga : 0.
				}
				var req = new GestaoAquisicaoCartao(token).SolicitarCartaoIdentificado(data);
				card.state = Queued(ConfirmarPagamento(req.card, req.cost));
				card.update();

			case Queued(ConfirmarPagamento(req, cost)):
				// FIXME call the appropriate API
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
				card.submitting = false;

			case AwaitingBearerData, AwaitingBearerConfirmation:
				assert(false, card.state);
				break;

			case SendEmail:
				new sendgrid.Email(card.userData.NomeCompleto, card.userData.Email, 'https://lbelcard.com.br/novo/status/${card.requestId}').execute();
				card.state = Queued(SolicitarAdesaoCliente);
				card.update();


			case Failed(_), CardRequested:
				break;  // nothing to do
			}

			// rate limit
			Sys.sleep(0.1);
		}
	}
}

