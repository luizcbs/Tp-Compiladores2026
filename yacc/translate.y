%{
/*
 * Soundy Script -- Analisador Sintatico + Geração de Código Intermediário (TP3)
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "TabelaSimbolo.h"
#include "gci.h"

extern int yylineno;
int  yylex(void);
void yyerror(const char *msg);
static void inserir_simbolo(const char *nome, const char *tipo,
                            const char *categoria, int linha,
                            int tamanhoLista);
static Tipo tipo_de_texto(const char *tipo);
static Categoria categoria_de_texto(const char *categoria);

extern TabelaSimbolo *global;
extern TabelaSimbolo *tabelaAtual;

%}

%union {
    int    ival;
    double fval;
    char   sval[256];
}

%token FIM_LINHA
%token <sval> TIPO
%token <sval> KW_LISTA
%token VAR FUNC CALL
%token IF ELSE WHILE
%token KW_RETURN KW_BREAK KW_CONTINUE
%token BLOCO_INI END_BLOCO
%token READ_LIST WRITE_LIST
%token OP_ADD OP_SUB OP_MUL OP_DIV
%token OP_AND OP_OR OP_NOT
%token OP_EQ OP_NEQ OP_GT OP_LT OP_GTE OP_LTE
%token <ival> LIT_INT
%token <fval> LIT_FLOAT
%token <ival> LIT_BOOL
%token LIT_NULL
%token <sval> ID
%token <sval> ACORDE_LIVRE

%type <sval> operando

%nonassoc ID LIT_INT LIT_FLOAT LIT_BOOL ACORDE_LIVRE

%%

program
    : decl_list
    | /* vazio */
    ;

decl_list
    : decl_list decl
    | decl
    ;

decl
    : func_decl
    | stmt
    ;

var_decl
    : TIPO VAR ID END_BLOCO FIM_LINHA
        { inserir_simbolo($3, $1, "variavel", yylineno, 0); }
    | TIPO VAR ID END_BLOCO operando FIM_LINHA
        { inserir_simbolo($3, $1, "variavel", yylineno, 0); }
    | KW_LISTA VAR ID END_BLOCO LIT_INT FIM_LINHA
        { inserir_simbolo($3, $1, "variavel", yylineno, $5); }
    ;

func_decl
    : TIPO FUNC ID param_list BLOCO_INI stmt_list END_BLOCO
        { inserir_simbolo($3, $1, "funcao", yylineno, 0); }
    | TIPO FUNC ID BLOCO_INI stmt_list END_BLOCO
        { inserir_simbolo($3, $1, "funcao", yylineno, 0); }
    ;

param_list
    : param_list param
    | param
    ;

param
    : TIPO ID
        { inserir_simbolo($2, $1, "parametro", yylineno, 0); }
    ;

stmt_list
    : stmt_list stmt
    | /* vazio */
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
    : ID           { strcpy($$, $1); }
    | LIT_INT      { sprintf($$, "%d",   $1); }
    | LIT_FLOAT    { sprintf($$, "%.6g", $1); }
    | LIT_BOOL     { sprintf($$, "%d",   $1); }
    | LIT_NULL     { strcpy($$, "null"); }
    | ACORDE_LIVRE { strcpy($$, $1); }
    ;

op_binario
    : OP_ADD ID operando operando FIM_LINHA { gci_emitir_operacao_otimizada("ADD", $2, $3, $4); }
    | OP_SUB ID operando operando FIM_LINHA { gci_emitir_operacao_otimizada("SUB", $2, $3, $4); }
    | OP_MUL ID operando operando FIM_LINHA { gci_emitir_operacao_otimizada("MUL", $2, $3, $4); }
    | OP_DIV ID operando operando FIM_LINHA { gci_emitir_operacao_otimizada("DIV", $2, $3, $4); }
    | OP_AND ID operando operando FIM_LINHA { gci_emitir_operacao_otimizada("AND", $2, $3, $4); }
    | OP_OR  ID operando operando FIM_LINHA { gci_emitir_operacao_otimizada("OR",  $2, $3, $4); }
    | OP_EQ  ID operando operando FIM_LINHA { gci_emitir_operacao_otimizada("SEQ", $2, $3, $4); }
    | OP_NEQ ID operando operando FIM_LINHA { gci_emitir_operacao_otimizada("SNE", $2, $3, $4); }
    | OP_GT  ID operando operando FIM_LINHA { gci_emitir_operacao_otimizada("SGT", $2, $3, $4); }
    | OP_LT  ID operando operando FIM_LINHA { gci_emitir_operacao_otimizada("SLT", $2, $3, $4); }
    | OP_GTE ID operando operando FIM_LINHA { gci_emitir_operacao_otimizada("SGE", $2, $3, $4); }
    | OP_LTE ID operando operando FIM_LINHA { gci_emitir_operacao_otimizada("SLE", $2, $3, $4); }
    ;

op_unario
    : OP_NOT ID operando FIM_LINHA
        { gci_emitir_unario("NOT", $2, $3); }
    ;

/* Regra intermediária para o prefixo do if — elimina o conflito
   reduce/reduce que surgia ao ter dois blocos IF separados */
if_prefix
    : IF BLOCO_INI ID FIM_LINHA
        {
            char* lf = gci_nova_label();
            gci_push_if_label(lf);
            gci_emitir_jump_condicional($3, lf);
            free(lf);
        }
    ;

if_stmt
    : if_prefix stmt_list END_BLOCO
        {
            char* lf = gci_pop_if_label();
            gci_emitir_label(lf);
            free(lf);
        }

    | if_prefix stmt_list END_BLOCO ELSE BLOCO_INI
        {
            char* lfim = gci_nova_label();
            gci_emitir_jump(lfim);
            char* lf = gci_pop_if_label();
            gci_emitir_label(lf);
            free(lf);
            gci_push_if_label(lfim);
            free(lfim);
        }
      stmt_list END_BLOCO
        {
            char* lfim = gci_pop_if_label();
            gci_emitir_label(lfim);
            free(lfim);
        }
    ;

while_prefix
    : WHILE BLOCO_INI
        {
            char* ini = gci_nova_label();
            char* fim = gci_nova_label();
            gci_push_while(ini, fim);
            gci_emitir_label(ini);
        }
    ;

while_stmt
    : while_prefix ID FIM_LINHA
        {
            gci_emitir_jump_condicional($2, gci_get_while_fim());
        }
      stmt_list END_BLOCO
        {
            gci_emitir_jump(gci_get_while_inicio());
            gci_emitir_label(gci_get_while_fim());
            gci_pop_while();
        }
    ;

return_stmt
    : KW_RETURN operando FIM_LINHA
        { gci_emitir_return($2); }
    ;

break_stmt
    : KW_BREAK FIM_LINHA
        { gci_emitir_jump(gci_get_while_fim()); }
    ;

continue_stmt
    : KW_CONTINUE FIM_LINHA
        { gci_emitir_jump(gci_get_while_inicio()); }
    ;

func_call_stmt
    : CALL ID ID operando_list FIM_LINHA
        { gci_emitir_call($2, $3); }
    ;

operando_list
    : operando_list operando
    | /* vazio */
    ;

read_list_stmt
    : READ_LIST ID ID operando FIM_LINHA
        { gci_emitir_read_list($2, $3, $4); }
    ;

write_list_stmt
    : WRITE_LIST ID operando operando FIM_LINHA
        { gci_emitir_write_list($2, $3, $4); }
    ;

%%

static Tipo tipo_de_texto(const char *tipo)
{
    if (strcmp(tipo, "int")   == 0 || strcmp(tipo, "C/G")  == 0) return TIPO_INT;
    if (strcmp(tipo, "float") == 0 || strcmp(tipo, "Am/E") == 0) return TIPO_FLOAT;
    if (strcmp(tipo, "bool")  == 0 || strcmp(tipo, "Em/B") == 0) return TIPO_BOOL;
    if (strcmp(tipo, "lista") == 0 || strcmp(tipo, "C7")   == 0) return TIPO_LISTA;
    return TIPO_INVALIDO;
}

static Categoria categoria_de_texto(const char *categoria)
{
    if (strcmp(categoria, "funcao")    == 0) return CAT_FUNCAO;
    if (strcmp(categoria, "parametro") == 0) return CAT_PARAMETRO;
    return CAT_VARIAVEL;
}

static void inserir_simbolo(const char *nome, const char *tipo,
                            const char *categoria, int linha,
                            int tamanhoLista)
{
    if (tabelaAtual == NULL) return;
    inserirSimbolo(
        tabelaAtual,
        criarSimbolo(
            (char *)nome,
            tipo_de_texto(tipo),
            categoria_de_texto(categoria),
            linha,
            tamanhoLista
        )
    );
}

void yyerror(const char *msg)
{
    (void)msg;
    printf("Erro próximo a linha %d - Programa sintaticamente incorreto\n",
           yylineno);
}
