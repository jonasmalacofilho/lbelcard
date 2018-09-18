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

## Monthy database update

Every month L'BEL sends the updated data for their consultants and this must be uploaded to the server.

The process is not very automated, as the format has yet to stabilize and there is quite a lock of checking involved.

As of September 2018, the process looks like the following:

```
$ sqlite3 main.db3
```

```sql
.headers on
.timer on
.separator ,

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

