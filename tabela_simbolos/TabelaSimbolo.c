#include "TabelaSimbolo.h"

TabelaSimbolo *criarTabelaSimbolo(char *nome, TabelaSimbolo *pai)
{
    TabelaSimbolo *novo = (TabelaSimbolo *) malloc(sizeof(TabelaSimbolo));

    if (novo == NULL)
    {
        printf("Erro ao alocar memoria para Tabela de Simbolo.\n");
        exit(1);
    }

    strcpy(novo->nome, nome);

    novo->pai = pai;

    novo->qtdFilhos = 0;
    novo->qtdSimbolos = 0;

    for (int i = 0; i < MAX_FILHOS; i++)
    {
        novo->filhos[i] = NULL;
    }

    return novo;
}

void adicionarFilho(TabelaSimbolo *pai, TabelaSimbolo *filho)
{
    if (pai == NULL || filho == NULL)
    {
        return;
    }

    if (pai->qtdFilhos >= MAX_FILHOS)
    {
        printf("Erro: limite de filhos excedido no Tabela de Simbolo '%s'\n",
               pai->nome);
        return;
    }

    pai->filhos[pai->qtdFilhos] = filho;
    pai->qtdFilhos++;

    filho->pai = pai;
}

Simbolo criarSimbolo(char *nome, Tipo tipo, Categoria categoria, int linha)
{
    Simbolo s;

    strcpy(s.nome, nome);

    s.tipo = tipo;
    s.categoria = categoria;
    s.linhaDeclaracao = linha;

    return s;
}

int inserirSimbolo(TabelaSimbolo *tabela, Simbolo simbolo)
{
    if (tabela == NULL)
        return 0;

    for (int i = 0; i < tabela->qtdSimbolos; i++)
    {
        if (strcmp(
                tabela->simbolos[i].nome,
                simbolo.nome
            ) == 0)
        {
            printf(
                "Erro: simbolo '%s' ja declarado no tabela '%s'.\n",
                simbolo.nome,
                tabela->nome
            );

            return 0;
        }
    }

   tabela->simbolos[
       tabela->qtdSimbolos
    ] = simbolo;

   tabela->qtdSimbolos++;

    return 1;
}

Simbolo *buscarNaTabelaSimboloAtual(TabelaSimbolo *tabela, char *nome)
{
    if (tabela == NULL)
        return NULL;

    for (int i = 0; i < tabela->qtdSimbolos; i++)
    {
        if (strcmp(
                tabela->simbolos[i].nome,
                nome
            ) == 0)
        {
            return &tabela->simbolos[i];
        }
    }

    return NULL;
}

void entrarTabalaSimbolo(TabelaSimbolo **tabelaAtual,TabelaSimbolo *novaTabela)
{
    if (novaTabela != NULL)
    {
        *tabelaAtual = novaTabela;
    }
}

void sairTabelaSimbolo(TabelaSimbolo **tabelaAtual)
{
    if (*tabelaAtual != NULL &&
        (*tabelaAtual)->pai != NULL)
    {
        *tabelaAtual =
            (*tabelaAtual)->pai;
    }
}

char *tipoParaString(Tipo tipo)
{
    switch(tipo)
    {
        case TIPO_INT:   return "Int";
        case TIPO_FLOAT: return "Float";
        case TIPO_BOOL:  return "Bool";
        case TIPO_NULL:  return "Null";
        case TIPO_LISTA: return "Lista";
        default:         return "Desconhecido";
    }
}

char *categoriaParaString(Categoria categoria)
{
    switch(categoria)
    {
        case CAT_VARIAVEL:
            return "Variavel";

        case CAT_FUNCAO:
            return "Funcao";

        case CAT_PARAMETRO:
            return "Parametro";

        default:
            return "Desconhecida";
    }
}

void imprimirArvore(TabelaSimbolo *escopo, int nivel)
{
    if (escopo == NULL)
        return;

    for (int i = 0; i < nivel; i++)
        printf("    ");

    printf("=========================================================\n");

    for (int i = 0; i < nivel; i++)
        printf("    ");

    printf("ESCOPO: %s\n", escopo->nome);

    for (int i = 0; i < nivel; i++)
        printf("    ");

    printf("=========================================================\n");

    for (int i = 0; i < nivel; i++)
        printf("    ");

    printf("%-15s %-10s %-15s %-5s\n",
           "Nome",
           "Tipo",
           "Categoria",
           "Linha");

    for (int i = 0; i < nivel; i++)
        printf("    ");

    printf("---------------------------------------------------------\n");

    for (int i = 0; i < escopo->qtdSimbolos; i++)
    {
        Simbolo s = escopo->simbolos[i];

        for (int j = 0; j < nivel; j++)
            printf("    ");

        printf("%-15s %-10s %-15s %-5d\n",
               s.nome,
               tipoParaString(s.tipo),
               categoriaParaString(s.categoria),
               s.linhaDeclaracao);
    }

    for (int i = 0; i < nivel; i++)
        printf("    ");

    printf("=========================================================\n\n");

    for (int i = 0; i < escopo->qtdFilhos; i++)
    {
        imprimirArvore(
            escopo->filhos[i],
            nivel + 1
        );
    }
}