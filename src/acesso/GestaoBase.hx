package acesso;

class GestaoBase {
	public function new() {}

	public function CriarToken(params:{ Email:String, Senha:String }):AccessToken
		return request(Endpoint.GESTAO_AQUISICAO_CARTAO, "CriarToken", params,
			function (res:{ Data:String, ResultCode:String })
			{
				assert(res.Data != null && res.ResultCode != null, res);
				switch res.ResultCode {
				case "00": return (res.Data:AccessToken);
				case "05": throw TemporaryError("Não foi possível gerar o Token", res.ResultCode);
				case "99": throw TemporaryError("Erro interno", res.ResultCode);
				case err: throw PermanentError("Other", res.ResultCode);
				}
			});

	function request<A,B,C>(endpoint:String, api:String, params:A, onResponse:B->C)
	{
		var req = new haxe.Http('$endpoint/$api');
		req.addHeader("Content-Type", "application/json");
		req.addHeader("User-Agent", "belcorp, haxe/neko");
		// TODO set timeout

		var requestData = haxe.Json.stringify(params);
		req.setPostData(requestData);
		show(requestData);  // TODO remove

		var result:C = null;
		var statusCode = 0;
		req.onError = function (msg) throw TransportError(msg, statusCode);
		req.onStatus = function (code) statusCode = code;
		req.onData = function (responseData) {
			show(statusCode, responseData);  // TODO remove
			var response:B = haxe.Json.parse(responseData);
			result = 
				try {
					onResponse(response);
				} catch (err:Dynamic) {
					// show(statusCode);  // TODO enable
					// show(requestData);  // TODO enable
					// show(responseData);  // TODO enable
					neko.Lib.rethrow(err);
				}
		}
		req.request(true);
		return result;
	}
}

