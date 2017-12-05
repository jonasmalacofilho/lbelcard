package route;

import Sys;
import eweb.Dispatch;
import eweb.Web;

class Index {
	public function new() {}

	public function get()
	{
		Web.setReturnCode(200);
		Sys.println(views.Base.render("Index", views.Index.render));
	}

	public function doNovo(d:Dispatch)
	{
		d.dispatch(new Novo());
	}

	#if dev
	public function doStatus()
	{
		Sys.println(views.Base.render("Status", views.Status.render));
	}
	#end
}

