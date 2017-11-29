package route;

import Sys;
import eweb.Dispatch;
import eweb.Web;

typedef PersonalData = { foo:String }  // FIXME

class Novo {
	static inline var CARD_COOKIE = "CARD_REQUEST";

	public function new() {}

	public function getInicio()
	{
		Web.setReturnCode(200);
		Sys.println("Digite seu número de colaborador");
	}

	public function postInicio(args:{ belNumber:Int })
	{
		// FIXME replace with check for belNumber and cpf|name match
		var user = new db.BelUser(args.belNumber);
		user.insert();

		var card = db.CardRequest.manager.select($bearer == user);
		if (card == null) {
			card = new db.CardRequest(user);
			card.insert();
		}

		Web.setCookie(CARD_COOKIE, card.clientKey);
		Web.redirect(moveForward(card));
	}

	public function getDados()
	{
		Web.setReturnCode(200);
		Sys.println("Insira seus dados pessoais");
	}

	public function postDados(args:PersonalData)
	{
		var card = getCardRequest();
		if (card == null) {
			Web.setReturnCode(404);
			Sys.println("Nenhum cartão encontrado");
			return;
		}
		// TODO store the data
		card.state = AwaitingBearerConfirmation;
		card.update();
		Web.redirect(moveForward(card));
	}

	public function getConfirma()
	{
		Web.setReturnCode(200);
		Sys.println("As informações estão corredas?  Você confirma o pedido?");
	}

	public function postConfirma()
	{
		var card = getCardRequest();
		if (card == null) {
			Web.setReturnCode(404);
			Sys.println("Nenhum cartão encontrado");
			return;
		}
		card.state = AwaitingAcessoMembershipRequest;
		card.update();
		// TODO communicate with Acesso
		Web.redirect(moveForward(card));
	}

	public function getStatus()
	{
		var card = getCardRequest();
		if (card == null) {
			Web.setReturnCode(404);
			Sys.println("Nenhum cartão encontrado");
			return;
		}

		Web.setReturnCode(200);
		Sys.println(Type.enumConstructor(card.state));
	}

	function moveForward(card:db.CardRequest):String
	{
		return switch card.state {
		case AwaitingBearerData: "dados";
		case AwaitingBearerConfirmation: "confirma";
		case _: "status";
		}
	}

	function getCardRequest()
	{
		var key = Web.getCookies().get(CARD_COOKIE);
		if (key == null)
			return null;
		return db.CardRequest.manager.select($clientKey == key);
	}
}

