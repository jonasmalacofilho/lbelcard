package acesso;

class GestaoAquisicaoCartao extends GestaoBase {
	static inline var ENDPOINT =
			"https://servicos.acessocard.com.br/api2.0/Services/rest/GestaoAquisicaoCartao.svc";

	public function new(token)
		super(token);

	public function SolicitarAdesaoCliente(data:SolicitarAdesaoClienteData):{ newUser:Bool, client:TokenAdesao }
	{
		var res:Response<TokenAdesao> = request(ENDPOINT, "solicitar-adesao-cliente", data);
		switch res.ResultCode {
		case 0:
			return { newUser:true, client:res.Data };
		case 1:
			return { newUser:false, client:res.Data };
		case 2, 5, 6:
			throw AcessoUserOrDataError(res);
		case 99:
			throw AcessoTokenError(res);
		case err:
			throw AcessoPermanentError(res);
		}
	}

	public function SolicitarCartaoIdentificado(data:SolicitarCartaoIdentificadoData):{ card:TokenCartao, cost:Float }
	{
		var res:Response<{ TokenCartao:TokenCartao, ValorTotal:Float }> =
				request(ENDPOINT, "solicitar-cartao-identificado", data);
		switch res.ResultCode {
		case 0:
			return { card:res.Data.TokenCartao, cost:res.Data.ValorTotal };
		case err:
			throw AcessoPermanentError(res);
		}
	}

	public function ConfirmarPagamento(data:ConfirmarPagamentoData):Void
	{
		var res:Response<Void> = request(ENDPOINT, "confirmar-pagamento", data);
		switch res.ResultCode {
		case 0:
			// all ok, nothing more to do
		case err:
			throw AcessoPermanentError(res);
		}
	}
}

