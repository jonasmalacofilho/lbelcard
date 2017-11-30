package acesso;

abstract AccessToken(String) from String to String {}
abstract ClientGuid(String) from String to String {}
abstract CardGuid(String) from String to String {}

typedef SolicitarAdesaoClienteParams = Dynamic;
typedef SolicitarCartaoIdentificadoParams = Dynamic;

