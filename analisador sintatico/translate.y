%{
/*
 * Soundy Script -- Analisador Sintatico (Trabalho Pratico 2)
 *
 * NOTACAO DE TRES ENDERECOS:
 * OP dest src1 src2 B C  →  dest = src1 OP src2
 *
 * ATRIBUICAO (RISC-style):
 * C/E dest 0 src B C     →  dest = 0 + src
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tabela_simbolos.h"

extern int lineno;
int  yylex(void);
void yyerror(const char *msg);

%}

%union {
    int    ival;
    double fval;
    char   sval[256];
}

%token FIM_LINHA

/* Tipos */
%token <sval> TIPO

/* Declaracoes */
%token VAR
%token FUNC

/* Controle de fluxo */
%token IF
%token ELSE
%token WHILE
%token KW_RETURN
%token KW_BREAK
%token KW_CONTINUE

/* Delimitadores de bloco */
%token BLOCO_INI
%token END_BLOCO

/* Operacoes de lista */
%token READ_LIST
%token WRITE_LIST

/* Operadores aritmeticos */
%token OP_ADD
%token OP_SUB
%token OP_MUL
%token OP_DIV

/* Operadores logicos e relacionais */
%token OP_AND
%token OP_OR
%token OP_NOT
%token OP_EQ
%token OP_NEQ
%token OP_GT
%token OP_LT
%token OP_GTE
%token OP_LTE

/* Literais e Identificadores */
%token <ival> LIT_INT
%token <fval> LIT_FLOAT
%token <sval> LIT_CHAR
%token <sval> LIT_STRING
%token <ival> LIT_BOOL
%token <sval> ID
%token <sval> ACORDE_LIVRE

%type <sval> type

%%

program
    : decl_list
    |
    ;

decl_list
    : decl_list decl
    | decl
    ;

decl
    : func_decl
    | stmt
    ;

type
    : TIPO { strcpy($$, $1); }
    ;

var_decl
    : type VAR ID END_BLOCO
        { inserir_simbolo($3, $1, "variavel", lineno); }
    | type VAR ID END_BLOCO operando FIM_LINHA
        { inserir_simbolo($3, $1, "variavel", lineno); }
    ;

func_decl
    : type FUNC ID param_list BLOCO_INI stmt_list END_BLOCO
        { inserir_simbolo($3, $1, "funcao", lineno); }
    | type FUNC ID BLOCO_INI stmt_list END_BLOCO
        { inserir_simbolo($3, $1, "funcao", lineno); }
    ;

param_list
    : param_list param
    | param
    ;

param
    : TIPO ID
    ;

stmt_list
    : stmt_list stmt
    |
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

operando
    : ID
    | LIT_INT
    | LIT_FLOAT
    | LIT_CHAR
    | LIT_STRING
    | LIT_BOOL
    | ACORDE_LIVRE
    ;

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

op_unario
    : OP_NOT ID operando FIM_LINHA
    ;

if_stmt
    : IF BLOCO_INI ID FIM_LINHA stmt_list END_BLOCO
    | IF BLOCO_INI ID FIM_LINHA stmt_list END_BLOCO ELSE BLOCO_INI stmt_list END_BLOCO
    ;

while_stmt
    : WHILE BLOCO_INI ID FIM_LINHA stmt_list END_BLOCO
    ;

return_stmt
    : KW_RETURN operando FIM_LINHA
    ;

break_stmt
    : KW_BREAK FIM_LINHA
    ;

continue_stmt
    : KW_CONTINUE FIM_LINHA
    ;

func_call_stmt
    : ID operando_list FIM_LINHA
    ;

operando_list
    : operando_list operando
    |
    ;

read_list_stmt
    : READ_LIST ID ID operando FIM_LINHA
    ;

write_list_stmt
    : WRITE_LIST ID operando operando FIM_LINHA
    ;

%%