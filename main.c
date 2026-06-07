#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "TabelaSimbolo.h"

/*
 * Interface principal do compilador:
 * abre o arquivo, numera o codigo, chama o parser
 * e imprime o resultado final.
 */
extern int yyparse(void);
extern FILE *yyin;
extern int yylineno;

TabelaSimbolo *global = NULL;
TabelaSimbolo *tabelaAtual = NULL;

static void imprimir_codigo_numerado(FILE *arquivo)
{
    char linha[1024];
    int numero_linha = 1;

    while (fgets(linha, sizeof(linha), arquivo) != NULL)
    {
        printf("%4d | %s", numero_linha, linha);

        if (strchr(linha, '\n') == NULL)
        {
            printf("\n");
        }

        numero_linha++;
    }
}

int main(int argc, char *argv[])
{
    int resultado;

    if (argc != 2)
    {
        printf("Uso: %s <arquivo.sndy>\n", argv[0]);
        return 1;
    }

    yyin = fopen(argv[1], "r");
    if (yyin == NULL)
    {
        printf("Erro ao abrir o arquivo.\n");
        return 1;
    }

    global = criarTabelaSimbolo("global", NULL);
    tabelaAtual = global;

    printf("Código fonte numerado:\n");
    imprimir_codigo_numerado(yyin);
    printf("\n");

    rewind(yyin);
    yylineno = 1;

    resultado = yyparse();

    if (resultado == 0)
    {
        printf("\nTabela de símbolos:\n");
        if (global != NULL)
        {
            imprimirArvore(global, 0);
        }
        printf("Programa sintaticamente correto\n");
    }

    fclose(yyin);
    return resultado == 0 ? 0 : 1;
}
