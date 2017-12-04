package js;
import js.jquery.JQuery;

@:keep @:expose
class Login
{
    public static function init()
    {
        new JQuery('document').ready(function(_){
            untyped $.fn.form.settings.rules.validCPF = function(val){
                return MainJS.validaCPF(val);
            }
            validate();
        });
    }

    static function validate()
    {
        untyped $('ui.form').form({
            'inline' : true,
            on: 'blur',
            fields : {
                n_consultor : {
                    rules : [{
                        type : 'empty',
                        prompt : 'Digite seu número de Consultor L\'BEL'
                    }]
                },
                CPF : {
                   rules : [{
                        type : 'emtpy',
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
                }
            }
        });
    }
}