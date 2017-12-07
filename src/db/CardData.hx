package db;
import sys.db.Object;
import sys.db.Types;
import haxe.Json;

using StringTools;

//TODO: Sort this stuff as a readable (reasonable) stuff (aka... this order is a mess!)
class CardData extends Object
{
    public var id : SId;
    @:relation(cardReq_id) public var cardReq : CardRequest;

    public var CodEspecieProduto : SString<255>; //TODO: Add Cte
    
    /****   CEL Data Block   ****/
    public var DDD : SString<2>;
    //There is a MAX number (should be around 5 tbh)
    public var DDI : SString<10>;
    public var NumeroTel : SString<9>;
    //Assuming this is cte.
    public var TpTelefone : SString<1> = "0";
    
    /****   Document Block  ****/
    //CPF
    public var CodCliente : SString<11>;
    //Convert that mess to MS Style!
    public var DtExpedicao : SFloat;

    public var NumDocumento : SString<20>;
    //NOT Required, but they ask for Country + UF, soo..
    public var OrgaoExpedidor : SString<20>;
    public var PaisOrgao : SString<30>;
    public var TpDocumento : SInt;
    public var UFOrgao : SString<2>;

    /****  Personal Info    ****/
    public var DtNascimento : SFloat;
    public var Email : SString<125>;
    public var Bairro : SString<30>;
    public var CEP : SString<8>;
    public var Cidade : SString<60>;
    
    //Optional
    public var Complemento : Null<SString<20>>;

    public var Logradouro : SString<100>;
    public var NumeroRes : SString<10>;
    public var TpEndereco : SInt;
    public var UF : SString<2>;
    public var NomeCompleto : SString<100>;
    public var NomeMae : SString<100>;
    public var TpCliente : SString<2>;
    public var TpSexo : SInt;

    /****   Other stuff     ****/
    public var Language : SInt = 0;
    public var NomeCanal : SString<15> = "WEBSERVICE";
    
    //public var RecId : Float;
    //public var Token : SString<100>;

    //Extra info:

    public var lastedit : SDateTime;
    public var last_update : SDateTime;
    public var last_check : SDateTime;

    public function toJSON(RecID : Float, token_acesso : String)
    {
        return Json.stringify({
            Data : {
                CodEspecieProduto : this.CodEspecieProduto,
                Usuario : {
                    //omiting citizenship info
                    CodCliente : CodCliente,
                    //TODO : Format
                    DtNascimento : DtNascimento,
                    Email : Email,
                    NomeCompleto : NomeCompleto,
                    NomeMae : NomeMae,
                    TpCliente : TpCliente,
                    TpSexo : TpSexo,

                    Celular : {
                        DDI : DDI,
                        DDD : DDD,
                        Numero : NumeroTel,
                        TpTelefone : Std.parseInt(TpTelefone)
                    },
                    
                    Documento : {
                         //TODO: Format
                        DtExpedicao : DtExpedicao,
                        NumDocumento : NumDocumento,
                        OrgaoExpedidor : OrgaoExpedidor,
                        PaisOrgao : PaisOrgao,
                        UFOrgao : UFOrgao,
                        TpDocumento : TpDocumento,
                    },

                    Endereco : {
                        Bairro : Bairro,
                        CEP : CEP,
                        Cidade : Cidade,
                        Complemento : Complemento,
                        Logradouro : Logradouro,
                        Numero : NumeroRes,
                        TpEndereco : TpEndereco,
                        UF : UF
                    },

                    Language : Language,
                    NomeCanal : NomeCanal,
                    RecId : RecID,
                    TokenAcesso : token_acesso

                }
            }
        });
    }

}

