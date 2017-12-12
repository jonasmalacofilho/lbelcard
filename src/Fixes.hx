import db.types.*;

class Fixes {
	public static function apply()
	{
		{
			var card = db.CardRequest.manager.select($requestId == "d2a8a803acd05e6f267995c59e961d1e26647077feba40ef4f87e0f0d8fbc486");
			if (card != null && card.bearer.belNumber == -42 && card.bearer.cpf == "37088985837" &&
					card.queued && card.state.match(AcessoCard(ConfirmarPagamento(_)))) {
				trace('fix #1: card request ${card.requestId} succeeded, just was not updated');
				card.state = CardRequested;
				card.queued = false;
				card.update();
			}
		}
	}
}

