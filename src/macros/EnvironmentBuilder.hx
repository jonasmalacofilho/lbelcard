package macros;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;

class EnvironmentBuilder {
	public static function build()
	{
		var fields = Context.getBuildFields();
		for (f in fields) {
			if (f.access.indexOf(AStatic) < 0 || f.access.indexOf(APublic) < 0)
				continue;
			switch f.kind {
			case FVar(t, null):
				var expr = macro
						if (Sys.getEnv($v{f.name}) == "")
							null;
						else
							Sys.getEnv($v{f.name});
				f.kind = FVar(t, expr);
			case _:
				continue;
			}
		}

		return fields;
	}
}

