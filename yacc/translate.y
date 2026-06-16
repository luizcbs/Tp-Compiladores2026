%{
/* Analisador Sintatico e GCI - Soundy Script (TP3) */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "TabelaSimbolo.h"
#include "gci.h"

extern int yylineno;
int  yylex(void);
void yyerror(const char *msg);

/* Funcoes auxiliares */
static void inserir_simbolo(const char *nome, const char *tipo, const char *categoria, int linha);
static Tipo tipo_de_texto(const char *tipo);
static Categoria categoria_de_texto(const char *categoria);

extern TabelaSimbolo *global;
extern TabelaSimbolo *tabelaAtual;
%}

/* --- Definicao de Tipos --- */
%union {
    int    ival;
    double fval;
    char   sval[256];
}

/* --- Tokens --- */
%token FIM_LINHA
%token <sval> TIPO

/* Palavras-chave */
%token VAR FUNC
%token IF ELSE WHILE
%token KW_RETURN KW_BREAK KW_CONTINUE

/* Blocos */
%token BLOCO_INI END_BLOCO

/* Listas */
%token READ_LIST WRITE_LIST

/* Operadores Aritmeticos */
%token OP_ADD OP_SUB OP_MUL OP_DIV

/* Operadores Logicos e Relacionais */
%token OP_AND OP_OR OP_NOT
%token OP_EQ OP_NEQ OP_GT OP_LT OP_GTE OP_LTE

/* Literais e Identificadores */
%token <ival> LIT_INT
%token <fval> LIT_FLOAT
%token <sval> LIT_CHAR
%token <sval> LIT_STRING
%token <ival> LIT_BOOL
%token <sval> ID
%token <sval> ACORDE_LIVRE

/* Mapeamento para GCI e Tabela de Simbolos */
%type <sval> operando

/* Precedencias para evitar Shift/Reduce */
%nonassoc DECL_SEM_INICIALIZACAO
%nonassoc ID LIT_INT LIT_FLOAT LIT_CHAR LIT_STRING LIT_BOOL ACORDE_LIVRE

%%
/* --- Regras de Producao --- */

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

/* Declaracao de variavel */
var_decl
    : TIPO VAR ID END_BLOCO %prec DECL_SEM_INICIALIZACAO
        { inserir_simbolo($3, $1, "variavel", yylineno); }
    | TIPO VAR ID END_BLOCO operando FIM_LINHA
        { inserir_simbolo($3, $1, "variavel", yylineno); }
    ;

/* Declaracao de funcao */
func_decl
    : TIPO FUNC ID param_list BLOCO_INI stmt_list END_BLOCO
        { inserir_simbolo($3, $1, "funcao", yylineno); }
    | TIPO FUNC ID BLOCO_INI stmt_list END_BLOCO
        { inserir_simbolo($3, $1, "funcao", yylineno); }
    ;

param_list
    : param_list param
    | param
    ;

param
    : TIPO ID
        { inserir_simbolo($2, $1, "parametro", yylineno); }
    ;

/* Comandos */
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

/* Tratamento de Operandos (Convertendo para string para o GCI) */
operando
    : ID           { strcpy($$, $1); }
    | LIT_INT      { sprintf($$, "%d", $1); }
    | LIT_FLOAT    { sprintf($$, "%.2f", $1); }
    | LIT_CHAR     { strcpy($$, $1); }
    | LIT_STRING   { strcpy($$, $1); }
    | LIT_BOOL     { sprintf($$, "%d", $1); }
    | ACORDE_LIVRE { strcpy($$, $1); }
    ;

/* --- Operacoes (Injetando Código de 3 Enderecos) --- */
op_binario
    : OP_ADD ID operando operando FIM_LINHA { gci_emitir_operacao("ADD", $2, $3, $4); }
    | OP_SUB ID operando operando FIM_LINHA { gci_emitir_operacao("SUB", $2, $3, $4); }
    | OP_MUL ID operando operando FIM_LINHA { gci_emitir_operacao("MUL", $2, $3, $4); }
    | OP_DIV ID operando operando FIM_LINHA { gci_emitir_operacao("DIV", $2, $3, $4); }
    | OP_AND ID operando operando FIM_LINHA { gci_emitir_operacao("AND", $2, $3, $4); }
    | OP_OR  ID operando operando FIM_LINHA { gci_emitir_operacao("OR",  $2, $3, $4); }
    | OP_EQ  ID operando operando FIM_LINHA { gci_emitir_operacao("SEQ", $2, $3, $4); }
    | OP_NEQ ID operando operando FIM_LINHA { gci_emitir_operacao("SNE", $2, $3, $4); }
    | OP_GT  ID operando operando FIM_LINHA { gci_emitir_operacao("SGT", $2, $3, $4); }
    | OP_LT  ID operando operando FIM_LINHA { gci_emitir_operacao("SLT", $2, $3, $4); }
    | OP_GTE ID operando operando FIM_LINHA { gci_emitir_operacao("SGE", $2, $3, $4); }
    | OP_LTE ID operando operando FIM_LINHA { gci_emitir_operacao("SLE", $2, $3, $4); }
    ;

op_unario
    : OP_NOT ID operando FIM_LINHA { gci_emitir_unario("NOT", $2, $3); }
    ;

/* --- Controle de Fluxo (Prefixos resolvem os conflitos do Yacc) --- */
if_prefix
    : IF BLOCO_INI ID FIM_LINHA 
        {
            strcpy($<sval>$, gci_nova_label());
            gci_emitir_jump_condicional($3, $<sval>$);
        }
    ;

if_stmt
    : if_prefix stmt_list END_BLOCO 
        {
            gci_emitir_label($<sval>1); 
        }
    | if_prefix stmt_list END_BLOCO ELSE BLOCO_INI 
        {
            strcpy($<sval>$, gci_nova_label()); 
            gci_emitir_jump($<sval>$);   
            gci_emitir_label($<sval>1);  
        }
      stmt_list END_BLOCO 
        {
            gci_emitir_label($<sval>6);
        }
    ;

while_prefix
    : WHILE BLOCO_INI 
        {
            char* inicio = gci_nova_label();
            char* fim = gci_nova_label();
            gci_push_while(inicio, fim);
            
            gci_emitir_label(inicio);
            strcpy($<sval>$, fim);
        }
    ;

while_stmt
    : while_prefix ID FIM_LINHA 
        {
            gci_emitir_jump_condicional($2, $<sval>1);
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
    ;

break_stmt
    : KW_BREAK FIM_LINHA 
        { gci_emitir_jump(gci_get_while_fim()); }
    ;

continue_stmt
    : KW_CONTINUE FIM_LINHA 
        { gci_emitir_jump(gci_get_while_inicio()); }
    ;

/* --- Chamadas de Funcao e Listas --- */
func_call_stmt
    : ID operando_list FIM_LINHA
        { gci_emitir_call("dest", $1); }
    ;

operando_list
    : operando_list operando
    |
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
/* --- Codigo C Auxiliar --- */

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