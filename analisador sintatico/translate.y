%{
/*
 * Soundy Script -- Analisador Sintatico (Trabalho Pratico 2)
 * Topico 3: Gramatica e Analisador Sintatico
 *
 * NOTACAO DE TRES ENDERECOS (Secao 4 da especificacao):
 *   OP dest src1 src2 B C  →  dest = src1 OP src2
 *
 * ORDEM DA DECLARACAO DE VARIAVEL (Secao 6):
 *   TIPO Dm/A id Cm           →  sem valor inicial
 *   TIPO Dm/A id Cm val B C   →  com valor inicial
 *
 * CONDICIONAL/REPETICAO (Secao 5):
 *   A condicao e a primeira linha DENTRO do bloco (nota guia):
 *   F C
 *       cond B C     ← nota guia
 *       comandos
 *   Cm
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
%token MOVE           /* D/F#  — atribuicao simples (Move) */

/* Controle de fluxo */
%token IF             /* F     */
%token ELSE           /* Em    */
%token WHILE          /* Bm    */
%token SWITCH         /* E     */
%token CASE           /* A     */
%token KW_RETURN      /* Am    */
%token KW_BREAK       /* G#dim */
%token KW_CONTINUE    /* A7    */

/* Delimitadores de bloco
 * IMPORTANTE: END_BLOCO (Cm) tem dupla funcao na linguagem:
 *   1. Termina blocos if/while/func:  F C ... Cm
 *   2. Termina nomes em declaracoes:  C/G Dm/A x Cm  */
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

/*
 * SEM %left/%right:
 * Na notacao de tres enderecos nao existem expressoes aninhadas,
 * portanto nao ha ambiguidade de precedencia para resolver.
 */

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
 * DECLARACAO DE VARIAVEL (Secao 6 — gramatica corrigida)
 *
 * TIPO Dm/A id Cm              →  sem valor inicial
 * TIPO Dm/A id Cm operando BC  →  com valor inicial
 *
 * Exemplos:
 *   C/G Dm/A x Cm              →  int x
 *   C/G Dm/A x Cm 10 B C       →  int x = 10
 *
 * Nota: 'Cm' (END_BLOCO) aqui e terminador de nome,
 *       nao fechamento de bloco.
 * ---------------------------------------------------------- */
var_decl
    : type VAR ID END_BLOCO
        { inserir_simbolo($3, $1, "variavel", lineno); }
    | type VAR ID END_BLOCO operando FIM_LINHA
        { inserir_simbolo($3, $1, "variavel", lineno); }
    ;

/* ----------------------------------------------------------
 * DECLARACAO DE FUNCAO (Secao 4.3)
 *
 * TIPO Bm/F# id [params] C corpo Cm
 *
 * Exemplos:
 *   C/G Bm/F# dobro C/G x C      →  int dobro(int x) { ... }
 *       corpo
 *   Cm
 *
 *   C/G Bm/F# soma C/G a C/G b C →  int soma(int a, int b) { ... }
 *       corpo
 *   Cm
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
    | assign_stmt
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
 * ATRIBUICAO SIMPLES (Move)
 *
 * Sintaxe: D/F# dest src BC
 * Exemplo: D/F# idade 20 B C   →   idade = 20
 * ---------------------------------------------------------- */
assign_stmt
    : MOVE ID operando FIM_LINHA
    ;

/* ----------------------------------------------------------
 * OPERACOES BINARIAS DE TRES ENDERECOS
 *
 * Sintaxe: OP dest src1 src2 BC
 *
 * Exemplos (Secao 3):
 *   C/E   total valor1 valor2 B C   →  total  = valor1 + valor2
 *   Dm/F# saldo ganho  gasto  B C   →  saldo  = ganho  - gasto
 *   E/G   area  base   altura B C   →  area   = base   * altura
 *   F/A   media soma   qtd    B C   →  media  = soma   / qtd
 *   G/B   pode  tem    maior  B C   →  pode   = tem    && maior
 *   Am/C  aprov passou entregou B C →  aprov  = passou || entregou
 *   E7/G  maior idade  limite  B C  →  maior  = idade  >  limite
 *   G7/B  aprov nota   media   B C  →  aprov  = nota   >= media
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
 *
 * Sintaxe: Bm/D dest src BC
 * Exemplo: Bm/D bloqueado ativo B C  →  bloqueado = !ativo
 * ---------------------------------------------------------- */
op_unario
    : OP_NOT ID operando FIM_LINHA
    ;

/* ----------------------------------------------------------
 * IF / IF-ELSE (Secao 5.1 e 5.2)
 *
 * A condicao e a primeira linha DENTRO do bloco (nota guia).
 * Deve ser um ID (variavel booleana pre-calculada) + BC.
 *
 * Sintaxe:
 *   F C
 *       cond B C          ← nota guia
 *       [comandos]
 *   Cm
 *
 *   F C
 *       cond B C
 *       [comandos_verdadeiro]
 *   Cm Em C
 *       [comandos_falso]
 *   Cm
 *
 * Exemplo (if_else.sndy da documentacao):
 *   G7/B aprovado nota media B C
 *   F C
 *       aprovado B C
 *       D/F# situacao 1 B C
 *   Cm Em C
 *       D/F# situacao 0 B C
 *   Cm
 * ---------------------------------------------------------- */
if_stmt
    : IF BLOCO_INI ID FIM_LINHA stmt_list END_BLOCO
    | IF BLOCO_INI ID FIM_LINHA stmt_list END_BLOCO ELSE BLOCO_INI stmt_list END_BLOCO
    ;

/* ----------------------------------------------------------
 * WHILE (Secao 5.3)
 *
 * Mesma logica do IF: condicao e nota guia dentro do bloco.
 *
 * Sintaxe:
 *   Bm C
 *       cond B C          ← nota guia
 *       [comandos]
 *   Cm
 *
 * Exemplo (while.sndy da documentacao):
 *   F7/A continua contador limite B C
 *   Bm C
 *       continua B C
 *       C/E contador contador um B C
 *       F7/A continua contador limite B C
 *   Cm
 * ---------------------------------------------------------- */
while_stmt
    : WHILE BLOCO_INI ID FIM_LINHA stmt_list END_BLOCO
    ;

/* ----------------------------------------------------------
 * SWITCH / CASE (Secao 4.2)
 *
 * Sintaxe:
 *   E id C
 *       A operando C comandos Cm
 *       A operando C comandos Cm
 *   Cm
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
 * RETURN / BREAK / CONTINUE
 * ---------------------------------------------------------- */
return_stmt
    : KW_RETURN ID FIM_LINHA
    ;

break_stmt
    : KW_BREAK FIM_LINHA
    ;

continue_stmt
    : KW_CONTINUE FIM_LINHA
    ;

/* ----------------------------------------------------------
 * OPERACOES DE LISTA (Secao 4.2)
 *
 * ReadList:  C7maj dest lista idx BC  →  dest = lista[idx]
 * WriteList: Cm7 lista idx valor BC   →  lista[idx] = valor
 * ---------------------------------------------------------- */
read_list_stmt
    : READ_LIST ID ID operando FIM_LINHA
    ;

write_list_stmt
    : WRITE_LIST ID operando operando FIM_LINHA
    ;

%%
