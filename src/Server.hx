import eweb.ManagedModule;
import eweb.Web;

class Server {
	public static var requestId(default,null):String;
	public static var shortId(default,null):String;

	static var stderr = Sys.stderr();

	static function main()
	{
		initModule();
		if (ManagedModule.cacheAvailable) {
			ManagedModule.runAndCache(handleRequest);
		} else {
			handleRequest();
			ManagedModule.callFinalizers();
		}
	}

	static function initModule()
	{
		var ini_t = Sys.time();

		haxe.Log.trace = function (msg, ?pos) ctrace(shortId, msg, pos);
		ManagedModule.log = function (msg, ?pos) ctrace("mmgr", msg, pos);
		ManagedModule.addModuleFinalizer(crypto.Random.global.close, "random");

#if dev
		sys.db.Manager.cnx = sys.db.Sqlite.open(":memory:");
#else
		assert(Environment.MAIN_DB != null && Environment.MAIN_DB.indexOf("sqlite3://") == 0, Environment.MAIN_DB);
		sys.db.Manager.cnx = sys.db.Sqlite.open(Environment.MAIN_DB.substr(0, "sqlite3://".length));
#end
		// TODO init tables
		ManagedModule.addModuleFinalizer(sys.db.Manager.cnx.close, "db/main");

		trace('time: ${since(ini_t)} ms on module initialization');
	}

	static function handleRequest()
	{
		var req_t = Sys.time();

		try {

			requestId = crypto.Random.global.readHex(16);
			shortId = requestId.substr(0, 4);
			var method = Web.getMethod().toUpperCase();
			var uri = Web.getURI();
			if (uri == "")
				uri = "/";
			trace('begin: $method $uri ($requestId)');

			Web.setHeader("X-Request-ID", requestId);
			// TODO replace with dynamic dispatch
			Web.setReturnCode(200);
			Sys.println("Hello!");
			trace('done: ${since(req_t)} ms to $method $uri');

		} catch (err:Dynamic) {
			try
				Web.setReturnCode(500)
			catch (_:Dynamic)
				trace('could not set response status to 500 anymore');
			var stack = StringTools.trim(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
			trace('ERROR after ${since(req_t)} ms: $err', stack);
			if (ManagedModule.cacheEnabled)
				ManagedModule.uncache();
			ManagedModule.callFinalizers();
		}

		shortId = requestId = null;
	}

	static inline function since(ref:Float)
		return Math.round((Sys.time() - ref)*1e3);

	static function ctrace(id:String, msg:Dynamic, ?pos:haxe.PosInfos)
	{
		var lines = [msg].concat(pos.customParams != null ? pos.customParams : []).join("\n").split("\n");
		stderr.writeString('[$id] ${lines[0]}  @${pos.className}:${pos.methodName}  (${pos.fileName}:${pos.lineNumber})\n');
		for (i in 1...lines.length)
			stderr.writeString('[$id] .. ${lines[i]}\n');
	}
}

