package db.types;

import acesso.Data;

enum CardRequestError {
	TransportError(err:String);

	AcessoUserOrDataError(res:Response<Dynamic>);
	AcessoTemporaryError(res:Response<Dynamic>);
	AcessoPermanentError(res:Response<Dynamic>);
	AcessoTokenError(err:Response<Dynamic>);

	SendGridError(status:Int, response:String);

	JumpToError(err:Response<Dynamic>, jumpTo:CardRequestState);
}

