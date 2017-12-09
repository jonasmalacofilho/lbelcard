package db;

@:id(requestId)
class CardRequest extends sys.db.Object {
	public var requestId:SString<64>;
	@:relation(bearerId) public var bearer:BelUser;
	public var state:SData<CardRequestState>;
	public var submitting:Bool;  // overlaps with state but required for fast recovery

	public function new(bearer)
	{
		super();
		this.requestId = crypto.Random.global.readHex(32);  // 256 bits
		this.bearer = bearer;
		this.state = AwaitingBearerData;
		this.submitting = false;
	}
}

