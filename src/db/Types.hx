package db;

enum CardRequestState {
	AwaitingBearerData;
	AwaitingBearerConfirmation;
	Queued(step:AcessoStep);
	Processing(step:AcessoStep);
	Failed(err:AcessoError, onState:CardRequestState);
	CardRequested;
}

enum AcessoStep {
	SolicitarAdesaoCliente;
	AlterarEnderecoPortador;
	SolicitarAlteracaoEmailPortador;
	ConfirmarSolicitacaoAlteracaoEmailPortador;
	EfetivarAlteracaoEmailPortador;
	SolicitarAlteracaoTelefonePortador;
	ConfirmarAlteracaoTelefonePortador;
	ComplementarDadosPrincipais;
	SolicitarCartaoIdentificado;
	ConfirmarPagamento;
}

enum AcessoError {
	TransportError(err:String);
	UserOrDataError(res:acesso.Data.Response);
	TemporarySystemError(res:acesso.Data.Response);
	PermanentSystemError(res:acesso.Data.Response);
}

