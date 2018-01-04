package tools;

import db.types.CardRequestState;

class Unserialize {
	static function main()
	{
		try {
			while (true) {
				var data = Sys.stdin().readLine();
				Sys.println(haxe.Unserializer.run(data));
			}
		} catch (eof:haxe.io.Eof) {
			Sys.exit(0);
		}
	}
}

