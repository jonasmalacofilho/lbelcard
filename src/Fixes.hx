import db.types.*;

class Fixes {
	public static function apply()
	{
		upgradeDatabase();

		// place fixes here (each isolated within a block)
	}

	static function upgradeDatabase()
	{
		var dbVersion = db.Metadata.manager.get("schemaVersion");
		if (dbVersion == null) {
			dbVersion = new db.Metadata("schemaVersion");
			dbVersion.value = 1;
			dbVersion.insert();
		}

		var cnx = sys.db.Manager.cnx;
		cnx.request("BEGIN TRANSACTION");
		try {
			trace('database: at version ${dbVersion.value}');
			if (dbVersion.value == Server.schemaVersion) {
				cnx.request("COMMIT");
				return;
			}

			if (dbVersion.value < 2) {
				cnx.request("ALTER TABLE CardRequest ADD COLUMN created DOUBLE");
				cnx.request("ALTER TABLE CardRequest ADD COLUMN lastUpdated DOUBLE");
				cnx.request("ALTER TABLE RemoteCallLog ADD COLUMN created DOUBLE");
				dbVersion.value = 2;
				dbVersion.update();
				trace('database: upgraded to version ${dbVersion.value}');
			}

			// place additional migration steps here;
			// always update the dbVersion value at each step

			// make sure we're up-to-date
			if (dbVersion.value != Server.schemaVersion)
				throw 'database upgrade failed: expected ${Server.schemaVersion}, only got to ${dbVersion.value}';
			cnx.request("COMMIT");
		} catch (err:Dynamic) {
			cnx.request("ROLLBACK");
			neko.Lib.rethrow(err);
		}
	}
}

