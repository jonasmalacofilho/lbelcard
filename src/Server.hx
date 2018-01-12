import eweb.ManagedModule;
import eweb.Web;

class Server {
	public static var requestId(default,null):String;
	public static var shortId(default,null):String;
	public static var codeVersion(default,null):Float;
	public static var serverVersion(default,null) = "1.1.4";
	public static var schemaVersion(default,null) = 2;
#if dev
	public static var userAgent = 'LBELCard-dev (localhost) Neko Haxe';  // TODO add neko and haxe versions [automatically]
#else
	public static var userAgent = 'LBELCard/$serverVersion (lbelcard.com.br) Neko Haxe';  // TODO add neko and haxe versions [automatically]
#end

	static var stderr = Sys.stderr();

	static function main()
	{
		assert(ManagedModule.cacheAvailable, "queue assumes tora (although we can fix this)");

		initModule();

		if (async.Handler.handOver()) {
			ManagedModule.callFinalizers();
			return;
		}
		async.Queue.global().upgrade(neko.vm.Module.local(), codeVersion);

		attemptRecovery();
		ManagedModule.runAndCache(handleRequest);
	}

	static function initModule()
	{
		var ini_t = Sys.time();

		haxe.Log.trace = function (msg, ?pos) ctrace(shortId, msg, pos);
		ManagedModule.log = function (msg, ?pos) ctrace("eweb", msg, pos);
		ManagedModule.addModuleFinalizer(crypto.Random.global.close, "random");

		trace('init: L\'BEL Card v$serverVersion');
		assert(Math.abs(vehjo.Timezone.localTimezone()/1000/3600) < 9,
				"might fail to convert datestrings into timestamps or SerializedDate");

		assert(Environment.ACESSO_USERNAME != null);
		assert(Environment.ACESSO_PASSWORD != null);
		assert(Environment.ACESSO_PRODUCT != null);

		var modulePath = '${neko.vm.Module.local().name}.n';
		codeVersion = sys.FileSystem.stat(modulePath).mtime.getTime();

		assert(Environment.MAIN_DB != null && Environment.MAIN_DB.indexOf("sqlite3://") == 0,
				Environment.MAIN_DB);
		var dbPath = Environment.MAIN_DB.substr("sqlite3://".length);
		trace('sqlite: open $dbPath');
		var cnx = sys.db.Manager.cnx = sys.db.Sqlite.open(dbPath);
		ManagedModule.addModuleFinalizer(cnx.close, "db/main");

		// this init and setup code can only handle SQLite
		assert(cnx.dbName() == "SQLite");

		var integrityCheck = cnx.request("PRAGMA integrity_check(1)");
		if (integrityCheck.getResult(0) != "ok") {
			show(integrityCheck.getResult(0));
			throw('sqlite: failed integrity check');
		}
		trace('sqlite: passed integrity check');

		cnx.request("PRAGMA busy_timeout=5000");
		trace('sqlite: busy_timeout set');
		var journalMode = cnx.request("PRAGMA journal_mode").getResult(0);
		if (journalMode == "delete") {
			cnx.request("PRAGMA page_size=4096");
			cnx.request("VACUUM");
			cnx.request("PRAGMA journal_mode=wal");
			trace('sqlite: page_size and journal_mode set');
		}

		sys.db.Manager.initialize();
		var allTables:Array<sys.db.Manager<Dynamic>> = [
			db.BelUser.manager,
			db.CardRequest.manager,
			db.Metadata.manager,
			db.RemoteCallLog.manager
		];

		cnx.request("BEGIN TRANSACTION");
		try {
			var missing = 0;
			for (m in allTables) {
				if (sys.db.TableCreate.exists(m))
					continue;  // it would be nice to also assert the schema
				missing++;
				sys.db.TableCreate.create(m);
				trace('sqlite: created missing table ${m.dbInfos().name}');
			}
			if (missing == allTables.length) {
				// if we created the entire schema, it's current
				var dbVersion = new db.Metadata("schemaVersion");
				dbVersion.value = schemaVersion;
				dbVersion.insert();
			}
			cnx.request("COMMIT");
		} catch (err:Dynamic) {
			cnx.request("ROLLBACK");
			neko.Lib.rethrow(err);
		}

		Fixes.apply();

		/*
		Check the database schema version; assuming a single tora instance and no
		manual changes to the schemaVersion metadata it's enough to check it here,
		instead of before handling every request.
		*/
		var dbVersion = db.Metadata.manager.get("schemaVersion");
		assert(dbVersion != null && dbVersion.value == schemaVersion, dbVersion.value, schemaVersion);

		trace('time: ${since(ini_t)} ms on module initialization');
	}

