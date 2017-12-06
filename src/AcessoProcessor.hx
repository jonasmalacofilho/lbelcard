import Environment.*;
import acesso.*;
import acesso.AcessoError;
import acesso.Data;

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
		card = db.CardRequest.manager.select($clientKey == key);
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
			switch err {
			case TransportError(msg):
				neko.Lib.rethrow(err);  // FIXME reenqueue
			case TemporaryError(msg, code):
				neko.Lib.rethrow(err);  // FIXME reenqueue
			case PermanentError(msg, code):
				card.state = Failed(false, msg, card.state);
				card.update();
			}
		}
	}
}

