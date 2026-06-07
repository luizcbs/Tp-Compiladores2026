#include <stdio.h>
#include "TabelaSimbolo.h"

int main()
{
    printf("=====================================\n");
    printf("TESTE DA TABELA DE SIMBOLOS\n");
    printf("=====================================\n\n");

    /* Cria o TabelaSimbolo global */
    TabelaSimbolo *global = criarTabelaSimbolo("global", NULL);

    /* Variável que representa o TabelaSimbolo atual */
    TabelaSimbolo *TabelaSimboloAtual = global;

    printf("TabelaSimbolo global criado.\n\n");

    /* Teste criarSimbolo + inserirSimbolo */

    inserirSimbolo(
        TabelaSimboloAtual,
        criarSimbolo(
            "idade",
            TIPO_INT,
            CAT_VARIAVEL,
            1
        )
    );

    inserirSimbolo(
        TabelaSimboloAtual,
        criarSimbolo(
            "media",
            TIPO_FLOAT,
            CAT_VARIAVEL,
            2
        )
    );

    inserirSimbolo(
        TabelaSimboloAtual,
        criarSimbolo(
            "somar",
            TIPO_INT,
            CAT_FUNCAO,
            5
        )
    );

    printf("Simbolos globais inseridos.\n\n");

    /* Teste de duplicação */

    printf("Tentando inserir 'idade' novamente:\n");

    inserirSimbolo(
        TabelaSimboloAtual,
        criarSimbolo(
            "idade",
            TIPO_INT,
            CAT_VARIAVEL,
            10
        )
    );

    printf("\n");

    /* Cria TabelaSimbolo da função */

    TabelaSimbolo *TabelaSimboloFuncao =
        criarTabelaSimbolo("somar", TabelaSimboloAtual);

    adicionarFilho(
        TabelaSimboloAtual,
        TabelaSimboloFuncao
    );

    entrarTabalaSimbolo(
        &TabelaSimboloAtual,
        TabelaSimboloFuncao
    );

    printf("Entrou no TabelaSimbolo da funcao.\n\n");

    /* Parâmetros */

    inserirSimbolo(
        TabelaSimboloAtual,
        criarSimbolo(
            "a",
            TIPO_INT,
            CAT_PARAMETRO,
            5
        )
    );

    inserirSimbolo(
        TabelaSimboloAtual,
        criarSimbolo(
            "b",
            TIPO_INT,
            CAT_PARAMETRO,
            5
        )
    );

    /* Variável local */

    inserirSimbolo(
        TabelaSimboloAtual,
        criarSimbolo(
            "resultado",
            TIPO_INT,
            CAT_VARIAVEL,
            6
        )
    );

    printf("Parametros e variaveis locais inseridos.\n\n");

    /* Teste buscarNoTabelaSimboloAtual */

    Simbolo *s =
        buscarNaTabelaSimboloAtual(
            TabelaSimboloAtual,
            "resultado"
        );

    if(s != NULL)
    {
        printf(
            "Encontrado no TabelaSimbolo atual: %s\n\n",
            s->nome
        );
    }

    /* Cria TabelaSimbolo IF */

    TabelaSimbolo *TabelaSimboloIf =
        criarTabelaSimbolo(
            "if",
            TabelaSimboloAtual
        );

    adicionarFilho(
        TabelaSimboloAtual,
        TabelaSimboloIf
    );

    entrarTabalaSimbolo(
        &TabelaSimboloAtual,
        TabelaSimboloIf
    );

    inserirSimbolo(
        TabelaSimboloAtual,
        criarSimbolo(
            "temp",
            TIPO_INT,
            CAT_VARIAVEL,
            8
        )
    );

    printf("Entrou no TabelaSimbolo IF.\n\n");

    /* Sai do IF */

    sairTabelaSimbolo(&TabelaSimboloAtual);

    printf(
        "Saiu do IF. TabelaSimbolo atual: %s\n\n",
        TabelaSimboloAtual->nome
    );

    /* Sai da função */

    sairTabelaSimbolo(&TabelaSimboloAtual);

    printf(
        "Saiu da funcao. TabelaSimbolo atual: %s\n\n",
        TabelaSimboloAtual->nome
    );

    /* Imprime toda a árvore */

    printf("\n");
    printf("=====================================\n");
    printf("IMPRESSAO DA ARVORE\n");
    printf("=====================================\n\n");

    imprimirArvore(global, 0);

    return 0;
}