package db;

class RemoteCallLog extends sys.db.Object {
	public var id:SId;
	public var url:String;
	public var method:String;
	public var created:SNull<Timestamp>;  // nullable for backwards compatibility

	public var requestHeaders:SNull<SData<Array<String>>>;
	public var requestPayload:SNull<String>;

	public var responseHeaders:SNull<SData<Array<String>>>;
	public var responseCode:SNull<Int>;
	public var responseData:SNull<String>;
	public var timing:SNull<Float>;

	public function new(url, method)
	{
		super();
		this.url = url;
		this.method = method;
		this.created = Date.now();
	}
}

