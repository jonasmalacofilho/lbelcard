import eweb._impl.ToraRawShare;
import neko.vm.*;

class ProcessingQueue {
	static inline var NAME = "global-processing-queue";

	var queue:Array<Null<Void->Void>> = [];
	var lock:Mutex = new Mutex();
	var master:Module = Module.local();
	var worker:Thread;

	function new() {}

	/**
		Access the global processing queue

		If no queue exists, one will be created.
	**/
	public static function global():ProcessingQueue
	{
		// don't lock the share initially
		// if where calling from a queue module, we can't using this lock
		var share = new ToraRawShare(NAME);
		var inst = share.get(false);
		if (inst != null)
			return inst;

		// if there was no global queue, we can't possibly be running from a queue module
		// thus, it's safe to lock the share now, so that we can initialize a queue
		inst = share.get(true);
		if (inst == null) {
			inst = new ProcessingQueue();
			share.set(inst);
		}
		share.commit();
		return inst;
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

	function initWorker()
	{
		trace('queue: init worker thread');
		var module = Module.readPath(master.name + ".n", [], master.loader());
		module.setExport(NAME, this);
		module.execute();
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
		var inst = Module.local().getExports()[NAME];
		if (inst != null) {
			trace('queue: init worker module');
			inst.workerLoop();
			return true;
		}
		return false;
	}

	function workerLoop()
	{
		trace('queue: init worker loop (${master.codeSize()})');
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

	public function refreshCode(master:Module)
	{
		lock.acquire();
		if (this.master.codeSize() != master.codeSize()) {  // FIXME use load time and check name
			trace('queue: refresh code (${this.master.codeSize()} => ${master.codeSize()})');
			// update the master module
			this.master = master;
			if (worker != null) {
				trace('queue: restart the worker');
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
}

