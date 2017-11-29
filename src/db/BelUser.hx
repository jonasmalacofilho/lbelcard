package db;

@:id(belNumber)
class BelUser extends sys.db.Object {
	public var belNumber:Int;

	public function new(belNumber)
	{
		super();
		this.belNumber = belNumber;
	}
}

