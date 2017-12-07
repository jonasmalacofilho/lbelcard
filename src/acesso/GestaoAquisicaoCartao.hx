package acesso;

class GestaoAquisicaoCartao extends GestaoBase {
	static inline var ENDPOINT =
			"https://servicos.acessocard.com.br/api2.0/Services/rest/GestaoAquisicaoCartao.svc";

	public function SolicitarAdesaoCliente(params:SolicitarAdesaoClienteParams):{ newUser:Bool, client:ClientGuid }
	{
		var res:Response = request(ENDPOINT, "solicitar-adesao-cliente", params);
		switch res.ResultCode {
		case 0:
			return { newUser:true, client:(res.Data:ClientGuid) };
		case 1:
			return { newUser:false, client:(res.Data:ClientGuid) };
		case err:
			throw PermanentError("Other", res.ResultCode);
		}
	}

	public function SolicitarCartaoIdentificado(params:SolicitarCartaoIdentificadoParams):CardGuid
	{
		var res:Response = request(ENDPOINT, "SolicitarCartaoIdentificado", params);
		switch res.ResultCode {
		case 0: return (res.Data:CardGuid);
		case err: throw PermanentError("Other", res.ResultCode);
		}
	}
}

