package sendgrid;
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
        req.setHeader('Content-Type', "application/json");
        req.setHeader("User-Agent", "BELCARD");
        req.setHeader("Authorization", 'Bearer ${"TODO: SENDGRID_KEY"}');
        req.setPostData(haxe.Json.stringify(payload));

        var status = null;
        req.onStatus = function(code) {status = code;};
        
        
    }
}