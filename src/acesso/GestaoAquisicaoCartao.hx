package acesso;

class GestaoAquisicaoCartao extends GestaoBase {
	public function SolicitarAdesaoCliente(params:SolicitarAdesaoClienteParams):{ newUser:Bool, client:ClientGuid }
		return request(Endpoint.GESTAO_AQUISICAO_CARTAO, "SolicitarAdesaoCliente", params,
			function (res:{ Data:String, ResultCode:String })
			{
				assert(res.Data != null && res.ResultCode != null, res);
				switch res.ResultCode {
				case "00": return { newUser:true, client:(res.Data:ClientGuid) };
				case "01": return { newUser:false, client:(res.Data:ClientGuid) };
				case err: throw PermanentError("Other", res.ResultCode);
				}
			});

	public function SolicitarCartaoIdentificado(params:SolicitarCartaoIdentificadoParams):CardGuid
		return request(Endpoint.GESTAO_AQUISICAO_CARTAO, "SolicitarCartaoIdentificado", params,
			function (res:{ Data:String, ResultCode:String })
			{
				assert(res.Data != null && res.ResultCode != null, res);
				switch res.ResultCode {
				case "00": return (res.Data:CardGuid);
				case err: throw PermanentError("Other", res.ResultCode);
				}
			});
}

