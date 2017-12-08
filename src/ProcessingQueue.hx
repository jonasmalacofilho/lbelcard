import eweb._impl.ToraRawShare;
import neko.vm.*;

class ProcessingQueue {
	var queue:Array<Null<Void->Void>> = [];
	var lock:Mutex = new Mutex();
	var master:Module;
	var worker:Thread;

	public function new()
	{
		master = Module.local();
	}

	public function addTask(task:Null<Void->Void>)
	{
		trace('queue: add task');
		lock.acquire();
		queue.push(task);
		if (worker == null)
			worker = Thread.create(initWorker);
		lock.release();
	}

	public function refreshCode(master:Module)
	{
		lock.acquire();
		if (this.master.codeSize() != master.codeSize()) {  // FIXME use load time and check name
			// update the master module
			this.master = master;
			if (worker != null) {
				// update the worker code
				//  - ask the current worker to terminate itself before executing any more tasks
				//  - switch to a new instance of the queue (that the old worker wont see)
				//  - start a new worker (that will only see the new queue)
				queue.unshift(null);
				queue = queue.slice(1);
				worker = Thread.create(initWorker);
			}
		}
		lock.release();
	}

	function initWorker()
	{
		trace('queue: init worker thread');
		var module = Module.readPath(master.name + ".n", [], master.loader());
		module.setExport(NAME, workerLoop);
		module.execute();
	}

	function workerLoop()
	{
		trace('queue: init worker loop');
		var localQueue = queue;  // make the worker blind to queue replacement (for worker updates)
		while (true) {
			lock.acquire();
			var task = localQueue.shift();
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

