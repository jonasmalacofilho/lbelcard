package db;

class BelUser extends sys.db.Object {
	public var id:SId;
	public var belNumber:String;
	public var cpf:String;

	public function new(belNumber, cpf)
	{
		super();
		this.belNumber = belNumber;
		this.cpf = cpf;
	}
}

