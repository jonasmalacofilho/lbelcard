package acesso;

import db.types.CardRequestState;

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
		case 4, 14, 15, 16, 19:  // error in cep, neighborhood, city or state... or when updating
			throw AcessoUserOrDataError(res);
		case err:
			throw AcessoPermanentError(res);
		}
	}

	public function SolicitarAlteracaoEmailPortador(data:SolicitarAlteracaoEmailPortadorData):TokenAlteracao
	{
		var res:Response<TokenAlteracao> = request(ENDPOINT, "solicitar-alteracao-email-portador", data);
		switch res.ResultCode {
		case 0:
			return res.Data;
		case 2, 3, 4, 5:  // data mismatch, invalid email, already registred (to another user?), blacklisted
			throw AcessoUserOrDataError(res);
		case err:
			throw AcessoPermanentError(res);
		}
	}

	public function ConfirmarSolicitarAlteracaoEmailPortador(data:ConfirmarSolicitarAlteracaoEmailPortadorData):TokenAlteracao
	{
		var res:Response<{ TokenEfetivacao:TokenAlteracao }> =
				request(ENDPOINT, "confirmar-solicitacao-alteracao-email-portador", data);
		switch res.ResultCode {
		case 0:
			return res.Data.TokenEfetivacao;
		case 1, 3:  // request token expired or invalid
			throw JumpToError(res, AcessoCard(AcessoCardStep.SolicitarAlteracaoEmailPortador(data.TokenAdesao)));
		case 4:  // invalid access token
			throw AcessoTokenError(res);
		case err:
			throw AcessoPermanentError(res);
		}
	}

	public function EfetivarAlteracaoEmailPortador(data:EfetivarAlteracaoEmailPortadorData):Void
	{
		var res:Response<Void> = request(ENDPOINT, "efetivar-alteracao-email-portador", data);
		switch res.ResultCode {
		case 0, 7:
			// all ok or already updated, nothing more to do
		case 3:
			throw AcessoUserOrDataError(res);
		case 4, 5:  // request token expired or invalid
			throw JumpToError(res, AcessoCard(AcessoCardStep.SolicitarAlteracaoEmailPortador(data.TokenAdesao)));
		case err:
			throw AcessoPermanentError(res);
		}
	}

	public function SolicitarAlteracaoTelefonePortador(data:SolicitarAlteracaoTelefonePortadorData):TokenAlteracao
	{
		var res:Response<{ TokenSolicitacao:TokenAlteracao }> =
				request(ENDPOINT, "solicitar-alteracao-telefone-portador", data);
		switch res.ResultCode {
		case 0:
			return res.Data.TokenSolicitacao;
		case 2, 5, 6, 7:  // data mismatch, invalid phonenumber, already registred (to another user?), blacklisted
			throw AcessoUserOrDataError(res);
		case err:
			throw AcessoPermanentError(res);
		}
	}

	public function ConfirmarAlteracaoTelefonePortador(data:ConfirmarAlteracaoTelefonePortadorData):Void
	{
		var res:Response<Void> = request(ENDPOINT, "confirmar-alteracao-telefone-portador", data);
		switch res.ResultCode {
		case 0:
			// all ok, nothing more to do
		case 1:
			throw AcessoUserOrDataError(res);
		case 2, 3:  // invalid request token
			throw JumpToError(res, AcessoCard(AcessoCardStep.SolicitarAlteracaoEmailPortador(data.TokenAdesao)));
		case err:
			throw AcessoPermanentError(res);
		}
	}

	public function ComplementarDadosPrincipais(data:ComplementarDadosPrincipaisData):Void
	{
		var res:Response<Void> = request(ENDPOINT, "complementar-dados-principais", data);
		switch res.ResultCode {
		case 0:
			// all ok, nothing more to do
		case 4, 5, 6, 7, 8:  // data error: persisting (i.e. validation), birthday|min, birthday|max, credit bureau search, mother's name
			throw AcessoUserOrDataError(res);
		case err:
			throw AcessoPermanentError(res);
		}
	}
}

