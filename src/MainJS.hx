import js.CardReq;


@:keep @:expose
class MainJS
{
    public static function main()
    {}

    // From http://www.receita.fazenda.gov.br/Aplicacoes/ATCTA/CPF/funcoes.js
    public static function validaCPF (e : String) : Bool
    {
        var sum : Int = 0;
        var rest : Int = 0;

        if(e == '00000000000')
            return false;

        for (i in 1...10)
            sum = sum + Std.parseInt(e.substring(i-1,i)) * (11 - i);
        
        trace(sum);
        rest = (sum*10) % 11;
        if(rest == 10 || rest == 11)
            rest = 0;
        
        if (rest != Std.parseInt(e.substring(9,10)))
            return false;
        
        sum = 0;

        for(i in 1...11)
            sum = sum + Std.parseInt(e.substring(i-1,i)) * (12 - i);
        
        rest = (sum*10) % 11;

        if(rest == 10 || rest == 11)
            rest = 0;
        if(rest != Std.parseInt(e.substring(10,11)))
            return false;

        return true;
    }
}