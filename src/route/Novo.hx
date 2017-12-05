package route;

import Sys;
import eweb.Dispatch;
import eweb.Web;

typedef PersonalData = { foo:String }  // FIXME

class Novo {
	static inline var CARD_COOKIE = "CARD_REQUEST";

	public function new() {}

	public function getDefault()
	{
		Web.setReturnCode(200);
		Sys.println(views.Base.render("Peça seu cartão", views.Login.render));
	}

	public function postDefault(args:{ belNumber:Int, cpf:String })
	{
		show(args);
		// FIXME replace with check for belNumber and cpf|name match
		var user = db.BelUser.manager.select($belNumber == args.belNumber);
		if (user == null) {
			user = new db.BelUser(args.belNumber);
			user.insert();
		}

		var card = db.CardRequest.manager.select($bearer == user);
		if (card == null) {
			card = new db.CardRequest(user);
			card.insert();
		}

		Web.setCookie(CARD_COOKIE, card.clientKey, DateTools.delta(Date.now(), DateTools.days(1)));
		Web.redirect(moveForward(card));
	}

	public function getDados()
	{
		var card = getCardRequest();
		if (card == null) {
			Web.redirect(moveForward(null));
			return;
		}
		
		Web.setReturnCode(200);
		Sys.println(views.Base.render("Entre com suas informações", views.CardReq.render));
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
		if (card == null)
			return "/novo";
		return switch card.state {
		case AwaitingBearerData: "/novo/dados";
		case AwaitingBearerConfirmation: "/novo/confirma";
		case _: "/novo/status";
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

