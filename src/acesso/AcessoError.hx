package acesso;

enum AcessoError {
	TransportError(err:String);
	TemporaryError(err:String, resultCode:String);
	PermanentError(err:String, resultCode:String);
}

