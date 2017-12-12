package js;
import js.jquery.JQuery;

@:keep @:expose
class Login
{
    public static function init()
    {
        new JQuery('document').ready(function(_){
            untyped $.fn.form.settings.rules.validaCPF = function(val){
                return MainJS.validaCPF(val);
            };
            

            validate();
       		untyped $('#CPF').mask('000.000.000-00', {reverse : true});

            //prevent Enter to submit
            new JQuery('input').keydown(function(evt){
               //enter key
                if(evt.keyCode == 13)
                {
                    evt.preventDefault();
                    evt.stopImmediatePropagation();
                }
            });

        });
    }
    
   


    static function validate()
    {
        untyped $('.ui.form').form({
            'inline' : true,
            on: 'blur',
            fields : {
                belNumber : {
                    rules : [{
                        type : 'empty',
                        prompt : 'Digite seu número de Consultor L\'BEL'
                    }]
                },
                cpf : {
                   rules : [{
                        type : 'empty',
                        prompt : 'Digite seu CPF'
                    },
                    {
						type: 'exactLength[14]',
						prompt : 'Por favor, preencha com os 11 dígitos'
					},
                    {
                        type : 'validaCPF',
                        prompt : 'CPF Inválido'
                    }]
                },
                recaptcha: {
                    identifier: 'recaptcha',
                    rules: 
                    [{
                        type: 'empty',
                        prompt: 'Por favor, faça a verificação de Recaptcha'
                    }]
                }
            }
        });
    }
}
