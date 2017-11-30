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
		//Sys.println("Hello!");
	}

	public function getNovo(d:Dispatch)
	{
		d.dispatch(new Novo());
	}
}

