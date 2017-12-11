package acesso;

class GestaoAquisicaoCartao extends GestaoBase {
	static inline var ENDPOINT =
			"https://servicos.acessocard.com.br/api2.0/Services/rest/GestaoAquisicaoCartao.svc";

	public function new(token)
		super(token);

	public function SolicitarAdesaoCliente(data:SolicitarAdesaoClienteData):{ newUser:Bool, client:TokenAdesao }
	{
		var res:Response = request(ENDPOINT, "solicitar-adesao-cliente", data);
		switch res.ResultCode {
		case 0:
			return { newUser:true, client:(res.Data:TokenAdesao) };
		case 1:
			return { newUser:false, client:(res.Data:TokenAdesao) };
		case 5, 6:  // error in: reduced data, complete data
			throw UserOrDataError(res);
		case 99:  // [undocumented] invalid token
			throw TemporarySystemError(res);
		case err:
			throw PermanentSystemError(res);
		}
	}
}

