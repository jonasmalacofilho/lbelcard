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
		trace('processor: working on $key');
		card = db.CardRequest.manager.select($requestId == key);
		assert(card != null, key);
		try {
			loop();
		} catch (err:CardRequestError) {
			card.state = Failed(err, card.state);
			card.update();

			switch err {
			case AcessoTokenError(_):
				trace('processor: bad AcessoCard access token, discarding and reenqueing');
				token = null;
				async.Queue.global().addTask(key);  // renqueue this task
			case AcessoTemporaryError(res) | AcessoPermanentError(res) if (res.ResultCode == 99):
				trace('processor: (presumably) bad AcessoCard access token, discarding and reenqueing');
				weakAssert(res.Message.indexOf("ValidarToken") >= 0, res);
				token = null;
				async.Queue.global().addTask(key);  // renqueue this task
			case TransportError(_):
				trace('processor: network error, waiting a bit and reenqueuing');
				Sys.sleep(10);
				async.Queue.global().addTask(key);  // renqueue this task
			case AcessoTemporaryError(_) | JumpToError(_):
				trace('processor: (presumably) temporary AcessoCard error, reenqueuing');
				weakAssert(token == null, "error dispatched by something other than CriarToken",
						Type.enumConstructor(err));
				Sys.sleep(60);
				async.Queue.global().addTask(key);  // renqueue this task
			case _:
				trace('processor: cannot recover from $err');
			}
		}
	}


	function loop()
	{
		var userCnt = null, globalCnt = null;
		while (true) {
			// only need to check once, but loop might start Failed
			if (userCnt == null && card.state.match(SendEmail | AcessoCard(_))) {
				// to count within SQLite, compute the serialized value of CardRequested
				var requested = {
					var s = new haxe.Serializer();
#if RECORD_MACROS_USE_ENUM_NAME
					s.useEnumIndex = false;
#end
					s.serialize(CardRequested);
					haxe.io.Bytes.ofString(s.toString());
				}
				userCnt = db.CardRequest.manager.count($bearer == card.bearer && $state == requested);
				globalCnt = db.CardRequest.manager.count($state == requested);
				show(userCnt, globalCnt);
				if (userCnt > 0) {
					trace('failsafe: request limit reached (user ${card.bearer.belNumber})');
					// FIXME switch to proper error
					var msg = "Atingido o limite de solicitação de cartões para esse consultor";
					throw AcessoUserOrDataError({ ResultCode:-1, Message:msg, FieldErrors:[{ ResultCode:-1, Message:msg }], Data:null });
				}
			}

			rateLimit(card.state);

			switch card.state {
			case Failed(AcessoUserOrDataError(_), _) | CardRequested:
				// nothing to do for user errors or if request has finished processing
				break;

			case Failed(JumpToError(_, resume), _):
				// jump to errors require as to jump (back) before retrying
				card.state = resume;
				continue;

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

#if (dev || !unlock_actual_cards)
			case AcessoCard(_):
				trace('dev-build: stopping on ${card.state} due to failsafe');
				break;  // do *not* remove this
#end

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
				/**
				Acesso does not correctly validate payment timestamps when after
				midnight UTC until midnight BRT.

				They have been alerted to the issue, but have yet to fix it.

				For now, lets supply a timestamp older enough (see hack bellow) that it
				doesn't trigger the issue (even considering unsynchronized time).
				**/
				var data:ConfirmarPagamentoData = {
					AgenciaRecebedora : "",
					AgenciaRecebedoraDV : "",
					BancoRecebedor : "",
					DataPagamento : DateTools.delta(Date.now(), - DateTools.hours(6)),  // hack
					TokenOperacao : req,
					TpMeioPagamento : Outros,
					TpOperacao : Embossing_Cartao,
					ValorPagamento : cost
				}
				show(cost);
				if (cost >= 5)
					throw 'failsafe: card cost exceedes our expectations (R$$ $cost)';
				new GestaoAquisicaoCartao(token).ConfirmarPagamento(data);
				card.state = CardRequested;
				card.queued = false;
				card.update();

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
			// SendGrid rate limit is 1000 req/s
			Sys.sleep(0.001);
		case AcessoCard(_):
			// AcessoCard rate limit is 5 req/s; however, the fastest logged request
			// took 160 ms and we see no possibility of being able to sustain 5 req/s
			Sys.sleep(0.005);
		case _:
			// nothing to do
		}
	}
}

