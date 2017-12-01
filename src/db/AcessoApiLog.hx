package db;

class AcessoApiLog extends sys.db.Object {
	public var id:SId;
	public var url:String;
	public var method:String;

	public var requestHeaders:SNull<SData<Array<String>>>;
	public var requestPayload:SNull<String>;

	public var responseHeaders:SNull<SData<Array<String>>>;
	public var responseCode:SNull<Int>;
	public var responseData:SNull<String>;

	public function new(url, method)
	{
		super();
		this.url = url;
		this.method = method;
	}
}