	static function attemptRecovery()
	{
		var share = new eweb._impl.ToraRawShare("recovery-has-run");
		var lastRecovery:Null<Float> = share.get(true);
		try {
			if (lastRecovery == null || codeVersion > lastRecovery) {
				trace('recovery: reenqueue requests');
				var q = async.Queue.global();
				for (card in db.CardRequest.manager.search($queued == true)) {
					weakAssert(card.state.match(SendEmail | AcessoCard(_) | Failed(_)),
							card.requestId, card.queued, Type.enumConstructor(card.state),
							"forgot to set queued to off");
					// this is heuristic, the queue handler is supposed to figure out
					// wheather it should actually process the request; however, we are
					// confident that we can never recover from user/data errors
					if (card.state.match(Failed(AcessoUserOrDataError(_), _)))
						continue;
					q.addTask(card.requestId);
				}
				share.set(codeVersion);
			}
			share.commit();
		} catch (err:Dynamic) {
			share.commit();
			neko.Lib.rethrow(err);
		}
	}

	static function handleRequest()
	{
		var req_t = Sys.time();

		try {

			requestId = crypto.Random.global.readHex(16);
			shortId = requestId.substr(0, 4);
			var ip = Web.getClientIP();
			var method = Web.getMethod().toUpperCase();
			var params = Web.getParams();
			var uri = Web.getURI();
			if (uri == "")
				uri = "/";
			trace('begin: $method $uri from $ip ($requestId)');

			Web.setHeader("X-Request-ID", requestId);
			var d = new eweb.Dispatch(uri, params, method);
			d.dispatch(new route.Index());
			sys.db.Manager.cleanup();
			trace('done: ${since(req_t)} ms to $method $uri');

		} catch (err:eweb.Dispatch.DispatchError) {
			var stack = StringTools.trim(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
			trace('done: could not route after ${since(req_t)} ms: $err', stack);
			try {
				switch err {
				case DENotFound(part):
					Web.setReturnCode(404);
					Sys.println(views.Base.render("Ops", views.Error.render.bind("Não encontramos a página que você buscava.")));
				case DEInvalidValue | DEMissing | DEMissingParam(_) | DETooManyValues:
					Web.setReturnCode(404);
					Sys.println(views.Base.render("Ops", views.Error.render.bind(null)));
				}
			} catch (err2:Dynamic) {
				abort(req_t, err2, 400);
			}
		} catch (err:RequestError) {
			switch err {
			case SecurityError(err, userMsg, clean):
				abort(req_t, err, 400, userMsg, clean);
			}
		} catch (err:Dynamic) {
			abort(req_t, err, 500);
		}

		shortId = requestId = null;
	}

	static function abort(req_t:Float, err:Dynamic, status:Int, ?userMessage:String, clean=false)
	{
		try
			Web.setReturnCode(status)
		catch (_:Dynamic)
			trace('could not set response status to $status anymore');
		try
			Sys.println(views.Base.render("Ops", views.Error.render.bind(userMessage)))
		catch (_:Dynamic)
			trace('could not return error view anymore');
		var stack = StringTools.trim(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
		trace('ERROR after ${since(req_t)} ms: $err', stack);
		if (!clean) {
			if (ManagedModule.cacheEnabled)
				ManagedModule.uncache();
			ManagedModule.callFinalizers();
		}
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

