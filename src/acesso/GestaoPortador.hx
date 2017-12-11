package acesso;

class GestaoPortador extends GestaoBase {
	static inline var ENDPOINT =
			"https://servicos.acessocard.com.br/api2.0/Services/rest/GestaoPortador.svc";

	public function new(token)
		super(token);

	public function AlterarEnderecoPortador(data:AlterarEnderecoPortadorData):Void
	{
		var res:Response<Void> = request(ENDPOINT, "alterar-endereco-portador", data);
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
		var res:Response<TokenAlteracao> = request(ENDPOINT, "solicitar-alteracao-email-portador", data);
		switch res.ResultCode {
		case 0:
			return res.Data;
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
		var res:Response<{ TokenEfetivacao:TokenAlteracao }> =
				request(ENDPOINT, "confirmar-solicitacao-alteracao-email-portador", data);
		switch res.ResultCode {
		case 0:
			return res.Data.TokenEfetivacao;
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
		var res:Response<Void> = request(ENDPOINT, "efetivar-alteracao-email-portador", data);
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

	public function SolicitarAlteracaoTelefonePortador(data:SolicitarAlteracaoTelefonePortadorData):TokenAlteracao
	{
		var res:Response<{ TokenSolicitacao:TokenAlteracao }> =
				request(ENDPOINT, "solicitar-alteracao-telefone-portador", data);
		switch res.ResultCode {
		case 0:
			return res.Data.TokenSolicitacao;
		case 2, 3, 5, 6, 7:  // data mismatch, missing data, invalid phonenumber, already registred (to another user?), blacklisted
			throw UserOrDataError(res);
		case 10:  // error during persisting
			throw TemporarySystemError(res);
		case err:
			throw PermanentSystemError(res);
		}
	}

	public function ConfirmarAlteracaoTelefonePortador(data:ConfirmarAlteracaoTelefonePortadorData):Void
	{
		var res:Response<Void> = request(ENDPOINT, "confirmar-alteracao-telefone-portador", data);
		switch res.ResultCode {
		case 0:
			// all ok, nothing more to do
		case 1:  // data mismatch
			throw UserOrDataError(res);
		case 2, 3:  // invalid request token
			throw JumpToError(res, AcessoStep.SolicitarAlteracaoEmailPortador(data.TokenAdesao));
		case 4, 5:  // error during persisting, processing
			throw TemporarySystemError(res);
		case err:
			throw PermanentSystemError(res);
		}
	}

	public function ComplementarDadosPrincipais(data:ComplementarDadosPrincipaisData):Void
	{
		var res:Response<Void> = request(ENDPOINT, "complementar-dados-principais", data);
		switch res.ResultCode {
		case 0:
			// all ok, nothing more to do
		case 5, 6, 7, 8:  // data error: birthday|min, birthday|max, credit bureau search, mother's name
			throw UserOrDataError(res);
		case 4:  // error during persisting
			throw TemporarySystemError(res);
		case err:
			throw PermanentSystemError(res);
		}
	}
}

