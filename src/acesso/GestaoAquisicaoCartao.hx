package acesso;

class GestaoAquisicaoCartao extends GestaoBase {
	static inline var URL =
			"https://servicos.acessocard.com.br/api2.0/Services/rest/GestaoAquisicaoCartao.svc";

	public function SolicitarAdesaoCliente(params:SolicitarAdesaoClienteParams):{ newUser:Bool, client:ClientGuid }
	{
		var res:{ Data:String, ResultCode:String } = request(URL, "SolicitarAdesaoCliente", params);
		assert(res.Data != null && res.ResultCode != null, res);
		switch res.ResultCode {
		case "00": return { newUser:true, client:(res.Data:ClientGuid) };
		case "01": return { newUser:false, client:(res.Data:ClientGuid) };
		case err: throw PermanentError("Other", res.ResultCode);
		}
	}

	public function SolicitarCartaoIdentificado(params:SolicitarCartaoIdentificadoParams):CardGuid
	{
		var res:{ Data:String, ResultCode:String } = request(URL, "SolicitarCartaoIdentificado", params);
		assert(res.Data != null && res.ResultCode != null, res);
		switch res.ResultCode {
		case "00": return (res.Data:CardGuid);
		case err: throw PermanentError("Other", res.ResultCode);
		}
	}
}

