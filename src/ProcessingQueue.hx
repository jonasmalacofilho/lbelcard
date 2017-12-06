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
		if (worker == null) {
			trace('queue: init worker thread');
			worker = Thread.create(workerLoop);
		}
		lock.release();
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
		trace('queue: terminate worker loop');
	}
}

