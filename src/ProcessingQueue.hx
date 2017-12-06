import eweb._impl.ToraRawShare;
import neko.vm.*;

class ProcessingQueue {
	public static function isWorkerInstance()
		return Module.local().getExports()[NAME] == "worker";

	/**
	Allow the processing queue to take control of the module, if it created it

	Returns true if control was taken, in which case the module is no longer
	needed anymore; all resources should be freed and the module should be
	terminated.

	Otherwise return false, and normal execution of the module can be resumed.
	**/
	public static function handleControl():Bool
	{
		if (isWorkerInstance()) {
			trace('queue: init worker module');
			var q = getShare().get(true);
			q.workerLoop();
			getShare().commit();
			return true;
		}
		return false;
	}

	public static function addTask(task:Null<Void->Void>)
	{
		trace('queue: add task');
		getShare().get(true).queue.push(task);
		getShare().commit();
	}

	static inline var NAME = "belcard-processing-queue";

	static function getShare():ToraRawShare<ProcessingQueue>
		return new ToraRawShare(NAME, ProcessingQueue.new);

	var queue:Array<Null<Void->Void>>;
	var worker:Thread;

	function new()
	{
		queue = [];
		worker = Thread.create(initWorker);
	}

	function initWorker()
	{
		trace('queue: init worker thread');
		var self = Module.local();
		var workerModule = Module.readPath(self.name + ".n", [], self.loader());
		workerModule.setExport(NAME, "worker");
		workerModule.execute();
	}

	function workerLoop()
	{
		trace('queue: init worker loop');
		while (true) {
			getShare().get(true);
			var task = queue.shift();
			if (task == null) {
					getShare().free();
					break;
			}
			getShare().commit();
			task();
		}
		trace('queue: terminate worker loop');
	}
}

