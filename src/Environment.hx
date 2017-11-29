@:build(macros.EnvironmentBuilder.build())
class Environment {
	/**
	Main DB connection settings

	Supported engines and formats:
	 - SQLite3: `sqlite3://<path>`
	**/
	public static var MAIN_DB:String;

	/**
	GUID Token for the Acesso API

	Should have been previously generated with a remote call to Acesso's CriarToken API.
	**/
	public static var ACESSO_TOKEN:String;
}

