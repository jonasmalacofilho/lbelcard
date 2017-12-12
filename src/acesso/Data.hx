package acesso;

/*
Upstream API reponse types.
*/

typedef FieldError = {
	Message:String,
	ResultCode:Int
}

typedef Response<T> = {
	ResultCode:Int,
	Message:String,
	FieldErrors:Null<Array<FieldError>>,
	Data:Null<T>
}

/*
Typed values based on basic types
*/

abstract TokenAcesso(String) from String to String {}

/**
Global client Id at Acesso
**/
abstract TokenAdesao(String) from String to String {}

abstract TokenCartao(String) from String to String {}

/**
Generic token for requesting, confirming or executing user data changes
**/
abstract TokenAlteracao(String) from String to String {}

abstract SerializedDate(String) to String {
	function new(s)
		this = s;

	public function getTime():Float
	{
		assert(~/^\/Date\((-?\d+)\)\/$/.match(this), this);
		return Std.parseFloat(this.substring("/Date(".length, this.indexOf(")")));
	}

	@:to public function getDate():Date
		return Date.fromTime(getTime());

	public static function fromStringBR(s:String):SerializedDate
	{
		var r = ~/^(\d+)\/(\d+)\/(\d+)$/;
		if (!r.match(s))
			throw 'Invalid BR datestring: $s (expected DD/MM/YYYY)';
		var day = Std.parseInt(r.matched(1));
		var month = Std.parseInt(r.matched(2)) - 1;
		var year = Std.parseInt(r.matched(3));
		assert(day >= 1 && day <= 31, day);
		assert(month >= 0 && month <= 11, month + 1);
		assert(year >= 1900 && year <= Date.now().getFullYear(), year);
		var t = new Date(year, month, day, 0, 0, 0).getTime();
		return new SerializedDate('/Date($t)/');
	}

	@:from public static function fromDate(d:Date):SerializedDate
		return new SerializedDate('/Date(${d.getTime()})/');
}

abstract CodEspecieProduto(String) from String to String {}

/**
The user's CPF number
**/
abstract CodCliente(String) from String to String {}

@:enum abstract Language(Dynamic) {
	public var REST = 0;
}

@:enum abstract NomeCanal(String) {
	public var Webservice = "WEBSERVICE";
}

@:enum abstract Sexo(Int) {
	public var Nao_informado = 0;
	public var Masculino = 1;
	public var Feminino = 2;

	@:from static function fromInt(v:Int):Sexo
	{
		assert(v >= 0 && v <= 2, v);
		return cast v;
	}
}

@:enum abstract TpDocumento(Int) {
	public var RG = 0;
	public var RNE = 1;
	public var Passaporte = 2;

	@:from static function fromInt(v:Int):TpDocumento
	{
		assert(v >= 0 && v <= 2, v);
		return cast v;
	}
}

@:enum abstract TpTelefone(Int) {
	public var Celular = 0;
	public var Residencial = 1;
	public var Comercial = 2;
	public var Pessoal = 3;

	@:from static function fromInt(v:Int):TpTelefone
	{
		assert(v >= 0 && v <= 3, v);
		return cast v;
	}
}

@:enum abstract TpEndereco(Int) {
	public var Residencial = 0;
	public var Comercial = 1;
	public var Outros = 2;

	@:from static function fromInt(v:Int):TpEndereco
	{
		assert(v >= 0 && v <= 2, v);
		return cast v;
	}
}

@:enum abstract TpCliente(Int) {
	public var Nacional_pessoa_fisica = 0;
	public var Nacional_pessoa_juridica = 1;
	public var Estrangeiro = 2;

	@:from static function fromInt(v:Int):TpCliente
	{
		assert(v >= 0 && v <= 2, v);
		return cast v;
	}
}

@:enum abstract TpEmail(Int) {
	public var Residencial = 0;
	public var Comercial = 1;
	public var Secundario = 2;

	@:from static function fromInt(v:Int):TpEmail
	{
		assert(v >= 0 && v <= 2, v);
		return cast v;
	}
}

