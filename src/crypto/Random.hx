// imported from cherto

package crypto;

import haxe.io.*;

class StdRandomInput extends Input {
	override public inline function readByte()
		return Std.random(256);

	public function new() {}
}

class Random extends Input {
	var gen:Input;

	function new(gen:Input)
		this.gen = gen;

	override public inline function close()
	{
		gen.close();
		if (global == this)
			global = null;
	}

	override public inline function readByte()
		return gen.readByte();

	public function readSimpleBytes(len:Int):Bytes
	{
		var b = Bytes.alloc(len);
		gen.readFullBytes(b, 0, len);
		return b;
	}

	public function readHex(len:Int):String
		return readSimpleBytes(len).toHex();

	public static var global(get,null):Random;
		static function get_global() {
			if (global != null) return global;
			var gen = switch Sys.systemName() {
			case "Windows":
				//TODO: Fix this (this trace is called before the override, breaking develop builds on Windows)
				//trace("WARNING no real random generator used on Windows");
				new StdRandomInput();
			case _:
				sys.io.File.read("/dev/urandom", true);
			}
			return global = new Random(gen);
		}
}
