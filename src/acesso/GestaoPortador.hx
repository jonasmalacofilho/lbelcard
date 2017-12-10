package acesso;

class GestaoPortador extends GestaoBase {
	static inline var ENDPOINT =
			"https://servicos.acessocard.com.br/api2.0/Services/rest/GestaoPortador.svc";

	public function AlterarEnderecoPortador(params:AlterarEnderecoPortadorParams):Void
	{
		var res:Response = request(ENDPOINT, "alterar-endereco-portador", params);
		switch res.ResultCode {
		case 0:
			// all ok, nothing more to do
		case 17, 18, 19, 20:
			throw TemporarySystemError(res);
		case err:
			throw PermanentSystemError(res);
		}
	}

	public function SolicitarAlteracaoEmailPortador(params:SolicitarAlteracaoEmailPortadorParams):TokenAlteracao
	{
		var res:Response = request(ENDPOINT, "solicitar-alteracao-email-portador", params);
		switch res.ResultCode {
		case 0:
			return (res.Data:TokenAlteracao);
		case 6:
			throw TemporarySystemError(res);
		case err:
			throw PermanentSystemError(res);
		}
	}
}


