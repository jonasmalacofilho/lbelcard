package async;

import eweb._impl.ToraRawShare;
import neko.vm.*;

class Queue {
	static inline var NAME = "global-processing-queue";

	var queue:Array<Null<String>> = [];
	var lock:Mutex = new Mutex();
	var master:Module = Module.local();

	function new() {}

	/**
		Access the global processing queue

		If no queue exists, one will be created.
	**/
	public static function global():Queue
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
			trace('async: init queue (${Module.local().codeSize()})');
			inst = new Queue();
			share.set(inst);
			share.commit();
			inst.initWorker();
		} else {
			share.commit();
		}
		return inst;
	}

	function initWorker()
	{
		Thread.create(function () {
			var module = Module.readPath(master.name + ".n", [], master.loader());
			module.setExport(NAME, this);
			module.execute();
		});
	}

	/**
	Add a new task to the queue
	**/
	public function addTask(task:String)
	{
		trace('async: add $task (${Module.local().codeSize()})');
		lock.acquire();
		queue.push(task);
		lock.release();
	}

	public function upgrade(master:Module)
	{
		lock.acquire();
		if (this.master.codeSize() != master.codeSize()) {  // FIXME use load time and check name
			trace('async: upgrade (${this.master.codeSize()} => ${master.codeSize()} | ${Module.local().codeSize()})');
			// update the master module
			this.master = master;
			// update the worker code
			//  - ask the current worker to terminate itself before executing any more tasks
			//  - switch to a new instance of the queue (that the old worker wont see)
			//  - start a new worker (that will only see the new queue)
			queue.unshift("shutdown");
			queue = queue.slice(1);
			initWorker();
		}
		lock.release();
	}
}

