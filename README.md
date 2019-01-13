# Belcard
_L'Bel: Hotsite para obteção de um Acesso Card_

## Building and running locally

```
# Build
hmm install
haxe dev.hxml

# And start a development server
#
# Notes:
#  - asks for the password to AcessoCard's API
#  - starts nginx automatically (nginx is required)
#  - expectes a tora to be in the path (instrucutions in the script)
docs/dev-server
```

## Periodic maintenance

### Updates to the list of authorized users

_As of late September 2018..._

Every month L'BEL sends the updated data for their consultants and this must be
uploaded to the server.

The file should a valid CSV file with UNIX-style line-endings and no header or
empty lines.  Each row should consist of two values, comma separated: integer
`belNumber` (conta) and non-padded integer `cpf`.

Manual checking of the file is recommended.  Additionally, the following Vim
commands might be useful:

```
setlocal nobomb
setlocal fileencoding=utf-8
setlocal ff=unix
```

Then, rsync the file to the server:

```
# rsync -P <local path> root@lbelcard.com.br:/var/lbelcard/consultores-<date>.csv
```

After uploading this file to the server, log in and go through:

```
# cd /var/lbelcard
# sqlite3 main.db3
```

```sql
.headers on
.timer on
.separator ,
.changes on

BEGIN TRANSACTION;
SELECT count(*) FROM BelUser;

-- import the new data into a temperary table;
-- you must check that all data has been imported
CREATE TEMPORARY TABLE newdata(conta, ncpf);
.import <path> newdata
SELECT count(*) from newdata;
SELECT count(distinct conta) from newdata;  -- if different, decide whether to verify or ignore

-- normalize the cpf and insert (or replace) it for each belNumber/conta
INSERT OR REPLACE INTO BelUser SELECT conta, substr('00000000000' || ncpf, -11, 11) FROM newdata;
SELECT count(*) FROM BelUser;

-- if all went well,
COMMIT;
```

Changes to `BelUser` are automatically logged in `BelUserUpdateLog`, through
the use of a recently installed trigger.  Note: the trigger only executes for
`INSERT`.

```sql
CREATE TABLE BelUserUpdateLog(belNumber INTEGER, cpf TEXT, applied INTEGER);
CREATE TRIGGER BelUserLogInserts AFTER INSERT ON BelUser FOR EACH ROW BEGIN INSERT INTO BelUserUpdateLog VALUES (NEW.belNumber, NEW.cpf, datetime('now')); END;
```

Finally, for reference, the process used to perform some additional validation
steps, as well as forbade updates (by default).  This was deemed unnecessary
after the our contact at L'BEL changed to be Marilia.  However, it remains
listed here in case it is needed in the future.

```sql
-- import the new data into the auxiliary database; data should eventually go
-- into Consultores, there is a sequence of views that perform know validation
-- and fixing steps, and the valid consultants are exported through _BelUsers
ATTACH 'RPT-ConsultoresDetalhes.db' as bel;
CREATE TEMPORARY TABLE newdata(conta, cpf);
.import <path>.csv newdata
INSERT INTO bel.Consultores SELECT conta, '', '', cpf, '', <today> FROM newdata;
SELECT versao, count(*) total, count(belnumber) valid
    FROM bel.consultores LEFT JOIN bel._BelUsers ON conta = belnumber
    GROUP BY versao;

-- after checking the data, push the new valid consultants to the main
-- database; we choose the sacrifice updates (of data for existing users) in
-- favor of making sure we never overwrite manual fixes
INSERT OR IGNORE INTO BelUser SELECT * FROM bel._BelUsers;
```

### Backup of most important data

Make a backup of the `main.db3` database:

```
# cd /var/lbelcard
# sqlite3 main.db3 ".backup backup.db"
```

On the constodian machine, rsync that file to a safe(ish) place:

```
# rsync -P root@lbelcard.com.br:/var/lbelcard/backup.db <backup folder>/
```

Finally, open the backup and run an integrity check:

```
$ sqlite3 <backup folder>/backup.db
> PRAGMA integrity_check;
```

### System maintenace

You should know what each command bellow does.

```
<connect>

# free -h
<check>
# df -h
<check>
# htop
<check>

# apt-get update && apt-get dist-upgrade && apt-get autoremove
<check>
# systemctl stop nginx && letsencrypt renew --standalone --force-renewal ; systemctl start nginx
<check>

# reboot
<reconnect>

# systemctl status nginx robrt tora
<check>
```
