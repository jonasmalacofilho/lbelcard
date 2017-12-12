package db.types;

enum CardRequestState {
	AwaitingBearerData;
	AwaitingBearerConfirmation;
	SendEmail;
	AcessoCard(step:AcessoCardStep);
	Failed(err:CardRequestError, onState:CardRequestState);
	CardRequested;
}

