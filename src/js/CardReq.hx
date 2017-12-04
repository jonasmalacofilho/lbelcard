package js;
import js.jquery.JQuery;

@:keep @:expose
class CardReq
{
    public static function init()
    {
        new JQuery('document').ready(function(_){
            untyped $.fn.form.settings.rules.validCPF = function(val){
                return validaCPF(val);
            }

            untyped $('select').dropdown();
            calendar();
            validate();
        });
    }

    static function calendar()
    {
        untyped $(".ui.calendar").calendar({
				ampm : false,
				type : 'date',
				startMode : 'year',
				formatter : {
				date : function(date, settings)
				{
					if(!date) return "";
					var day = StringTools.lpad(date.getDate()+'','0',2);
					var mn = StringTools.lpad(date.getMonth() + 1+ '','0',2);
					var year = date.getFullYear();
					return '$day/$mn/$year';
				}
				}
			});
    }

    // From http://www.receita.fazenda.gov.br/Aplicacoes/ATCTA/CPF/funcoes.js
    static function validaCPF (e : String) : Bool
    {
        var reg = ~/\D/g;
        
        //Should be numbers only
        if(!reg.match(e))
            return false;
        
        var sum : Int = 0;
        var rest : Int = 0;

        if(e == '00000000000')
            return false;

        for (i in 1...9)
            sum = sum + Std.parseInt(e.substring(i-1,i)) * (11 - i);
        
        rest = (sum*10) % 11;
        if(rest == 10 || rest == 11)
            rest = 0;
        
        if (rest != Std.parseInt(e.substring(9,10)))
            return false;
        
        sum = 0;

        for(i in 1...10)
            sum = sum + Std.parseInt(e.substring(i-1,i)) * (12 - i);
        
        rest = sum % 11;

        if(rest == 10 || rest == 11)
            rest = 0;
        if(rest != Std.parseInt(e.substring(10,11)))
            return false;

        return true;
    }

    static function validate()
    {
        untyped $('.ui.form').form({
            'inline' : true,
            on : 'blur',
            fields : {
                NomeCompleto : {
                    rules : [{
                        type : 'empty',
                        prompt : 'Digite seu nome completo (sem abreviações)'
                    }]
                },
                TpSexo : {
                    rules : [{
                        type : 'empty',
                        prompt : 'Selecione uma opção'
                    }]
                },
                DtNascimento : {
                    rules : [{
                    type : 'empty',
                    prompt : 'Selecione a data de nascimento'
                    }]
                },
                NomePai : {
                    rules : [{
                        type : 'empty',
                        prompt : 'Digite o nome completo de seu pai (sem abreviações)'
                    }]
                },
                NomeMae : {
                    rules : [{
                        type : 'empty',
                        prompt : 'Digite o nome completo de sua mãe (sem abreviações)'
                    }]
                },
                DDI : {
                    rules : [{
                        type : 'empty',
                        prompt : 'Digite um DDI válido'
                    }]
                },
                DDD : {
                    rules : [{
                        type : 'empty',
                        prompt : 'Digite o DDD do telefone informado'
                    },
                    {
                        type : 'exactLength[2]',
                        prompt : 'DDD inválido, ele deve possuir apenas 2 dígitos'
                    }]
                },
                NumeroTel : {
                    rules : [{
                        type : 'empty',
                        prompt : 'Digite um número de telefone'
                    },
                    {
                        type : 'regExp[/[0-9]+/g]',
                        prompt : 'Digite apenas números'
                    },
                    {
                        type : 'minLength[8]',
                        prompt : 'Número de telefone inválido'
                    },
                    {
                        type : 'maxLength[9]',
                        prompt : 'Número de telefone inválido'
                    }]
                },
                TpTelefone : {
                    rules : [{
                        type : 'empty',
                        prompt : 'Selecione o tipo de telefone'
                    }]
                },
                CEP : {
                    rules : [{
                        type : 'exactLength[8]',
                        prompt : 'CEP Inválido'
                    },
                    {
                        type : 'integer',
                        prompt : 'Digite apenas números'
                    }]
                },
                UF : {
                    rules : [{
                        type : 'empty',
                        prompt : 'Selecione um Estado'
                    }]
                },
                Cidade : {
                    rules : [{
                        type : 'empty',
                        prompt : 'Digite uma cidade, ou preencha o campo de CEP'
                    }]
                },
                Bairro : {
                    rules : [{
                        type : 'empty',
                        prompt : 'Digite o bairro, ou preencha o campo de CEP'
                    }]
                },
                Logradouro : {
                    rules : [{
                        type : 'empty',
                        prompt : 'Digite a rua ou preencha o campo de CEP'
                    }]
                },
                NumeroRes : {
                    rules : [{
                        type : 'empty',
                        prompt : "Preencha o número de residência"
                    },
                    {
                        type : 'number',
                        prompt : "Digite apenas números, letras e outros caracteres devem ser preenchidos no campo Complemento"
                    }]
                },
                //Skipping complemento
                TpEndereco : {
                    rules : [{
                        type : 'empty',
                        prompt : "Preencha o Tipo de Complemento"
                    }]
                },
                Email : {
                    rules : [{
                        type : 'empty',
                        prompt : 'Digite seu e-mail de contato'
                    }
                    ,{
                        type : 'email',
                        prompt : 'Digite um e-mail válido'
                    }]
                },
                CodCliente : {
                    rules : [{
                        type : 'emtpy',
                        prompt : 'Digite seu CPF'
                    },
                    {
                        type : 'exactLength[11]',
                        prompt : 'Digite apenas os números'
                    },
                    {
                        type : 'validCPF',
                        prompt : 'CPF Inválido'
                    }]
                },
                NumDocumento : {
                    rules : [{
                        type : 'empty',
                        prompt : 'Digite um número de documento'
                    },
                    {
                        type : 'regExp[/[a-zA-Z0-9]+/g]',
                        prompt : 'Digite apenas números e letras'
                    }]
                },
                DtExpedicao : {
                    rules : [{
                        type : 'empty',
                        prompt : 'Digite a data de expedição do documento'
                    }]
                },
                TpDocumento : {
                    rules : [{
                        type : 'empty',
                        prompt : 'Preencha o tipo de Documento informado'
                    }]
                },
                //this isn't req...but eh
                OrgaoExpeditor : {
                    rules : [{
                        type : 'empty',
                        prompt : 'Preencha a sigla do órgão expeditor do documento'
                    }]
                },
                UFOrgao : {
                    rules : [{
                        type : 'empty',
                        prompt : "Preencha o estado do órgão emissor do Documento"
                    }]
                },
                PaisOrgao : {
                    rules : [{
                        type : 'empty',
                        prompt : 'Preencha o país do órgão emissor do documento'
                    }]
                }




            }
        });
    }
}