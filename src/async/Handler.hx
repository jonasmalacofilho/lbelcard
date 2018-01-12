package async;

import neko.vm.*;

class Handler {
	static inline var NAME = "global-processing-queue";

	var queue:Array<Null<String>> = [];
	var lock:Mutex = new Mutex();

	@:access(async.Queue)
	function new(inst:Queue)
	{
		queue = inst.queue;
		lock = inst.lock;
	}

	/**
		Allow the queue handler to take control of the module, if applicable

		Returns true if control was taken, in which case the module is no longer
		needed; all resources should be freed and the module should be terminated.

		Otherwise returns false, and normal execution of the module can be resumed.
	 **/
	@:access(Server)
	public static function handOver():Bool
	{
		var inst:Queue = Module.local().getExports()[NAME];
		if (inst != null) {
			Server.shortId = Server.requestId = 'async-${crypto.Random.global.readHex(2)}';
			sys.db.Manager.cnx.request("PRAGMA busy_timeout=10000");
			trace(NOTICE + 'async: init handler, busy_timeout extended (${Server.codeVersion})');
			var h = new Handler(inst);
			h.loop();
			return true;
		}
		return false;
	}

	function loop()
	{
		trace('async: init loop (${Server.codeVersion})');
		while (true) {
			lock.acquire();
			var task = queue.shift();
			if (task == "shutdown") {
				trace('async: shutdown loop');
				lock.release();
				break;
			} else if (task != null) {
				trace('async: ${queue.length + 1} tasks in the system');
			}
			lock.release();
			if (task == null) {
				Sys.sleep(.05);
				continue;
			}
			try {
				switch task.split(":") {
				case ["sleep", s]:
					Sys.sleep(Std.parseFloat(s));
				case _:
					var p = new async.AcessoProcessor(task);
					p.execute();
				}
			} catch (err:Dynamic) {
				var stack = StringTools.trim(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
				trace(ERR + 'async: task errored with $err', stack);
			}
			sys.db.Manager.cleanup();
		}
		trace(WARNING + 'async: loop terminated');
	}
}

