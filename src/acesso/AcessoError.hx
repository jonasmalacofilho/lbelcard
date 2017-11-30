package acesso;

enum AcessoError {
	TransportError(err:String, statusCode:Int);
	TemporaryError(err:String, resultCode:String);
	PermanentError(err:String, resultCode:String);
}

