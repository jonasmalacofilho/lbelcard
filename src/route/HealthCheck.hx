package route;

import db.types.CardRequestState;
import eweb.Web;
import eweb._impl.ToraRawShare;
import haxe.CallStack;

class HealthCheck {
	var now:Float;

	public function new() {}

	public function getDefault(args:{ key:String, ?Werror:Bool })
	{
		var auth = db.Metadata.manager.get("healthCheckKey");
		if (auth == null) {
			trace(ERR + 'abort: the health check endpoint has not been enabled');
			throw eweb.Dispatch.DispatchError.DENotFound("healthCheck");
		}
		assert(Std.is(auth.value, String));
		if (auth.value != args.key) {
			trace(CRIT + 'abort: endpoint key does not match');
			Sys.sleep(Math.random()*.01);
			throw eweb.Dispatch.DispatchError.DENotFound("healthCheck");
		}

		// assumption: both warnings and errors generate notifications, but over
		// different priorities (e.g. warnings go to slack/emails, errors go to phones)

		now = Sys.time();
		var buf = [];
		var errors = [];  // not seen by the client
		try {
			// use prime cache times to minimize refreshing more than one value at a time
			withCache(checkDb, "database", 929, buf, errors);
			checkHandler(buf, errors);
			checkQueueSize(buf, errors);
			checkEnabled(buf, errors);
			withCache(checkAcessoCard, "acesso-card", 911, buf, errors);
			withCache(checkRequests, "permament-errors", 67, buf, errors);
		} catch (err:Dynamic) {
			var stack = StringTools.trim(CallStack.toString(CallStack.exceptionStack()));
			buf.push('health check: uncaught exception (ERR)');
			errors.push('uncaught exception: $err\n$stack');
		}

		for (i in errors)
			trace(ERR + i);
		var warnings = false;
		var pwarn = ~/[ ]+\(WARNING\)/;
		for (i in buf) {
			if (pwarn.match(i)) {
				trace(WARNING + pwarn.matchedLeft() + pwarn.matchedRight());
				warnings = true;
			}
		}

		if (errors.length == 0 && (!args.Werror || !warnings)) {
			buf.push("summary: all ok");
			Web.setReturnCode(200);
		} else {
			buf.push("summary: ERR");
			Web.setReturnCode(500);
		}
		Web.setHeader("Content-Type", "text/plain; charset=utf-8");
		Sys.println(buf.join("\n"));
	}

	function withCache(check, checkName, cacheTime, buf, errors)
	{
		// perform `check` and cache it, or retrieve it from cache
		var shareName = 'health-check-cache:$checkName';
		var share = new ToraRawShare(shareName);

		var last:{ time:Float, lbuf:Array<String>, lerrors:Array<String> } = share.get(false);
		if (last != null && now - last.time <= cacheTime) {
			for (i in last.lbuf)
				buf.push(i + " (cached result)");
			for (i in last.lerrors)
				errors.push(i + " (cached result)");
			return;
		}

		share.get(true);
		var lbuf = [], lerrors = [];
		check(lbuf, lerrors);
		last = { time:now, lbuf:lbuf, lerrors:lerrors };
		share.set(last);
		share.commit();
		for (i in last.lbuf)
			buf.push(i);
		for (i in last.lerrors)
			errors.push(i);
	}

	function checkDb(buf, errors)
	{
		// is the database healthy?
		var integrityCheck = sys.db.Manager.cnx.request("PRAGMA integrity_check");
		if (integrityCheck.getResult(0) == "ok") {
			buf.push("database: ok");
		} else {
			buf.push("database: failed integrity check (EMERG)");
			for (i in integrityCheck)
				errors.push('database problem: ${integrityCheck.getResult(0)}');
		}
	}

	function checkHandler(buf, errors)
	{
		// is the queue handler live and healthy?
		var lastAck = async.Queue.global().lastAck;
		if (now - lastAck <= 5*60) {
			buf.push("handler: live");
		} else {
			buf.push("handler: awol (CRIT)");
			errors.push('handler awol for ${Math.round(now - lastAck)} seconds');
		}
	}

	function checkQueueSize(buf, errors)
	{
		// is the queue size bounded?
		var queueSize = async.Queue.global().peekSize();
		if (queueSize < Novo.LIMIT_QUEUE_SIZE >> 1) {
			buf.push('queue size: $queueSize');
		} else {
			// while the server is expected to handle this gracefully, this is very
			// abnormal and a human should be notified immediately
			buf.push('queue size: $queueSize (CRIT)');
			errors.push('critical queue size: $queueSize');
		}
	}

	function checkEnabled(buf, errors)
	{
		// are we refusing users? (warn only)
		var disabled = db.Metadata.manager.get("disabled");
		buf.push('enabled: ${disabled == null ? "yes" : "no (WARNING)"}');  // note: disabled != down
	}

	function checkAcessoCard(buf, errors)
	{
		// did we successfully talk to Acesso recently? (warn only)

		// call now
		try {
			var params = { Email:Environment.ACESSO_USERNAME, Senha:Environment.ACESSO_PASSWORD };
			var token = acesso.GestaoBase.CriarToken(params);
			assert(token != null);
		} catch (err:db.types.CardRequestError) {}

		// compute successfull calls over a period of time
		var recently = now*1000 - DateTools.hours(1);  // RemoteCallLog.created is a Haxe timestamp in ms
		var recentCalls = db.RemoteCallLog.manager.search($url.like("https://servicos.acessocard.com.br/%") &&
				$responseCode == 200 && $created != null && $created > recently && $timing != null);
		var timings = [];
		for (i in recentCalls) {
			var res:Dynamic = try haxe.Json.parse(i.responseData) catch (_:Dynamic) {};
			if (res == null || res.ResultCode != 0 ||
					(res.ResultCode == 1 && StringTools.endsWith(i.url, "solicitar-adesao-cliente")))
				continue;
			timings.push(i.timing);
		}

		if (timings.length != 0) {
			var avg = Lambda.fold(timings, function (i, pre) return pre + i, 0)/timings.length;
			buf.push('acesso card: ${avg < 2 ? "good" : "slow"}');
		} else {
			buf.push("acesso card: unreacheable (WARNING)");
		}
	}

	function checkRequests(buf, errors)
	{
		// are there any permanent failed requests? (warn only)

		function serialize(v:Dynamic)
		{
			var s = new haxe.Serializer();
#if RECORD_MACROS_USE_ENUM_NAME
			s.useEnumIndex = false;
#end
			s.serialize(v);
			return s.toString();
		}

		function genLikePattern(state, ?stopAt)
		{
			var t = serialize(state);
			if (stopAt != null) {
				var s = serialize(stopAt);
				if (t.indexOf(s) >= 0)
					t = t.substr(0, t.indexOf(s)) + "%";
			}
			return haxe.io.Bytes.ofString(t);
		}

		var requested = genLikePattern(CardRequested);
		var total = db.CardRequest.manager.count($state == requested);
		buf.push('total requests: $total');

		// ignore requests already analyzed and for which recovery has been disabled
		var permanentError = genLikePattern(Failed(AcessoPermanentError(untyped "__stop__"), null), "__stop__");
		var broken = db.CardRequest.manager.count($queued == true && $state.like(permanentError));
		if (broken == 0)
			buf.push('broken requests: $broken');
		else
			buf.push('broken requests: $broken (WARNING)');
	}
}

