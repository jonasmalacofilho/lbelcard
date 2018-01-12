package db.types;

import acesso.Data;

enum CardRequestError {
	/**
	Temporary network error
	**/
	TransportError(err:String);

	/**
	Request failure due AcessoCard refusing the supplied data

	This is final.
	**/
	AcessoUserOrDataError(res:Response<Dynamic>);

	/**
	AcessoCard's temporary failure to process the request
	**/
	AcessoTemporaryError(res:Response<Dynamic>);

	/**
	AcessoCard's presumably unrecoverable error

	This error wraps all failures returned by AcessoCard that cannot be
	confidently interpreted.

	This can be treated as final, but **the server will still attempt to
	recover** from this after an upgrade.
	
	Historically, this error has mostly been set by bugs (caused by Acesso's
	imprecise documentation) or straight-up Acesso bugs.
	**/
	AcessoPermanentError(res:Response<Dynamic>);

	/**
	AcessoCard's temporary failure to accept token
	**/
	AcessoTokenError(err:Response<Dynamic>);

	/**
	SendGrid API error

	This error is final.  However, future (minor) upgrades might change this.
	**/
	SendGridError(status:Int, response:String);

	/**
	Failure, jumping backwards or forwards required
	**/
	JumpToError(err:Response<Dynamic>, jumpTo:CardRequestState);
}

