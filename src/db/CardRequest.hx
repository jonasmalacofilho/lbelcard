package db;

enum CardRequestState {
	AwaitingBearerData;
	AwaitingBearerConfirmation;
	AwaitingAcessoMembershipRequest;
	AwaitingAcessoEmissionRequest;
	AwaitingAcessoPaymentConfirmationRequest;
	CardRequested;
}

@:id(clientKey)
class CardRequest extends sys.db.Object {
	public var clientKey:String;
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

