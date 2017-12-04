package acesso;

/*
Upstream API reponse types.
*/

typedef FieldError = {
	Message:String
}

typedef Response = {
	ResultCode:Int,
	Message:String,
	FieldErrors:Null<Array<FieldError>>,
	Data:Null<String>
}

/*
Typed values based on basic types
*/

abstract TokenAcesso(String) from String to String {}

abstract ClientGuid(String) from String to String {}

abstract CardGuid(String) from String to String {}

abstract SerializedDate(String) from String to String {}

abstract CodEspecieProduto(String) from String to String {}

/**
The user's CPF number
**/
abstract CodCliente(String) from String to String {}

@:enum abstract Language(Dynamic) {
	public var REST = 0;
}

@:enum abstract Sexo(Int) {
	public var Nao_informado = 0;
	public var Masculino = 1;
	public var Feminino = 2;
}

@:enum abstract TpDocumento(Int) {
	public var RG = 0;
	public var RNE = 1;
	public var Passaporte = 2;
}

@:enum abstract TpTelefone(Int) {
	public var Celular = 0;
	public var Residencial = 1;
	public var Comercial = 2;
	public var Pessoal = 3;
}

@:enum abstract TpEndereco(Int) {
	public var Residencial = 0;
	public var Comercial = 1;
	public var Outros = 2;
}

@:enum abstract TpCliente(Int) {
	public var Nacional_pessoa_fisica = 0;
	public var Nacional_pessoa_juridica = 1;
	public var Estrangeiro = 2;
}

/*
Intermidiate data types supplied by the API client
*/

typedef Meta = {
	Language : String,
	NomeCanal : String,
	RecId : Int,
	TokenAcesso : TokenAcesso
}

/*
Intermediate data types supplied by the user (or the UI)
*/

typedef Documento = {
	TpDocumento : TpDocumento,
	NumDocumento : String,
	DtExpedicao : SerializedDate,
	UFOrgao : String,
	PaisOrgao : String
}

typedef Telefone = {
	TpTelefone : TpTelefone,
	DDI : String,
	DDD : String,
	Numero : String
}

typedef Endereco = {
	TpEndereco : TpEndereco,
	CEP : String,
	Logradouro : String,
	Numero : String,
	Complemento : String,
	Bairro : String,
	Cidade : String,
	UF : String
}

typedef DadosPrincipais = {
	Documento : Documento,
	DtNascimento : SerializedDate,
	NomeMae : String,
	TpSexo : Sexo
}

/*
Data types sent to the upstream APIs
*/

typedef SolicitarAdesaoClienteParams = {
	> Meta,
	Data : {
		CodEspecieProduto : CodEspecieProduto,
		Usuario : {
			> DadosPrincipais,
			Celular : Telefone,
			CodCliente : CodCliente,
			Email : String,
			Endereco : Endereco,
			NomeCompleto : String,
			TpCliente : TpCliente
		}
	}
}

typedef SolicitarCartaoIdentificadoParams = Dynamic;

