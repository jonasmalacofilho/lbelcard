package db;

import acesso.Data;

@:id(requestId)
class CardRequest extends sys.db.Object {
	public var requestId:SString<64>;
	@:relation(bearerId) public var bearer:BelUser;

	public var state:SData<CardRequestState>;
	public var queued:Bool;  // redundant with state, but required for fast recovery

	public var product:Null<CodEspecieProduto>;
	public var userData:Null<SData<DadosDoUsuario>>;

	public var created:Null<Timestamp>;  // nullable for backwards compatibility
	public var lastUpdated:Null<Timestamp>;

	public function new(bearer)
	{
		super();
		this.requestId = crypto.Random.global.readHex(32);  // 256 bits
		this.bearer = bearer;
		created = lastUpdated = Date.now();
		state = AwaitingBearerData;
		queued = false;
	}

	override public function update()
	{
		lastUpdated = Date.now();
		super.update();
	}
}

