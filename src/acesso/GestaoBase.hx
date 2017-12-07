package acesso;

class GestaoBase {
	static inline var ENDPOINT =
			"https://servicos.acessocard.com.br/api2.0/Services/rest/GestaoAquisicaoCartao.svc";

	public function new() {}

	public function CriarToken(params:{ Email:String, Senha:String }):TokenAcesso
	{
		var email = StringTools.urlEncode(params.Email);
		var senha = StringTools.urlEncode(params.Senha);
		var res:Response = request(ENDPOINT, 'criar-token/$email/$senha', params);
		switch res.ResultCode {
		case 0:
			return (res.Data:TokenAcesso);
		case 5 /* unspecified */ | 99 /* internal */:
			throw TemporarySystemError(res);
		case _:
			throw PermanentSystemError(res);
		}
	}

	function request(endpoint:String, api:String, params:Dynamic):Dynamic
	{
		var ret:Dynamic = null;
		var url = '$endpoint/$api';
		var req = new haxe.Http(url);
		var log = new db.AcessoApiLog(url, "POST");

		req.addHeader("Content-Type", "application/json");
		req.addHeader("User-Agent", "haxe/neko");
		// TODO set timeout

		var requestData = haxe.Json.stringify(params);
		req.setPostData(requestData);

		var statusCode = 0;
		req.onStatus = function (code) statusCode = code;
		req.onError = function (msg) {
			trace('acesso: call FAILED with $msg');
			weakAssert(statusCode == null, "statusCode available, must update the code to log it");
			var err = TransportError(msg);
			log.responseData = Std.string(err);
			log.update();
			throw err;
		}
		req.onData = function (responseData) {
			trace('acesso: got $statusCode');
			log.responseCode = statusCode;
			log.responseData = responseData;
			log.update();
			ret = haxe.Json.parse(responseData);
		}

		log.requestPayload = requestData;
		log.insert();

		trace('acesso: call $url (log id ${log.id})');
		req.request(true);
		return ret;
	}
}