@:enum abstract TpEntrega(Int) {
	public var Carta_Simples = 3;

	@:from static function fromInt(v:Int):TpEntrega
	{
		assert(v >= 3 && v <= 3, v);
		return cast v;
	}
}

@:enum abstract TpMeioPagamento(Int) {
	public var BoletoBancario = 0;
	public var TransferenciaBancaria = 1;
	public var TED = 2;
	public var DOC = 3;
	public var Cartao = 4;
	public var NaoInformado = 5;
	public var Outros = 6;

	@:from static function fromInt(v:Int):TpMeioPagamento
	{
		assert(v >= 0 && v <= 6, v);
		return cast v;
	}
}

@:enum abstract TpOperacao(Int) {
	public var Embossing_Cartao = 0;
	public var Carga_Cartao = 1;
	public var Embossing_Carga_Cartao = 2;

	@:from static function fromInt(v:Int):TpOperacao
	{
		assert(v >= 0 && v <= 2, v);
		return cast v;
	}
}

/*
Intermidiate data types supplied by the API client
*/

typedef Meta = {
	?IpCliente : String,
	Language : Language,
	NomeCanal : NomeCanal,
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
	OrgaoExpedidor: String,
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

typedef DadosDoUsuario = {
	> DadosPrincipais,
	Celular : Telefone,
	CodCliente : CodCliente,
	Email : String,
	Endereco : Endereco,
	NomeCompleto : String,
	TpCliente : TpCliente
}

typedef Params<T> = {
	> Meta,
	Data : T
}

/*
Data types sent to the upstream APIs
*/

typedef SolicitarAdesaoClienteData = {
	CodEspecieProduto : CodEspecieProduto,
	Usuario : DadosDoUsuario
}

typedef AlterarEnderecoPortadorData = {
	CodCliente : CodCliente,
	NovoEndereco : Endereco,
	TokenAdesao : TokenAdesao,
	TpCliente : TpCliente
}

typedef SolicitarAlteracaoEmailPortadorData = {
	CodCliente : CodCliente,
	NovoEmail : {
		EnderecoEmail : String,
		Principal : Bool,
		TpEmail : TpEmail
	},
	TokenAdesao : TokenAdesao,
	TpCliente : TpCliente
}

typedef ConfirmarSolicitarAlteracaoEmailPortadorData = {
	CodCliente : CodCliente,
	TokenSolicitacaoAlteracao : TokenAlteracao,
	TokenAdesao : TokenAdesao,
	TpCliente : TpCliente
}

typedef EfetivarAlteracaoEmailPortadorData = {
	CodCliente : CodCliente,
	TokenEfetivacaoAlteracao : TokenAlteracao,
	TokenAdesao : TokenAdesao,
	TpCliente : TpCliente
}

typedef SolicitarAlteracaoTelefonePortadorData = {
	CodCliente : CodCliente,
	DDI : String,
	DDD : String,
	Numero : String,
	TokenAdesao : TokenAdesao,
	TpCliente : TpCliente
}

typedef ConfirmarAlteracaoTelefonePortadorData = {
	CodCliente : CodCliente,
	Token : TokenAlteracao,
	TokenAdesao : TokenAdesao,
	TpCliente : TpCliente
}

typedef ComplementarDadosPrincipaisData = {
	> DadosPrincipais,
	Portador : {
		CodCliente : CodCliente,
		TokenAdesao : TokenAdesao,
		TpCliente : TpCliente
	}
}

typedef SolicitarCartaoIdentificadoData = {
	CodCliente : CodCliente,
	CodEspecieProduto : CodEspecieProduto,
	TokenAdesao : TokenAdesao,
	TpCliente : TpCliente,
	TpEntrega : TpEntrega,
	ValorCarga : Float
}

typedef ConfirmarPagamentoData = {
	AgenciaRecebedora : String,
	AgenciaRecebedoraDV : String,
	BancoRecebedor : String,
	DataPagamento : SerializedDate,
	TokenOperacao : TokenCartao,
	TpMeioPagamento : TpMeioPagamento,
	TpOperacao : TpOperacao,
	ValorPagamento : Float
}

