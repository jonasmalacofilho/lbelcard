import eweb._impl.ToraRawShare;
import neko.vm.*;

class ProcessingQueue {
	var queue:Array<Null<Void->Void>> = [];
	var lock:Mutex = new Mutex();
	var worker:Thread;

	public function new() {}

	public function addTask(task:Null<Void->Void>)
	{
		trace('queue: add task');
		lock.acquire();
		queue.push(task);
		if (worker == null)
			worker = Thread.create(initWorker);
		lock.release();
	}

	function initWorker()
	{
		trace('queue: init worker thread');
		var self = Module.local();
		var module = Module.readPath(self.name + ".n", [], self.loader());
		module.setExport(NAME, workerLoop);
		module.execute();
	}

	function workerLoop()
	{
		trace('queue: init worker loop');
		while (true) {
			lock.acquire();
			var task = queue.shift();
			if (task == null) {
				worker = null;
				lock.release();
				break;
			}
			lock.release();
			task();
		}
		trace('queue: terminate worker');
	}

	/**
		Allow the processing queue to take control of the module, if applicable

		Returns true if control was taken, in which case the module is no longer
		needed anymore; all resources should be freed and the module should be
		terminated.

		Otherwise return false, and normal execution of the module can be resumed.
	 **/
	public static function handOver():Bool
	{
		var loop = Module.local().getExports()[NAME];
		if (loop != null) {
			trace('queue: init worker module');
			loop();
			return true;
		}
		return false;
	}

	static inline var NAME = "processing-queue-worker-loop";
}

