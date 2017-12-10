package js;
import js.jquery.JQuery;
import webmaniabr.*;
using StringTools;

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
                
                var cur = js.jquery.Helper.JTHIS;
                
                if(cur.val().length != 9)
                    return;

                var api = new Correios("PxQtu0NJd0v6B2sPBUR0leTE8Eryi1ZN", "KffqAXnZIz6Wmb9pYWYkCFag0qHw1z4jsKHeKw3IpKF39Qur");
                api.queryCep(cur.val(), response);
                new JQuery('#loader').addClass('active');

            });

            untyped $('#CPF').mask('000.000.000-00');
            untyped $('#CEP').mask('00000-000');
            untyped $('#cel').mask('00000-0000');

            storage();
        });
    }
    
    static function storage()
    {
        var sess_storage = js.Browser.getSessionStorage();

            if(sess_storage != null && 
            sess_storage.key(0) != null &&
            sess_storage.key(0) != "")
            {
                for(i in 0...sess_storage.length)
                {
                    var k = sess_storage.key(i);
                    var val = sess_storage.getItem(k);
                    
                    if(val == null || val.length == 0)
                        continue;

                    var elem = new JQuery('input[name="${k}"]');
                    
                    if(!k.startsWith("Dt"))
                        elem.val(val);
                    else
                        untyped elem.parent().parent().calendar('set date', val, true, false);
                }
            }

            //save stuff on form submit
            new JQuery('form').submit(function(_)
            {
                if(sess_storage == null)
                return;

                var sess_storage = js.Browser.getSessionStorage();
                if(sess_storage == null)
                    return;
                
                new JQuery('input').each(function(i,elem)
                {
                    var cur = new JQuery(elem);
                    sess_storage.setItem(cur.attr('name'), cur.val());
                });                
            });
    }

    static function response (d : Correios.Response<Correios.Address>)
    {
        new JQuery('#loader').removeClass('active');
        switch(d)
        {
            case Some(addr):
                new JQuery('#uf').val(addr.uf);
                new JQuery('#cidade').val(addr.cidade);
                new JQuery('#bairro').val(addr.bairro);
                new JQuery('#logradouro').val(addr.endereco);
            case None:
                //TODO: Fix this later
                js.Browser.alert('CEP inválido! Por favor, verifique se o valor está correto');
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
                        type : 'exactLength[9]',
                        prompt : 'CEP Inválido'
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