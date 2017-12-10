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

			switch card.state {
			case Queued(_) if (token == null):
				var params = { Email:ACESSO_USERNAME, Senha:ACESSO_PASSWORD };
				token = new GestaoBase().CriarToken(params);
			case Queued(SolicitarAdesaoCliente):
				var client = new GestaoAquisicaoCartao().SolicitarAdesaoCliente(null);
				if (client.newUser)
					card.state = Queued(SolicitarCartaoIdentificado);
				else
					card.state = Queued(AlterarEnderecoPortador);
				card.update();
			case Queued(AlterarEnderecoPortador):
				// FIXME call the appropriate API
				card.state = Queued(SolicitarAlteracaoEmailPortador);
			case Queued(SolicitarAlteracaoEmailPortador):
				// FIXME call the appropriate API
				card.state = Queued(ConfirmarSolicitacaoAlteracaoEmailPortador);
			case Queued(ConfirmarSolicitacaoAlteracaoEmailPortador):
				// FIXME call the appropriate API
				card.state = Queued(EfetivarAlteracaoEmailPortador);
			case Queued(EfetivarAlteracaoEmailPortador):
				// FIXME call the appropriate API
				card.state = Queued(SolicitarAlteracaoTelefonePortador);
			case Queued(SolicitarAlteracaoTelefonePortador):
				// FIXME call the appropriate API
				card.state = Queued(ConfirmarAlteracaoTelefonePortador);
			case Queued(ConfirmarAlteracaoTelefonePortador):
				// FIXME call the appropriate API
				card.state = Queued(ComplementarDadosPrincipais);
			case Queued(ComplementarDadosPrincipais):
				// FIXME call the appropriate API
				card.state = Queued(SolicitarCartaoIdentificado);
			case Queued(SolicitarCartaoIdentificado):
				// FIXME call the appropriate API
				card.state = Queued(ConfirmarPagamento);
			case Queued(ConfirmarPagamento):
				// FIXME call the appropriate API
				card.state = CardRequested;
			case _: assert(false);
			}

		} catch (err:AcessoError) {
			card.state = Failed(err, card.state);
			card.update();
			switch err {
			case TransportError(msg):
				// network error: wait a bit and then resume working
				Sys.sleep(60);
				ProcessingQueue.global().addTask(key);  // renqueue this task
			case TemporarySystemError({ Message:msg, ResultCode: 99 }) if (msg.indexOf("ValidarToken") > 0):
				// token must have expired: wait a bit, refresh it, and resume working
				Sys.sleep(3);
				token = null;
				ProcessingQueue.global().addTask(key);  // renqueue this task
			case _:
				// nothing to do for user/data or other system errors
			}
		}
	}
}

