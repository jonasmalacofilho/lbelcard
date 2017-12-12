package db.types;

import acesso.Data;

enum AcessoCardStep {
	SolicitarAdesaoCliente;
	AlterarEnderecoPortador(client:TokenAdesao);
	SolicitarAlteracaoEmailPortador(client:TokenAdesao);
	ConfirmarSolicitacaoAlteracaoEmailPortador(client:TokenAdesao, tounce:TokenAlteracao);
	EfetivarAlteracaoEmailPortador(client:TokenAdesao, tounce:TokenAlteracao);
	SolicitarAlteracaoTelefonePortador(client:TokenAdesao);
	ConfirmarAlteracaoTelefonePortador(client:TokenAdesao, tounce:TokenAlteracao);
	ComplementarDadosPrincipais(client:TokenAdesao);
	SolicitarCartaoIdentificado(client:TokenAdesao);
	ConfirmarPagamento(card:TokenCartao, cost:Float);
}

