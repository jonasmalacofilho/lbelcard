package db;

import acesso.Data;

enum CardRequestState {
	AwaitingBearerData;
	AwaitingBearerConfirmation;
	Queued(step:AcessoStep);
	Failed(err:AcessoError, onState:CardRequestState);
	CardRequested;
	// UserNotified(ofState:CardRequestState);  // idea on how to handle emails
}

enum AcessoStep {
	SolicitarAdesaoCliente;
	AlterarEnderecoPortador(client:TokenAdesao);
	SolicitarAlteracaoEmailPortador(client:TokenAdesao);
	ConfirmarSolicitacaoAlteracaoEmailPortador(client:TokenAdesao, tounce:TokenAlteracao);
	EfetivarAlteracaoEmailPortador(client:TokenAdesao, tounce:TokenAlteracao);
	SolicitarAlteracaoTelefonePortador(client:TokenAdesao);
	ConfirmarAlteracaoTelefonePortador(client:TokenAdesao, tounce:TokenAlteracao);
	ComplementarDadosPrincipais(client:TokenAdesao);
	SolicitarCartaoIdentificado(client:TokenAdesao);
	ConfirmarPagamento(card:TokenCartao, cost:Float);
}

enum AcessoError {
	TransportError(err:String);
	UserOrDataError(res:Response<Dynamic>);
	TemporarySystemError(res:Response<Dynamic>);
	PermanentSystemError(res:Response<Dynamic>);

	AccessTokenError(err:Response<Dynamic>);
	JumpToError(err:Response<Dynamic>, step:AcessoStep);
}

