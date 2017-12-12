package route;

import Sys;
import eweb.Dispatch;
import eweb.Web;

class Index {
	public function new() {}

	public function get()
	{
		Web.setReturnCode(200);
		Sys.println(views.Base.render("O cartão definitivo do consultor!", views.Index.render));
	}

	public function doNovo(d:Dispatch)
	{
		d.dispatch(new Novo());
	}

	#if dev
	public function doError(?msg : String)
	{
		Sys.println(views.Base.render("ERRO", views.Error.render.bind(msg)));
	}
	#end
}

