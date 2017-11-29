# Belcard
_L'Bel: Hotsite para obteção de um Acesso Card_

# Building and running locally

```
hmm install
haxe dev.hxml
```

```
mkdir -p runtime
export MAIN_DB=sqlite3://runtime/main.db3
export ACESSO_TOKEN=2b421b01-2c6b-4d70-8d44-b3d9d2e0879f
nekotools server -d serve -rewrite
```

