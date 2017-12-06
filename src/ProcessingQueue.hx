import eweb._impl.ToraRawShare;
import neko.vm.Deque;
import neko.vm.Thread;
import neko.vm.*;

class ProcessingQueue {
	/**
	Allow the processing queue to take control of the module, if it created it

	Returns true if control was taken, in which case the module is no longer
	needed anymore; all resources should be freed and the module should be
	terminated.

	Otherwise return false, and normal execution of the module can be resumed.
	**/
	public static function control():Bool
	{
		var self = Module.local();
		show(self.getExports()[NAME]);
		if (self.getExports()[NAME] == "worker") {
			var q = getGlobal();
			q.workerLoop();
			return true;
		}
		return false;
	}

	public static function getGlobal():ProcessingQueue
		return new ToraRawShare(NAME, ProcessingQueue.new).get(false);

	public function addTask(task:Null<Void->Void>)
		deque.add(task);

	static inline var NAME = "belcard-processing-queue";

	var deque:Deque<Null<Void->Void>>;
	var workers:Array<Thread>;

	function new()
	{
		deque = new Deque();
		workers = [ for (i in 0...2) Thread.create(initWorker) ];
	}

	function initWorker()
	{
		var self = Module.local();
		var workerModule = Module.readPath(self.name + ".n", [], self.loader());
		workerModule.setExport(NAME, "worker");
		workerModule.execute();
	}

	function workerLoop()
	{
		while (true) {
			var task = deque.pop(true);
			if (task == null)
				break;
			weakAssert(false);
		}
	}
}

