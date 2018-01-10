package tools;

import db.types.CardRequestState;
import sys.io.File;

/**
L'BEL Card Unserializer

Unserializes persisted data.

Usage:
  unserialize [options] <input> <output>
  unserialize -h | --help
	unserialize --version

Options:
  --fields=<list>      Fields to unserialize [default: all]
  --timestamps=<list>  Timestamps to stringify [default: none]
  --separator=<char>   Separator [default: \t]
  --skip-headers       Don't unserialize the headers line

**/
@:rtti
class Unserialize {
	static function main()
	{
		var doc = haxe.rtti.Rtti.getRtti(Unserialize).doc;
		assert(doc != null);

		var args = org.docopt.Docopt.parse(doc, Sys.args(), "L'BEL Card Unserialize v2.0.0 (Server v1.1.x compatible)");
		var unserialize:Array<Int> = args["--fields"] != "all" ? args["--fields"].split(",").map(Std.parseInt) : null;
		var timestring:Array<Int> = args["--timestamps"] != "none" ? args["--timestamps"].split(",").map(Std.parseInt) : null;
		var separator:String = args["--separator"];
		if (separator == "\\t")
			separator = "\t";

		var fin = args["<input>"] != "-" ? File.read(args["<input>"]) : Sys.stdin();
		var fou = args["<output>"] != "-" ? File.write(args["<output>"]) : Sys.stdout();

		inline function println(s:String) {
			fou.writeString(s);
			fou.writeString("\n");
		}

		try {
			if (args["--skip-headers"])
				println(fin.readLine());
			while (true) {
				var data = fin.readLine();
				var out = [];
				var i = 0;
				for (f in data.split(separator)) {
					out.push(
						if (f.length == 0)
							f;
						else if (timestring != null && timestring.indexOf(i) >= 0)
							Date.fromTime(Std.parseFloat(f)).toString();
						else if (unserialize == null || unserialize.indexOf(i) >= 0)
							haxe.Unserializer.run(f)
						else
							f
					);
					i++;
				}
				println(out.join(separator));
			}
		} catch (eof:haxe.io.Eof) {
			Sys.exit(0);
		}
	}
}

