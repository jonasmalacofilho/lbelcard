package db.types;

#if macro
import haxe.macro.Expr;
using StringTools;
using haxe.macro.ExprTools;
#end

/**
Timestamp abstract.

Originally developed for SAPO.
**/
abstract Timestamp(Float) from Float to Float {
	static inline var SECOND = 1e3;
	static inline var MINUTE = 60*SECOND;
	static inline var HOUR = 60*MINUTE;
	static inline var DAY = 24*HOUR;
	static inline var WEEK = 7*DAY;

	inline function new(t)
		this = t;

	@:to public function toDate():Date
		return Date.fromTime(this);

	@:from public static function fromDate(d:Date)
		return new Timestamp(d.getTime());

	@:to public function toString():String
		return toDate().toString();

	@:op(A > B) public function gt(rhs:Timestamp):Bool;
	@:op(A >= B) public function gte(rhs:Timestamp):Bool;
	@:op(A < B) public function lt(rhs:Timestamp):Bool;
	@:op(A <= B) public function lte(rhs:Timestamp):Bool;

#if macro
	static function matchConstants(e:Expr)
	{
		return switch e.expr {
		case EConst(CIdent(name)) if (name.startsWith("$")):
			var eqName = name.substr(1).toUpperCase();
			macro @:pos(e.pos) @:privateAccess common.db.MoreTypes.Timestamp.$eqName;
		case other:
			e.map(matchConstants);
		}
	}
#end

	public macro function delta(ethis:Expr, ms:Expr)
	{
		var p = haxe.macro.Context.currentPos();
		ms = matchConstants(ms);
		return macro @:pos(p) (($ethis:Float)+($ms):Timestamp);
	}

	@:to public function getTime():Float
		return this;

#if tink_template
	public function toHtml(?clientFormat:String):tink.template.Html
	{
		if (this == null)
			return "";
		var date = toDate();
		var offset = vehjo.Timezone.currentTimezone(date);
		var canonical = DateTools.format(DateTools.delta(toDate(), -offset), "%Y-%m-%d %H:%M:%S+0000");  // UTC/+0000
		var formatAttr = clientFormat != null ? 'format="${StringTools.htmlEscape(clientFormat)}"' : "";
		return new tink.template.Html('<span class="time" timestamp="$this" $formatAttr>$canonical</span>');
	}

	@:to inline function toDefaultHtml():tink.template.Html
		return toHtml();
#end

	public static macro function resolveTime(ms:Expr)
	{
		var p = haxe.macro.Context.currentPos();
		ms = matchConstants(ms);
		return macro @:pos(p) $ms;
	}
}

