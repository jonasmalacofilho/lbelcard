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
	EfetivarAlteracaoEmailPortador;
	SolicitarAlteracaoTelefonePortador;
	ConfirmarAlteracaoTelefonePortador;
	ComplementarDadosPrincipais;
	SolicitarCartaoIdentificado;
	ConfirmarPagamento;
}

enum AcessoError {
	TransportError(err:String);
	UserOrDataError(res:Response);
	TemporarySystemError(res:Response);
	PermanentSystemError(res:Response);
}

