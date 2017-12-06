package db;

enum AcessoStep {
	SolicitarAdesaoCliente;
	AlterarEnderecoPortador;
	SolicitarAlteracaoEmailPortador;
	ConfirmarSolicitacaoAlteracaoEmailPortador;
	EfetivarAlteracaoEmailPortador;
	SolicitarAlteracaoTelefonePortador;
	ConfirmarAlteracaoTelefonePortador;
	ComplementarDadosPrincipais;
	SolicitarCartaoIdentificado;
	ConfirmarPagamento;
}

enum CardRequestState {
	AwaitingBearerData;
	AwaitingBearerConfirmation;
	Queued(step:AcessoStep);
	Processing(step:AcessoStep);
	Failed(userError:Bool, msg:String, onState:CardRequestState);
	CardRequested;
}

@:id(clientKey)
class CardRequest extends sys.db.Object {
	//FIXME - 512 is a placeholder and this can't be a pure string...
	//b/c ...record-macros!
	public var clientKey:SString<512>;
	@:relation(bearerId) public var bearer:BelUser;
	public var state:SData<CardRequestState>;
	
	public function new(bearer)
	{
		super();
		this.clientKey = crypto.Random.global.readHex(32);
		this.bearer = bearer;
		this.state = AwaitingBearerData;
	}
}

