::!/bin/bash -e
echo "Preparing the development server (nekotools)"

:: Not testing this kinda of stuff from Windows..
SET ACESSO_PASSWORD=FOO

cd ../serve/
::mkdir -p runtime
SET MAIN_DB=sqlite3://runtime/main.db3
SET ACESSO_USERNAME=user.belcorp.acesso@gmail.com
SET ACESSO_PRODUCT=CBLBELSQID12V
nekotools server -rewrite
cd ../docs/
