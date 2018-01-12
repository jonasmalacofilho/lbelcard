package route;

import acesso.Data;
import eweb.Dispatch;
import eweb.Web;

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
	static inline var RECAPTCHA_SITE_KEY = "6LehwTwUAAAAAAhZ2Ffyn7R9sHpr7PHN2vnv0zKM";  // FIXME get from environment
	static inline var RECAPTCHA_SECRET = "6LehwTwUAAAAAGkXm3tcXPn1co-gGB3oe8juDS4m";  // FIXME get from environment

	var notDigits = ~/\D/g;
	var specials = ~/\W/g;

	public function new() {}

	public function getDefault(?error:String)
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
		var queued = async.Queue.global().peekSize();
		show(queued);
		if (queued > 122) {
			trace('abort: queue too long (size $queued)');
			getDefault('Há muito interesse no cartão, por favor tente novamente em algumas horas');
			return;
		}

		args.cpf = notDigits.replace(args.cpf, "").trim();

#if dev
		trace('dev-build: recaptcha validation skipped');
#else
		var recaptcha = Web.getParams().get("g-recaptcha-response");
		weakAssert(recaptcha != null);
		if(recaptcha == null || !recapChallenge(recaptcha)) {
			trace('abort: invalid recaptcha (user ${args.belNumber})');
			getDefault('Não conseguimos verificar que você não é um robô, aguarde um pouco e tente novamente');
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
			if (user == null)
				trace('abort: user not found (${args.belNumber})');  // TODO consider switching to SecurityError
			else
				trace('abort: cpf does not match user (user ${user.belNumber}, cpf ${args.cpf})');  // TODO consider switching to SecurityError
			getDefault('Consultor não encontrado ou CPF não bate');
			return;
#end
		}

		if (limitReached(user)) {
			trace('abort: card request limit reached (user ${user.belNumber})');
			getDefault('Atingido o limite de solicitação de cartões para esse consultor');
			return;
		}

		var card = new db.CardRequest(user);
		card.product = Environment.ACESSO_PRODUCT;
		card.insert();
		show(user.belNumber, card.requestId);

		Web.setCookie(CARD_COOKIE, card.requestId, DateTools.delta(Date.now(), DateTools.days(1)));
		Web.redirect(moveForward(card));
	}

	public function getDados(?error:String)
	{
		var card = getCardRequest();
		if (card == null || !card.state.match(AwaitingBearerData | AwaitingBearerConfirmation)) {
			// /novo/confirm shows user data, never move the user there
			Web.redirect(moveForward(null));
			return;
		}
		Web.setReturnCode(200);
		Sys.println(views.Base.render("Entre com suas informações", views.CardReq.render, error));
	}

	public function postDados(args:PersonalData)
	{
		args.CodCliente = notDigits.replace(args.CodCliente, "");
		args.DDI = notDigits.replace(args.DDI, "");
		args.DDD = notDigits.replace(args.DDD, "");
		args.NumeroTel = notDigits.replace(args.NumeroTel, "");
		args.CEP = notDigits.replace(args.CEP, "");
		args.NumDocumento = specials.replace(args.NumDocumento, "");
		for (f in Reflect.fields(args)) {
			var val = Reflect.field(args, f);
			if (val != null && Std.is(val, String))
				Reflect.setField(args, f, StringTools.trim(val));
		}

		weakAssert(!args.DDI.startsWith("0"), args.DDI);  // TODO consider switching to assert
		weakAssert(args.DDI != "55" || !args.DDD.startsWith("0"), args.DDI, args.DDD);  // TODO consider switching to assert

		var card = getCardRequest();
		if (card == null || !card.state.match(AwaitingBearerData | AwaitingBearerConfirmation)) {  // can resubmit if !confirmed
			show(Web.getCookies().get(CARD_COOKIE));
			if (card != null)
				show(Type.enumConstructor(card.state));
			throw SecurityError("card request not found or in wrong state");
		}
		show(card.requestId);

		if (card.bearer.cpf != args.CodCliente) {
#if dev
			trace('dev-build: ignoring mismatch between authorized and current bearers');
#else
			trace('abort: card bearer does not match user (user ${card.bearer.belNumber}, cpf ${args.CodCliente})');
			getDados('O CPF informado não pertence ao consultor');
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

	public function getConfirma()
	{
		var card = getCardRequest();
		if (card == null || !card.state.match(AwaitingBearerConfirmation)) {
			Web.redirect(moveForward(card));
			return;
		}
		Web.setReturnCode(200);
		Sys.println(views.Base.render("Confirme suas informações",views.Confirm.render.bind(card.userData)));
	}

	public function postConfirma()
	{
		var card = getCardRequest();
		if (card == null || !card.state.match(AwaitingBearerConfirmation)) {
			show(Web.getCookies().get(CARD_COOKIE));
			if (card != null)
				show(Type.enumConstructor(card.state));
			throw SecurityError("card request not found or in wrong state");
		}
		show(card.requestId);

		// might happen; we don't lock the BelUser when creating the CardRequest
		assert(!limitReached(card.bearer), card.requestId, card.bearer.belNumber);

		card.state = SendEmail;
		card.queued = true;
		card.update();

		var q = async.Queue.global();
		q.addTask(card.requestId);

		Web.redirect(moveForward(card));
	}

	public function getStatus(key:String)
	{
		var card = db.CardRequest.manager.select($requestId == key);
		if (card == null)
			throw SecurityError("card request not found", "Não encontramos o cartão na nossa base.");
		show(Type.enumConstructor(card.state));

		Web.setReturnCode(200);
		Sys.println(views.Base.render("Acompanhe o progresso da sua solicitação",views.Status.render.bind(card.state)));
	}

	/**
	Estimate if the user's request limit has been reached.

	Besides sucessfull requests, considers in-progress requests (that might
	succeed) and transient failures (that should eventually result in either
	failures or successes).
	
	In this instance, AcessoPermanentErrors are treated as final, since even if
	recoverable, they might take to do so.
	**/
	static function limitReached(user:db.BelUser)
	{
		var cards = db.CardRequest.manager.search($bearer == user);
		for (i in cards) {
			if (!i.state.match(AwaitingBearerData | AwaitingBearerConfirmation |
					Failed(AcessoUserOrDataError(_)|AcessoPermanentError(_)|SendGridError(_), _))) {
#if dev
				trace('dev-build: overriding maxed out limit of cards per user');
				return false;
#else
				weakAssert(i.queued || i.state.match(CardRequested),
						i.requestId, i.queued, Type.enumConstructor(i.state),
						"blocking, but offending request is not sucessfull nor queued (cannot recover)");
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

	static function recapChallenge(challenge : String)
	{
		var ret = false;

		var http = new haxe.Http(RECAPTCHA_URL);
		http.addHeader("User-Agent", Server.userAgent);
		http.addParameter("secret", RECAPTCHA_SECRET);
		http.addParameter("response", challenge);
		http.addParameter("remoteip", Web.getClientIP());

		http.onError = function(msg : String){
			throw 'recaptcha: $msg during remote verification';
		};
		http.onData = function(d : String)
		{
			var res = haxe.Json.parse(d);
			ret = res.success;
			assert(ret != null || Reflect.hasField(res, "error-codes"), d);
		};
		http.request(true);

		return ret;
	}
}

