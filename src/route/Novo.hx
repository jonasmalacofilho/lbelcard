package route;

import acesso.Data;
import eweb.Dispatch;
import eweb.Web;
import haxe.Json;

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
	NumeroRes:String,
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

	public function new() {}

	public function getDefault()
	{
		Web.setReturnCode(200);
#if dev
		trace('dev-build: recaptcha installation skipped');
		Sys.println(views.Base.render("Peça seu cartão", views.Login.render.bind(null)));
#else
		Sys.println(views.Base.render("Peça seu cartão", views.Login.render.bind({ siteKey:RECAPTCHA_SITE_KEY })));
#end
	}

	public function postDefault(args:{ belNumber:Int, cpf:String})
	{
		assert(~/^[0-9]+$/.match(args.cpf), args.cpf);

#if dev
		trace('dev-build: recaptcha validation skipped');
#else
		var recaptcha = Web.getParams().get("g-recaptcha-response");
		weakAssert(recaptcha != null);
		if(recaptcha == null || !recapChallenge(recaptcha))
			throw "A verificação do reCAPTCHA falhou";  // FIXME error type
#end

		var user = db.BelUser.manager.select($belNumber == args.belNumber);
		if (user == null || user.cpf != args.cpf) {
#if dev
			assert(user == null, args.belNumber);
			trace('dev-build: ignoring missing assossiation to L\'Bel');
			user = new db.BelUser(args.belNumber, args.cpf);
			user.insert();
#else
			show(args);
			throw "Consultor não encontrado ou CPF não bate";  // FIXME error type
#end
		}

		if (limitReached(user))
			throw "Atingido o limite de solicitação de cartões para esse consultor";  // FIXME error type

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
		Sys.println(views.Base.render("Entre com suas informações", views.CardReq.render.bind(null)));
	}

	public function postDados(args:PersonalData)
	{
		assert(~/^[0-9]+$/.match(args.NumDocumento), args.NumDocumento);
		assert(~/^[0-9]+$/.match(args.CodCliente), args.CodCliente);

		var card = getCardRequest();
		if (card == null)
			throw "Nenhum cartão encontrado";  // FIXME error type
		if (card.bearer.cpf != args.CodCliente)
			throw "O CPF informado não pertence ao consultor";
		assert(!limitReached(card.bearer));  // might happen because we don't lock the BelUser while creating a CardRequest

		// FIXME dates: they actually this depend on the client locale; thus it
		//       would be best to avoid touching dates on the server due to the
		//       existance of locale, timezone and other corner cases that are
		//       (very) hard to handle correctly

		// leaving this here for it can be usefull
		// 	//I pass dates as MM/DD/YYYY which is a nono
		// 	if(f == 'DtNascimento' || f == 'DtExpedicao')
		// 	{
		// 		var split :Array<String> = Reflect.field(args, f).split('/');
    //
		// 		var p = [];
		// 		for(s in split)
		// 			p.push(Std.parseInt(s));
    //
		// 		var data = new Date(p[2], p[1]-1, p[0],0,0,0).getTime();
		// 		Reflect.setField(d,f,data);

		var userData:DadosDoUsuario = {
			Documento : {
				TpDocumento : args.TpDocumento,
				NumDocumento : args.NumDocumento,
				DtExpedicao : null,  // FIXME,
				OrgaoExpedidor : args.OrgaoExpedidor,
				UFOrgao : args.UFOrgao,
				PaisOrgao : args.PaisOrgao
			},
			DtNascimento : null,  // FIXME,
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
				Numero : args.NumeroRes,  // FIXME rename
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
		Web.setReturnCode(200);
		var card = getCardRequest();
		Sys.println(views.Base.render("Confirme suas informações",views.Confirm.render.bind(card.userData)));
	}

	public function postConfirma()
	{
		var card = getCardRequest();
		if (card == null) {
			Web.setReturnCode(404);
			Sys.println("Nenhum cartão encontrado");
			return;
		}
		card.state = Queued(SolicitarAdesaoCliente);
		card.update();
		var q = ProcessingQueue.global();
		q.addTask(new AcessoProcessor(card.requestId).execute);  // FIXME
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

	static function limitReached(user:db.BelUser)
	{
		var cards = db.CardRequest.manager.search($bearer == user);
		for (i in cards) {
			if (i.state.match(Queued(_) | Processing(_) | CardRequested))
				return true;
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
		case _: "/novo/status";
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

