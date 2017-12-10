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
			show(card.requestId, card.state);

			switch card.state {
			case Failed(TransportError(_)|TemporarySystemError(_), onState):
				card.state = onState;

			case Queued(_) if (token == null):
				var params = { Email:ACESSO_USERNAME, Senha:ACESSO_PASSWORD };
				token = new GestaoBase().CriarToken(params);

			case Queued(SolicitarAdesaoCliente):
				var data:SolicitarAdesaoClienteParams = {
					Language : REST,
					NomeCanal : Webservice,
					RecId : 42,
					TokenAcesso : token,
					Data : {
						CodEspecieProduto : card.product,
						Usuario : card.userData
					}
				}
				var client = new GestaoAquisicaoCartao().SolicitarAdesaoCliente(data);
				if (client.newUser)
					card.state = Queued(SolicitarCartaoIdentificado);
				else
					card.state = Queued(AlterarEnderecoPortador);
				card.update();

			case Queued(_):
				break;  // FIXME temporary early exit (remove)

			// case Queued(AlterarEnderecoPortador):
			// 	// FIXME call the appropriate API
			// 	card.state = Queued(SolicitarAlteracaoEmailPortador);
			//
			// case Queued(SolicitarAlteracaoEmailPortador):
			// 	// FIXME call the appropriate API
			// 	card.state = Queued(ConfirmarSolicitacaoAlteracaoEmailPortador);
			//
			// case Queued(ConfirmarSolicitacaoAlteracaoEmailPortador):
			// 	// FIXME call the appropriate API
			// 	card.state = Queued(EfetivarAlteracaoEmailPortador);
			//
			// case Queued(EfetivarAlteracaoEmailPortador):
			// 	// FIXME call the appropriate API
			// 	card.state = Queued(SolicitarAlteracaoTelefonePortador);
			//
			// case Queued(SolicitarAlteracaoTelefonePortador):
			// 	// FIXME call the appropriate API
			// 	card.state = Queued(ConfirmarAlteracaoTelefonePortador);
			//
			// case Queued(ConfirmarAlteracaoTelefonePortador):
			// 	// FIXME call the appropriate API
			// 	card.state = Queued(ComplementarDadosPrincipais);
			//
			// case Queued(ComplementarDadosPrincipais):
			// 	// FIXME call the appropriate API
			// 	card.state = Queued(SolicitarCartaoIdentificado);
			//
			// case Queued(SolicitarCartaoIdentificado):
			// 	// FIXME call the appropriate API
			// 	card.state = Queued(ConfirmarPagamento);
			//
			// case Queued(ConfirmarPagamento):
			// 	// FIXME call the appropriate API
			// 	card.state = CardRequested;
			// 	card.submitting = false;

			case AwaitingBearerData, AwaitingBearerConfirmation:
				assert(false, card.state);
				break;

			case Failed(_), CardRequested:
				break;  // nothing to do
			}
		}
	}
}

