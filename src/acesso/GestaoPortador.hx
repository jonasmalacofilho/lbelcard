package acesso;

class GestaoPortador extends GestaoBase {
	static inline var ENDPOINT =
			"https://servicos.acessocard.com.br/api2.0/Services/rest/GestaoPortador.svc";

	public function new(token)
		super(token);

	public function AlterarEnderecoPortador(data:AlterarEnderecoPortadorData):Void
	{
		var res:Response = request(ENDPOINT, "alterar-endereco-portador", data);
		switch res.ResultCode {
		case 0:
			// all ok, nothing more to do
		case 4, 14, 15, 16:  // error in: cep, neighborhood, city, state
			throw UserOrDataError(res);
		case 17, 18, 19, 20:  // error while: persisting, processing, updating, database
			throw TemporarySystemError(res);
		case err:
			throw PermanentSystemError(res);
		}
	}

	public function SolicitarAlteracaoEmailPortador(data:SolicitarAlteracaoEmailPortadorData):TokenAlteracao
	{
		var res:Response = request(ENDPOINT, "solicitar-alteracao-email-portador", data);
		switch res.ResultCode {
		case 0:
			return (res.Data:TokenAlteracao);
		case 2, 3, 4, 5:  // data mismatch, invalid email, already registred (to another user?), blacklisted
			throw UserOrDataError(res);
		case 6:  // error during persisting
			throw TemporarySystemError(res);
		case err:
			throw PermanentSystemError(res);
		}
	}

	public function ConfirmarSolicitarAlteracaoEmailPortador(data:ConfirmarSolicitarAlteracaoEmailPortadorData):TokenAlteracao
	{
		var res:Response = request(ENDPOINT, "confirmar-solicitacao-alteracao-email-portador", data);
		switch res.ResultCode {
		case 0:
			// the response from this api is not standard
			// the tounce we expect is encapsulated in a (useless) object
			var tounce = untyped res.Data.TokenEfetivacao;
			assert(tounce != null);
			return (tounce:TokenAlteracao);
		case 1, 3:  // request token: expired, invalid
			throw JumpToError(res, AcessoStep.SolicitarAlteracaoEmailPortador(data.TokenAdesao));
		case 4:  // invalid access token
			throw AccessTokenError(res);
		case 8:  // error during persisting
			throw TemporarySystemError(res);
		case err:
			throw PermanentSystemError(res);
		}
	}

	public function EfetivarAlteracaoEmailPortador(data:EfetivarAlteracaoEmailPortadorData):Void
	{
		var res:Response = request(ENDPOINT, "efetivar-alteracao-email-portador", data);
		switch res.ResultCode {
		case 0:
			// all ok, nothing more to do
		case 3:  // data mismatch
			throw UserOrDataError(res);
		case 4, 5:  // request token: expired, invalid
			throw JumpToError(res, AcessoStep.SolicitarAlteracaoEmailPortador(data.TokenAdesao));
		case 8, 10:  // error during: persisting, processing
			throw TemporarySystemError(res);
		case err:
			throw PermanentSystemError(res);
		}
	}
}

