@:build(macros.EnvironmentBuilder.build())
class Environment {
	/**
	Main DB connection settings

	Supported engines and formats:
	 - SQLite3: `sqlite3://<path>`
	**/
	public static var MAIN_DB:String;

	/**
	Username for AcessoCard's API
	**/
	public static var ACESSO_USERNAME:String;

	/**
	Password for AcessoCard's API
	**/
	public static var ACESSO_PASSWORD:String;

	/**
	Desired card product code
	**/
	public static var ACESSO_PRODUCT:String;
}

