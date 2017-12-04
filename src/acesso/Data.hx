package acesso;

typedef FieldError = {
	Message:String
}

typedef Response = {
	ResultCode:Int,
	Message:String,
	FieldErrors:Null<Array<FieldError>>,
	Data:Null<String>
}

abstract AccessToken(String) from String to String {}
abstract ClientGuid(String) from String to String {}
abstract CardGuid(String) from String to String {}

typedef SolicitarAdesaoClienteParams = Dynamic;
typedef SolicitarCartaoIdentificadoParams = Dynamic;

