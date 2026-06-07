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
#include "tabela_simbolos.h"

extern int lineno;
int  yylex(void);
void yyerror(const char *msg);

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
%token SWITCH         /* E     */
%token CASE           /* A     */
%token KW_RETURN      /* Am    */
%token KW_BREAK       /* G#dim */
%token KW_CONTINUE    /* A7    */

/* Entrada e Saida */
%token PRINT          /* G     — Saida padrao              */
%token READ           /* Dm    — Entrada padrao            */

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

/* Tipo do nao-terminal 'type' para propagar o nome do tipo */
%type <sval> type

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
 * TIPO
 * Nao-terminal auxiliar que propaga o nome do tipo ($$ = $1).
 * Usado em var_decl, func_decl e param para capturar o tipo.
 * ---------------------------------------------------------- */
type
    : TIPO { strcpy($$, $1); }
    ;

/* ----------------------------------------------------------
 * DECLARACAO DE VARIAVEL
 *
 * TIPO Dm/A id Cm              →  sem valor inicial
 * TIPO Dm/A id Cm operando BC  →  com valor inicial
 * ---------------------------------------------------------- */
var_decl
    : type VAR ID END_BLOCO
        { inserir_simbolo($3, $1, "variavel", lineno); }
    | type VAR ID END_BLOCO operando FIM_LINHA
        { inserir_simbolo($3, $1, "variavel", lineno); }
    ;

/* ----------------------------------------------------------
 * DECLARACAO DE FUNCAO
 * ---------------------------------------------------------- */
func_decl
    : type FUNC ID param_list BLOCO_INI stmt_list END_BLOCO
        { inserir_simbolo($3, $1, "funcao", lineno); }
    | type FUNC ID BLOCO_INI stmt_list END_BLOCO
        { inserir_simbolo($3, $1, "funcao", lineno); }
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
    | switch_stmt
    | return_stmt
    | break_stmt
    | continue_stmt
    | read_list_stmt
    | write_list_stmt
    | print_stmt
    | read_stmt
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
 * SWITCH / CASE
 * ---------------------------------------------------------- */
switch_stmt
    : SWITCH ID BLOCO_INI case_list END_BLOCO
    ;

case_list
    : case_list case_stmt
    | case_stmt
    ;

case_stmt
    : CASE operando BLOCO_INI stmt_list END_BLOCO
    ;

/* ----------------------------------------------------------
 * RETURN / BREAK / CONTINUE / PRINT / READ
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

print_stmt
    : PRINT operando FIM_LINHA
    ;

read_stmt
    : READ ID FIM_LINHA
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
