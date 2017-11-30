if [ ! -d runtime ]; then
    mkdir -p runtime
fi

export MAIN_DB=sqlite3://runtime/main.db3
export ACESSO_TOKEN=2b421b01-2c6b-4d70-8d44-b3d9d2e0879f
nekotools server -rewrite