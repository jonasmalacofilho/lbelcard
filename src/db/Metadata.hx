package db;

@:id(name)
class Metadata extends sys.db.Object {
	public var name:SString<256>;
	public var value:SData<Dynamic>;

	public function new(name)
	{
		super();
		this.name = name;
	}
}

