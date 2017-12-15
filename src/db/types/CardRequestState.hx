package db.types;

enum CardRequestState {
	AwaitingBearerData;  // !queued
	AwaitingBearerConfirmation;  // !queued
	SendEmail;  // queued
	AcessoCard(step:AcessoCardStep);  // queued
	Failed(err:CardRequestError, onState:CardRequestState);  // queued
	CardRequested;  // !queued
}

