%{
/*
 * Soundy Script -- Analisador Sintatico (Trabalho Pratico 2)
 * Topico 3: Gramatica e Analisador Sintatico
 *
 * NOTACAO DE TRES ENDERECOS (Secao 4 da especificacao):
 * OP dest src1 src2 B C  →  dest = src1 OP src2
 *
 * ATRIBUICAO DE VALORES (Estrategia Assembly/RISC):
 * C/E dest 0 src B C     →  dest = 0 + src (Atribuicao direta)
 *
 * ORDEM DA DECLARACAO DE VARIAVEL (Secao 6):
 * TIPO Dm/A id Cm           →  sem valor inicial
 * TIPO Dm/A id Cm val B C   →  com valor inicial
 *
 * CONDICIONAL/REPETICAO (Secao 5):
 * A condicao e a primeira linha DENTRO do bloco (nota guia):
 * F C
 * cond B C     ← nota guia
 * comandos
 * Cm
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "TabelaSimbolo.h"

extern int yylineno;
extern FILE *yyin;
int  yylex(void);
void yyerror(const char *msg);
static void imprimir_codigo_numerado(FILE *arquivo);
static void inserir_simbolo(const char *nome, const char *tipo, const char *categoria, int linha);
static Tipo tipo_de_texto(const char *tipo);
static Categoria categoria_de_texto(const char *categoria);

static TabelaSimbolo *global = NULL;
static TabelaSimbolo *tabelaAtual = NULL;

%}

/* ==============================================================
 * %union
 * ============================================================== */
%union {
    int    ival;
    double fval;
    char   sval[256];
}

/* ==============================================================
 * DECLARACAO DOS TOKENS
 * ============================================================== */

%token FIM_LINHA

/* Tipos: carregam o nome textual do tipo */
%token <sval> TIPO   /* C/G=int  Am/E=float  Em/B=bool  F/C=char  G/D=null  C7=lista */

/* Palavras-chave de declaracao */
%token VAR            /* Dm/A  — declara variavel          */
%token FUNC           /* Bm/F# — declara funcao            */

/* Controle de fluxo */
%token IF             /* F     */
%token ELSE           /* Em    */
%token WHILE          /* Bm    */
%token KW_RETURN      /* Am    */
%token KW_BREAK       /* G#dim */
%token KW_CONTINUE    /* A7    */

/* Delimitadores de bloco
 * IMPORTANTE: END_BLOCO (Cm) tem dupla funcao na linguagem:
 * 1. Termina blocos if/while/func:  F C ... Cm
 * 2. Termina nomes em declaracoes:  C/G Dm/A x Cm  */
%token BLOCO_INI      /* C  */
%token END_BLOCO      /* Cm */

/* Operacoes de lista */
%token READ_LIST      /* C7maj — dest = lista[idx]    */
%token WRITE_LIST     /* Cm7   — lista[idx] = valor   */

/* Operadores aritmeticos (viram comandos de tres enderecos) */
%token OP_ADD         /* C/E   — soma          */
%token OP_SUB         /* Dm/F# — subtracao     */
%token OP_MUL         /* E/G   — multiplicacao */
%token OP_DIV         /* F/A   — divisao       */

/* Operadores logicos */
%token OP_AND         /* G/B  — e logico        */
%token OP_OR          /* Am/C — ou logico       */
%token OP_NOT         /* Bm/D — negacao (unario) */

/* Operadores relacionais */
%token OP_EQ          /* C7/E   — igual          */
%token OP_NEQ         /* Dm7/F# — diferente      */
%token OP_GT          /* E7/G   — maior que      */
%token OP_LT          /* F7/A   — menor que      */
%token OP_GTE         /* G7/B   — maior ou igual */
%token OP_LTE         /* A7/C#  — menor ou igual */

/* Literais */
%token <ival> LIT_INT
%token <fval> LIT_FLOAT
%token <sval> LIT_CHAR
%token <sval> LIT_STRING
%token <ival> LIT_BOOL

/* Identificadores e acordes livres */
%token <sval> ID
%token <sval> ACORDE_LIVRE

%nonassoc DECL_SEM_INICIALIZACAO
%nonassoc ID LIT_INT LIT_FLOAT LIT_CHAR LIT_STRING LIT_BOOL ACORDE_LIVRE

%%

/* ==============================================================
 * REGRAS DE PRODUCAO
 * ============================================================== */

program
    : decl_list
    | /* programa vazio */
    ;

/* Um programa e uma lista de declaracoes e comandos */
decl_list
    : decl_list decl
    | decl
    ;

decl
    : func_decl
    | stmt
    ;

/* ----------------------------------------------------------
 * DECLARACAO DE VARIAVEL
 *
 * TIPO Dm/A id Cm              →  sem valor inicial
 * TIPO Dm/A id Cm operando BC  →  com valor inicial
 * ---------------------------------------------------------- */
var_decl
    : TIPO VAR ID END_BLOCO %prec DECL_SEM_INICIALIZACAO
        { inserir_simbolo($3, $1, "variavel", yylineno); }
    | TIPO VAR ID END_BLOCO operando FIM_LINHA
        { inserir_simbolo($3, $1, "variavel", yylineno); }
    ;

/* ----------------------------------------------------------
 * DECLARACAO DE FUNCAO
 * ---------------------------------------------------------- */
func_decl
    : TIPO FUNC ID param_list BLOCO_INI stmt_list END_BLOCO
        { inserir_simbolo($3, $1, "funcao", yylineno); }
    | TIPO FUNC ID BLOCO_INI stmt_list END_BLOCO
        { inserir_simbolo($3, $1, "funcao", yylineno); }
    ;

/* Parametros: lista de pares TIPO ID listados antes do 'C' */
param_list
    : param_list param
    | param
    ;

param
    : TIPO ID
    ;

/* ----------------------------------------------------------
 * LISTA DE COMANDOS
 * ---------------------------------------------------------- */
stmt_list
    : stmt_list stmt
    | /* vazio (corpo pode ser vazio) */
    ;

stmt
    : var_decl
    | op_binario
    | op_unario
    | if_stmt
    | while_stmt
    | return_stmt
    | break_stmt
    | continue_stmt
    | read_list_stmt
    | write_list_stmt
    | func_call_stmt
    ;

/* ----------------------------------------------------------
 * OPERANDO
 * Um operando e um identificador ou literal.
 * Aparece como fonte (src) nas instrucoes de tres enderecos.
 * ---------------------------------------------------------- */
operando
    : ID
    | LIT_INT
    | LIT_FLOAT
    | LIT_CHAR
    | LIT_STRING
    | LIT_BOOL
    | ACORDE_LIVRE
    ;

/* ----------------------------------------------------------
 * OPERACOES BINARIAS DE TRES ENDERECOS (E ATRIBUICAO)
 *
 * Sintaxe: OP dest src1 src2 BC
 * Obs: Para atribuicao direta, usa-se a soma com zero.
 * Ex: C/E flag 0 true B C → flag = 0 + true
 * ---------------------------------------------------------- */
op_binario
    : OP_ADD ID operando operando FIM_LINHA
    | OP_SUB ID operando operando FIM_LINHA
    | OP_MUL ID operando operando FIM_LINHA
    | OP_DIV ID operando operando FIM_LINHA
    | OP_AND ID operando operando FIM_LINHA
    | OP_OR  ID operando operando FIM_LINHA
    | OP_EQ  ID operando operando FIM_LINHA
    | OP_NEQ ID operando operando FIM_LINHA
    | OP_GT  ID operando operando FIM_LINHA
    | OP_LT  ID operando operando FIM_LINHA
    | OP_GTE ID operando operando FIM_LINHA
    | OP_LTE ID operando operando FIM_LINHA
    ;

/* ----------------------------------------------------------
 * OPERACAO UNARIA DE TRES ENDERECOS
 * ---------------------------------------------------------- */
op_unario
    : OP_NOT ID operando FIM_LINHA
    ;

/* ----------------------------------------------------------
 * IF / IF-ELSE
 * ---------------------------------------------------------- */
if_stmt
    : IF BLOCO_INI ID FIM_LINHA stmt_list END_BLOCO
    | IF BLOCO_INI ID FIM_LINHA stmt_list END_BLOCO ELSE BLOCO_INI stmt_list END_BLOCO
    ;

/* ----------------------------------------------------------
 * WHILE
 * ---------------------------------------------------------- */
while_stmt
    : WHILE BLOCO_INI ID FIM_LINHA stmt_list END_BLOCO
    ;

/* ----------------------------------------------------------
 * RETURN / BREAK / CONTINUE
 * ---------------------------------------------------------- */
return_stmt
    : KW_RETURN operando FIM_LINHA
    ;

break_stmt
    : KW_BREAK FIM_LINHA
    ;

continue_stmt
    : KW_CONTINUE FIM_LINHA
    ;

/* ----------------------------------------------------------
 * CHAMADA DE FUNCAO (Function Call)
 *
 * Sintaxe: id operando1 operando2 ... BC
 * Exemplo: soma 10 20 B C
 * ---------------------------------------------------------- */
func_call_stmt
    : ID operando_list FIM_LINHA
    ;

operando_list
    : operando_list operando
    | /* vazio */
    ;

/* ----------------------------------------------------------
 * OPERACOES DE LISTA
 * ---------------------------------------------------------- */
read_list_stmt
    : READ_LIST ID ID operando FIM_LINHA
    ;

write_list_stmt
    : WRITE_LIST ID operando operando FIM_LINHA
    ;

%%

static Tipo tipo_de_texto(const char *tipo)
{
    if (strcmp(tipo, "int") == 0 || strcmp(tipo, "C/G") == 0) return TIPO_INT;
    if (strcmp(tipo, "float") == 0 || strcmp(tipo, "Am/E") == 0) return TIPO_FLOAT;
    if (strcmp(tipo, "bool") == 0 || strcmp(tipo, "Em/B") == 0) return TIPO_BOOL;
    if (strcmp(tipo, "char") == 0 || strcmp(tipo, "F/C") == 0) return TIPO_CHAR;
    if (strcmp(tipo, "null") == 0 || strcmp(tipo, "G/D") == 0) return TIPO_NULL;
    if (strcmp(tipo, "lista") == 0 || strcmp(tipo, "C7") == 0) return TIPO_LISTA;
    return TIPO_NULL;
}

static Categoria categoria_de_texto(const char *categoria)
{
    if (strcmp(categoria, "funcao") == 0) return CAT_FUNCAO;
    if (strcmp(categoria, "parametro") == 0) return CAT_PARAMETRO;
    return CAT_VARIAVEL;
}

static void inserir_simbolo(const char *nome, const char *tipo, const char *categoria, int linha)
{
    if (tabelaAtual == NULL)
    {
        return;
    }

    inserirSimbolo(
        tabelaAtual,
        criarSimbolo(
            (char *)nome,
            tipo_de_texto(tipo),
            categoria_de_texto(categoria),
            linha
        )
    );
}

void yyerror(const char *msg)
{
    (void)msg;
    printf("Erro próximo a linha %d - Programa sintaticamente incorreto\n", yylineno);
}

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
