package sendgrid;

import db.types.CardRequestError;
import sendgrid.Data;

class Email {
	static var url = "https://api.sendgrid.com/v3/mail/send";
	var payload : SendGridPayload; 

	public function new(username : String, email : String, status_url : String)
	{
		payload = {
			personalizations : [{
				to : [{ name : username, email : email }]
			}],
			from : { name : "L'BELCARD", email : "no-reply@lbelcard.com.br"},
			subject : "Obrigado por solicitar o seu L'BelCard",
			content : [{ type : "text/html", value : views.Email.render(username,email,status_url)  }]
		}
	}

	public function execute()
	{
		var req = new haxe.Http(url);
		var log = new db.RemoteCallLog(url, "POST");

		req.setHeader("Content-Type", "application/json");
		req.setHeader("User-Agent", "BELCARD");
		req.setHeader("Authorization", 'Bearer ${Environment.SENDGRID_KEY}');
		req.cnxTimeout = 20;  // TODO reevaluate

		var requestData = haxe.Json.stringify(payload);
		req.setPostData(requestData);

		var statusCode = null;
		var t0 = Sys.time();
		req.onStatus = function (code) statusCode = code;
		req.onError = function (msg) {
			var t1 = Sys.time();
			trace('sendgrid: call FAILED with $msg after ${Math.round((t1 - t0)*1e3)} ms');
			var err = TransportError(msg);
			log.responseCode = statusCode;
			log.responseData = Std.string(err);
			log.timing = t1;
			log.update();
			throw err;
		}
		req.onData = function (responseData) {
			var t1 = Sys.time();
			trace('sendgrid: received $statusCode after ${Math.round((t1 - t0)*1e3)} ms');
			log.responseCode = statusCode;
			log.responseData = responseData;
			log.timing = t1;
			log.update();
			if (statusCode >= 400)
				throw SendGridError(statusCode, responseData);
		}

		log.requestPayload = requestData;
		log.insert();

		trace('sendgrid: call $url (log id ${log.id})');
		req.request(true);
	}
}
