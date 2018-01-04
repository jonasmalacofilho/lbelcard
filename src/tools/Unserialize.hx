package tools;

import db.types.CardRequestState;

/**
L'BEL Card Unserializer

Unserializes persisted data.

Usage:
  unserialize [--fields=<list>] [--separator=<char>]
  unserialize -h | --help
	unserialize --version

Options:
  --fields=<list>     Fields to serialize (by default, all)
  --separator=<char>  Separator [default: \t]

**/
@:rtti
class Unserialize {
	static function main()
	{
		var doc = haxe.rtti.Rtti.getRtti(Unserialize).doc;
		assert(doc != null);

		var args = org.docopt.Docopt.parse(doc, Sys.args(), "L'BEL Card Unserialize v1.0.3");  // FIXME get serverVersion automatically
		var fields:Array<Int> = args["--fields"] != null ? args["--fields"].split(",").map(Std.parseInt) : null;
		var separator:String = args["--separator"];
		if (separator == "\\t")
			separator = "\t";

		try {
			while (true) {
				var data = Sys.stdin().readLine();
				if (fields != null) {
					var i = 0;
					var out = [ for (f in data.split(separator)) if (fields.indexOf(i++) >= 0 && f != "") haxe.Unserializer.run(f) else f ];
					Sys.println(out.join(separator));
				} else {
					Sys.println(haxe.Unserializer.run(data));
				}
			}
		} catch (eof:haxe.io.Eof) {
			Sys.exit(0);
		}
	}
}

