package js;
import js.jquery.JQuery;
import webmaniabr.*;

@:keep @:expose
class CardReq
{
    public static function init()
    {
        new JQuery('document').ready(function(_){
            untyped $.fn.form.settings.rules.validaCPF = function(val){
                return MainJS.validaCPF(val);
            }

            untyped $('select').dropdown();
            calendar();
            validate();
            
            //TODO: Check if should fire change or blur evt
            new JQuery('#CEP').blur(function(_){
                //fuck this ( forgot how to $(this) )
                var cur = new JQuery('#CEP');
                var api = new Correios("PxQtu0NJd0v6B2sPBUR0leTE8Eryi1ZN", "KffqAXnZIz6Wmb9pYWYkCFag0qHw1z4jsKHeKw3IpKF39Qur");
                api.queryCep(cur.val(), response);
            });
        });
    }
    
    static function response (d : Correios.Response<Correios.Address>)
    {
        switch(d)
        {
            case Some(addr):
                new JQuery('#uf').val(addr.uf);
                new JQuery('#cidade').val(addr.cidade);
                new JQuery('#bairro').val(addr.bairro);
                new JQuery('#logradouro').val(addr.endereco);
            case None:
                //TODO: Handle invalid CEP
            case Failure(e):
                trace('error @webmania : $e');
        }
    }

    public static function onSubmit()
    {
        new JQuery('form').submit();
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
                        prompt : 'Preencha o campo de CEP'
                    }]
                },
                Cidade : {
                    rules : [{
                        type : 'empty',
                        prompt : 'Preencha o campo de CEP'
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
                        type : 'empty',
                        prompt : 'Digite seu CPF'
                    },
                    {
                        type : 'exactLength[11]',
                        prompt : 'Digite apenas os números'
                    },
                    {
                        type : 'validaCPF',
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