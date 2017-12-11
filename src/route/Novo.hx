package route;

import acesso.Data;
import eweb.Dispatch;
import eweb.Web;
import haxe.Json;

using StringTools;

typedef PersonalData = {
	Bairro:String,
	CEP:String,
	Cidade:String,
	CodCliente:String,
	DDD:String,
	DDI:String,
	DtExpedicao:String,
	DtNascimento:String,
	Email:String,
	Logradouro:String,
	NomeCompleto:String,
	NomeMae:String,
	NumDocumento:String,
	NumeroEnd:String,
	NumeroTel:String,
	PaisOrgao:String,
	TpCliente:Int,
	TpDocumento:Int,
	TpEndereco:Int,
	TpSexo:Int,
	TpTelefone:Int,
	UF:String,
	UFOrgao:String,
	?Complemento:String,
	?OrgaoExpedidor:String
}

class Novo {
	static inline var CARD_COOKIE = "CARD_REQUEST";
	static inline var RECAPTCHA_URL = "https://www.google.com/recaptcha/api/siteverify";
	static inline var RECAPTCHA_SITE_KEY = "6LeA3zoUAAAAAM4xAlcdzP27QA-mduMUcFvn1RH4";  // FIXME get from environment
	static inline var RECAPTCHA_SECRET = "6LeA3zoUAAAAAHVQxT3Xh1nILlXPjGRl83F_Q5b6";  // FIXME get from environment

	var notDigits = ~/\D/g;

	public function new() {}

	public function getDefault(?error : String)
	{
		Web.setReturnCode(200);
#if dev
		trace('dev-build: recaptcha installation skipped');
		Sys.println(views.Base.render("Peça seu cartão", views.Login.render.bind(null), error));
#else
		Sys.println(views.Base.render("Peça seu cartão", views.Login.render.bind({ siteKey:RECAPTCHA_SITE_KEY }), error));
#end
	}

	public function postDefault(args:{ belNumber:Int, cpf:String})
	{
		args.cpf = notDigits.replace(args.cpf, "");

#if dev
		trace('dev-build: recaptcha validation skipped');
#else
		var recaptcha = Web.getParams().get("g-recaptcha-response");
		weakAssert(recaptcha != null);
		if(recaptcha == null || !recapChallenge(recaptcha))
		{
			Web.redirect('${moveForward(null)}/?error=${'A verificação do reCAPTCHA falhou'.urlEncode()}');
			return;
		}
#end

		var user = db.BelUser.manager.select($belNumber == args.belNumber);
		if (user == null || user.cpf != args.cpf) {
#if dev
			trace('dev-build: ignoring missing or incorrect association to L\'Bel');
			if (user == null) {
				user = new db.BelUser(args.belNumber, args.cpf);
				user.insert();
			}
#else
			show(args);
			Web.redirect('${moveForward(null)}?error=${'Consultor não encontrado ou CPF não bate'.urlEncode()}');
			return;
#end
		}

		if (limitReached(user))
		{
			Web.redirect('${moveForward(null)}?error=${'Atingido o limite de solicitação de cartões para esse consultor'.urlEncode()}');
			return;
		}

		var card = new db.CardRequest(user);
		card.product = Environment.ACESSO_PRODUCT;
		card.insert();

		Web.setCookie(CARD_COOKIE, card.requestId, DateTools.delta(Date.now(), DateTools.days(1)));
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
		args.CodCliente = notDigits.replace(args.CodCliente, "");
		args.NumDocumento = notDigits.replace(args.NumDocumento, "");
		args.DDI = notDigits.replace(args.DDI, "");
		args.DDD = notDigits.replace(args.DDD, "");
		args.NumeroTel = notDigits.replace(args.NumeroTel, "");
		args.CEP = notDigits.replace(args.CEP, "");
		assert(!args.DDI.startsWith("0"), args.DDI);
		assert(args.DDI != "55" || !args.DDD.startsWith("0"), args.DDI, args.DDD);

		var card = getCardRequest();
		if (card == null)
		{
			Web.redirect('${moveForward(null)}?error=${'Nenhum cartão encontrado'.urlEncode()}');
			return;
		}
		if (card.bearer.cpf != args.CodCliente) {
#if dev
			trace('dev-build: ignoring mismatch between authorized and current bearers');
#else
			Web.redirect('${moveForward(card)}?error=${'O CPF informado não pertence ao consultor'.urlEncode()}');
			return;
#end
		}

		// might happen; we don't lock the BelUser when creating the CardRequest
		assert(!limitReached(card.bearer), card.requestId, card.bearer.belNumber);

		var userData:DadosDoUsuario = {
			Documento : {
				TpDocumento : args.TpDocumento,
				NumDocumento : args.NumDocumento,
				DtExpedicao : SerializedDate.fromStringBR(args.DtExpedicao),
				OrgaoExpedidor : args.OrgaoExpedidor,
				UFOrgao : args.UFOrgao,
				PaisOrgao : args.PaisOrgao
			},
			DtNascimento : SerializedDate.fromStringBR(args.DtNascimento),
			NomeMae : args.NomeMae,
			TpSexo : args.TpSexo,
			Celular : {
				TpTelefone : args.TpTelefone,
				DDI : args.DDI,
				DDD : args.DDD,
				Numero : args.NumeroTel
			},
			CodCliente : args.CodCliente,
			Email : args.Email,
			Endereco : {
				TpEndereco : args.TpEndereco,
				CEP : args.CEP,
				Logradouro : args.Logradouro,
				Numero : args.NumeroEnd,
				Complemento : args.Complemento,
				Bairro : args.Bairro,
				Cidade : args.Cidade,
				UF : args.UF
			},
			NomeCompleto : args.NomeCompleto,
			TpCliente : args.TpCliente
		};

		card.state = AwaitingBearerConfirmation;
		card.userData = userData;
		card.update();

		Web.redirect(moveForward(card));
	}

