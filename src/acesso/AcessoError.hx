package acesso;

enum AcessoError {
	TransportError(err:String);
	TemporaryError(err:String, resultCode:Int);
	PermanentError(err:String, resultCode:Int);
}

