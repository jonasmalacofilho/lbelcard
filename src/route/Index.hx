package route;

import eweb.Dispatch;
import eweb.Web;

class Index {
	public function new() {}

	public function head()
	{
		Web.setReturnCode(200);
	}

	public function get()
	{
		Web.setReturnCode(200);
		Sys.println(views.Base.render("O cartão de negócios do consultor!", views.Index.render));
	}

	public function doNovo(d:Dispatch)
	{
		d.dispatch(new Novo());
	}

	public function getHealthCheck(d:Dispatch)
	{
		d.dispatch(new HealthCheck());
	}

	#if dev
	public function doError(?msg : String)
	{
		Web.setReturnCode(200);
		Sys.println(views.Base.render("ERRO", views.Error.render.bind(msg)));
	}

	public function doEmail(name:String, email:String, url:String)
	{
		Web.setReturnCode(200);
		Sys.println('<html><meta charset="utf-8">' + views.Email.render(name, email, url));
	}
	#end
}

