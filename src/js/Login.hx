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
            }
            validate();
       		untyped $('#CPF').mask('000.000.000-00');
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
                        type : 'validaCPF',
                        prompt : 'CPF Inválido'
                    }]
                }
            }
        });
    }
}