	public function getConfirma(?error : String)
	{
		Web.setReturnCode(200);
		var card = getCardRequest();
		Sys.println(views.Base.render("Confirme suas informações",views.Confirm.render.bind(card.userData), error));
	}

	public function postConfirma()
	{
		var card = getCardRequest();
		if (card == null)
		{
			Web.redirect('${moveForward(card)}?error=${'Nenhum cartão encontrado'.urlEncode()}');
			return;
		}

		if (card.state.match(AwaitingBearerConfirmation)) {
			// might happen; we don't lock the BelUser when creating the CardRequest
			assert(!limitReached(card.bearer), card.requestId, card.bearer.belNumber);

			card.state = Queued(SolicitarAdesaoCliente);
			card.submitting = true;
			card.update();

			var q = async.Queue.global();
			q.addTask(card.requestId);
		}

		Web.redirect(moveForward(card));
	}

	public function getStatus(key:String)
	{
		var card = db.CardRequest.manager.select($requestId == key);
		if (card == null)
		{
				Web.redirect('${moveForward(null)}?error=${'Nenhum cartão encontrado'.urlEncode()}');
				return;
		}
		show(Type.enumConstructor(card.state));

		Web.setReturnCode(200);
		Sys.println(views.Base.render("Acompanhe o progresso da sua solicitação",views.Status.render.bind(card.state)));
	}

	static function limitReached(user:db.BelUser)
	{
		var cards = db.CardRequest.manager.search($bearer == user);
		for (i in cards) {
			if (i.state.match(Queued(_) | CardRequested)) {
#if dev
				trace('dev-build: overriding maxed out limit of cards per user');
#else
				return true;
#end
			}
		}
		return false;
	}

	static function moveForward(card:db.CardRequest):String
	{
		if (card == null)
			return "/novo";
		return switch card.state {
		case AwaitingBearerData: "/novo/dados";
		case AwaitingBearerConfirmation: "/novo/confirma";
		case _: '/novo/status/${card.requestId}';
		}
	}

	static function getCardRequest()
	{
		var key = Web.getCookies().get(CARD_COOKIE);
		if (key == null)
			return null;
		return db.CardRequest.manager.select($requestId == key);
	}

	function recapChallenge(challenge : String)
	{
		var ret = false;

		var http = new haxe.Http(RECAPTCHA_URL);
		http.addParameter('secret', RECAPTCHA_SECRET);
		http.addParameter('response', challenge);
		http.addParameter('remoteip', Web.getClientIP());

		http.onError = function(msg : String){
			trace(msg);
			throw 'Unexpected Http error $msg';
		};
		http.onData = function(d : String)
		{
			var res = Json.parse(d);
			ret = res.success;
		};
		http.request(true);

		return ret;
	}
}

