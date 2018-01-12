@:enum abstract LogLevel(String) to String {
	public var EMERG   = #if systemd "<0>" #else "[[[[EMERG]]]]] " #end;  // system is unusable
	public var ALERT   = #if systemd "<1>" #else "[[[ALERT]]] "  #end;  // action must be taken immediately
	public var CRIT    = #if systemd "<2>" #else "[[CRIT]] "     #end;  // critical conditions
	public var ERR     = #if systemd "<3>" #else "[ERR] "        #end;  // error conditions
	public var WARNING = #if systemd "<4>" #else "[warning] "    #end;  // warning conditions
	public var NOTICE  = #if systemd "<5>" #else "[notice] "     #end;  // normal but significant condition
	public var INFO    = #if systemd "<6>" #else ""              #end;  // informational
	public var DEBUG   = #if systemd "<7>" #else "[debug] "      #end;  // debug-level messages
}

