%{
/*
 * Soundy Script -- Analisador Sintatico + Analise Semantica + GCI
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "TabelaSimbolo.h"
#include "gci.h"

extern int yylineno;
extern TabelaSimbolo *tabelaAtual;
int  yylex(void);
void yyerror(const char *msg);

static void inserir_simbolo(const char *nome, const char *tipo,
                            const char *categoria, int linha,
                            int tamanhoLista);
static Tipo tipo_de_texto(const char *tipo);
static Categoria categoria_de_texto(const char *categoria);
static void erro_semantico(const char *msg, int linha);
static int tipo_numerico(Tipo tipo);
static int tipos_comparaveis(Tipo a, Tipo b);
static int literal_int_do_operando(char *texto, Tipo tipo, int *valor);

typedef struct {
    char nome[50];
    Tipo retorno;
    int num_params;
} AssinaturaFuncao;

static AssinaturaFuncao assinaturas[100];
static int num_assinaturas = 0;

static Tipo tipo_retorno_atual = TIPO_NULL;
static char nome_funcao_atual[50] = "";
static int contagem_params_atual = 0;
static int contagem_args_atual = 0;
static int profundidade_loop = 0;

static void registrar_assinatura(const char *nome, Tipo retorno, int params);
static AssinaturaFuncao *buscar_assinatura(const char *nome);
%}

%union {
    int          ival;
    double       fval;
    char         sval[256];
    struct {
        char texto[256];
        int tipo;
    } oval;
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

%type <oval> operando

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
        {
            Tipo tipo_decl = tipo_de_texto($1);
            if ($5.tipo != TIPO_INVALIDO &&
                $5.tipo != TIPO_NULL &&
                $5.tipo != tipo_decl)
            {
                char msg[256];
                snprintf(msg, sizeof(msg),
                         "variavel '%s': valor inicial incompativel com tipo declarado",
                         $3);
                erro_semantico(msg, yylineno);
            }
            inserir_simbolo($3, $1, "variavel", yylineno, 0);
        }
    | KW_LISTA VAR ID END_BLOCO LIT_INT FIM_LINHA
        {
            if ($5 <= 0)
            {
                char msg[256];
                snprintf(msg, sizeof(msg),
                         "lista '%s': tamanho deve ser maior que zero",
                         $3);
                erro_semantico(msg, yylineno);
            }
            inserir_simbolo($3, $1, "variavel", yylineno, $5);
        }
    ;

func_decl
    : func_header param_list BLOCO_INI stmt_list END_BLOCO
        {
            registrar_assinatura(nome_funcao_atual, tipo_retorno_atual,
                                 contagem_params_atual);
            sairTabelaSimbolo(&tabelaAtual);
            nome_funcao_atual[0] = '\0';
            tipo_retorno_atual = TIPO_NULL;
            contagem_params_atual = 0;
        }
    | func_header BLOCO_INI stmt_list END_BLOCO
        {
            registrar_assinatura(nome_funcao_atual, tipo_retorno_atual, 0);
            sairTabelaSimbolo(&tabelaAtual);
            nome_funcao_atual[0] = '\0';
            tipo_retorno_atual = TIPO_NULL;
            contagem_params_atual = 0;
        }
    ;

func_header
    : TIPO FUNC ID
        {
            inserir_simbolo($3, $1, "funcao", yylineno, 0);
            tipo_retorno_atual = tipo_de_texto($1);
            strncpy(nome_funcao_atual, $3, sizeof(nome_funcao_atual) - 1);
            nome_funcao_atual[sizeof(nome_funcao_atual) - 1] = '\0';
            contagem_params_atual = 0;

            TabelaSimbolo *filho = criarTabelaSimbolo($3, tabelaAtual);
            adicionarFilho(tabelaAtual, filho);
            entrarTabalaSimbolo(&tabelaAtual, filho);
        }
    ;

param_list
    : param_list param
    | param
    ;

param
    : TIPO ID
        {
            inserir_simbolo($2, $1, "parametro", yylineno, 0);
            contagem_params_atual++;
        }
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
    : ID
        {
            Simbolo *simbolo = buscarSimbolo(tabelaAtual, $1);
            strcpy($$.texto, $1);
            $$.tipo = (simbolo != NULL) ? simbolo->tipo : TIPO_INVALIDO;
        }
    | LIT_INT
        {
            sprintf($$.texto, "%d", $1);
            $$.tipo = TIPO_INT;
        }
    | LIT_FLOAT
        {
            sprintf($$.texto, "%.6g", $1);
            $$.tipo = TIPO_FLOAT;
        }
    | LIT_BOOL
        {
            sprintf($$.texto, "%d", $1);
            $$.tipo = TIPO_BOOL;
        }
    | LIT_NULL
        {
            strcpy($$.texto, "null");
            $$.tipo = TIPO_NULL;
        }
    | ACORDE_LIVRE
        {
            strcpy($$.texto, $1);
            $$.tipo = TIPO_INVALIDO;
        }
    ;

op_binario
    : OP_ADD ID operando operando FIM_LINHA
        {
            Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
            if (dest == NULL)
            {
                char msg[256];
                snprintf(msg, sizeof(msg), "ADD: destino '%s' nao declarado", $2);
                erro_semantico(msg, yylineno);
            }
            else if (dest->tipo != TIPO_LISTA && !tipo_numerico(dest->tipo) && dest->tipo != TIPO_BOOL)
            {
                char msg[256];
                snprintf(msg, sizeof(msg), "ADD: destino '%s' com tipo invalido", $2);
                erro_semantico(msg, yylineno);
            }
            gci_emitir_operacao_otimizada("ADD", $2, $3.texto, $4.texto);
        }
    | OP_SUB ID operando operando FIM_LINHA
        {
            Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
            if (dest == NULL)
            {
                char msg[256];
                snprintf(msg, sizeof(msg), "SUB: destino '%s' nao declarado", $2);
                erro_semantico(msg, yylineno);
            }
            if (($3.tipo != TIPO_INVALIDO && !tipo_numerico($3.tipo) && $3.tipo != TIPO_NULL) ||
                ($4.tipo != TIPO_INVALIDO && !tipo_numerico($4.tipo) && $4.tipo != TIPO_NULL))
            {
                erro_semantico("SUB: operandos devem ser numericos", yylineno);
            }
            gci_emitir_operacao_otimizada("SUB", $2, $3.texto, $4.texto);
        }
    | OP_MUL ID operando operando FIM_LINHA
        {
            Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
            if (dest == NULL)
            {
                char msg[256];
                snprintf(msg, sizeof(msg), "MUL: destino '%s' nao declarado", $2);
                erro_semantico(msg, yylineno);
            }
            if (($3.tipo != TIPO_INVALIDO && !tipo_numerico($3.tipo) && $3.tipo != TIPO_NULL) ||
                ($4.tipo != TIPO_INVALIDO && !tipo_numerico($4.tipo) && $4.tipo != TIPO_NULL))
            {
                erro_semantico("MUL: operandos devem ser numericos", yylineno);
            }
            gci_emitir_operacao_otimizada("MUL", $2, $3.texto, $4.texto);
        }
    | OP_DIV ID operando operando FIM_LINHA
        {
            Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
            if (dest == NULL)
            {
                char msg[256];
                snprintf(msg, sizeof(msg), "DIV: destino '%s' nao declarado", $2);
                erro_semantico(msg, yylineno);
            }
            if (($3.tipo != TIPO_INVALIDO && !tipo_numerico($3.tipo) && $3.tipo != TIPO_NULL) ||
                ($4.tipo != TIPO_INVALIDO && !tipo_numerico($4.tipo) && $4.tipo != TIPO_NULL))
            {
                erro_semantico("DIV: operandos devem ser numericos", yylineno);
            }
            gci_emitir_operacao_otimizada("DIV", $2, $3.texto, $4.texto);
        }
    | OP_AND ID operando operando FIM_LINHA
        {
            Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
            if (dest == NULL)
            {
                char msg[256];
                snprintf(msg, sizeof(msg), "AND: destino '%s' nao declarado", $2);
                erro_semantico(msg, yylineno);
            }
            else if (dest->tipo != TIPO_BOOL)
            {
                erro_semantico("AND: destino deve ser bool", yylineno);
            }
            if (($3.tipo != TIPO_INVALIDO && $3.tipo != TIPO_BOOL) ||
                ($4.tipo != TIPO_INVALIDO && $4.tipo != TIPO_BOOL))
            {
                erro_semantico("AND: operandos devem ser bool", yylineno);
            }
            gci_emitir_operacao_otimizada("AND", $2, $3.texto, $4.texto);
        }
    | OP_OR ID operando operando FIM_LINHA
        {
            Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
            if (dest == NULL)
            {
                char msg[256];
                snprintf(msg, sizeof(msg), "OR: destino '%s' nao declarado", $2);
                erro_semantico(msg, yylineno);
            }
            else if (dest->tipo != TIPO_BOOL)
            {
                erro_semantico("OR: destino deve ser bool", yylineno);
            }
            if (($3.tipo != TIPO_INVALIDO && $3.tipo != TIPO_BOOL) ||
                ($4.tipo != TIPO_INVALIDO && $4.tipo != TIPO_BOOL))
            {
                erro_semantico("OR: operandos devem ser bool", yylineno);
            }
            gci_emitir_operacao_otimizada("OR", $2, $3.texto, $4.texto);
        }
    | OP_EQ ID operando operando FIM_LINHA
        {
            Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
            if (dest == NULL)
            {
                char msg[256];
                snprintf(msg, sizeof(msg), "SEQ: destino '%s' nao declarado", $2);
                erro_semantico(msg, yylineno);
            }
            else if (dest->tipo != TIPO_BOOL)
            {
                erro_semantico("SEQ: destino deve ser bool", yylineno);
            }
            if ($3.tipo != TIPO_INVALIDO && $4.tipo != TIPO_INVALIDO &&
                !tipos_comparaveis($3.tipo, $4.tipo))
            {
                erro_semantico("SEQ: operandos incompativeis para comparacao", yylineno);
            }
            gci_emitir_operacao_otimizada("SEQ", $2, $3.texto, $4.texto);
        }
    | OP_NEQ ID operando operando FIM_LINHA
        {
            Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
            if (dest == NULL)
            {
                char msg[256];
                snprintf(msg, sizeof(msg), "SNE: destino '%s' nao declarado", $2);
                erro_semantico(msg, yylineno);
            }
            else if (dest->tipo != TIPO_BOOL)
            {
                erro_semantico("SNE: destino deve ser bool", yylineno);
            }
            if ($3.tipo != TIPO_INVALIDO && $4.tipo != TIPO_INVALIDO &&
                !tipos_comparaveis($3.tipo, $4.tipo))
            {
                erro_semantico("SNE: operandos incompativeis para comparacao", yylineno);
            }
            gci_emitir_operacao_otimizada("SNE", $2, $3.texto, $4.texto);
        }
    | OP_GT ID operando operando FIM_LINHA
        {
            if (($3.tipo != TIPO_INVALIDO && !tipo_numerico($3.tipo)) ||
                ($4.tipo != TIPO_INVALIDO && !tipo_numerico($4.tipo)))
            {
                erro_semantico("SGT: operandos devem ser numericos", yylineno);
            }
            gci_emitir_operacao_otimizada("SGT", $2, $3.texto, $4.texto);
        }
    | OP_LT ID operando operando FIM_LINHA
        {
            if (($3.tipo != TIPO_INVALIDO && !tipo_numerico($3.tipo)) ||
                ($4.tipo != TIPO_INVALIDO && !tipo_numerico($4.tipo)))
            {
                erro_semantico("SLT: operandos devem ser numericos", yylineno);
            }
            gci_emitir_operacao_otimizada("SLT", $2, $3.texto, $4.texto);
        }
    | OP_GTE ID operando operando FIM_LINHA
        {
            if (($3.tipo != TIPO_INVALIDO && !tipo_numerico($3.tipo)) ||
                ($4.tipo != TIPO_INVALIDO && !tipo_numerico($4.tipo)))
            {
                erro_semantico("SGE: operandos devem ser numericos", yylineno);
            }
            gci_emitir_operacao_otimizada("SGE", $2, $3.texto, $4.texto);
        }
    | OP_LTE ID operando operando FIM_LINHA
        {
            if (($3.tipo != TIPO_INVALIDO && !tipo_numerico($3.tipo)) ||
                ($4.tipo != TIPO_INVALIDO && !tipo_numerico($4.tipo)))
            {
                erro_semantico("SLE: operandos devem ser numericos", yylineno);
            }
            gci_emitir_operacao_otimizada("SLE", $2, $3.texto, $4.texto);
        }
    ;

op_unario
    : OP_NOT ID operando FIM_LINHA
        {
            Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
            if (dest == NULL)
            {
                char msg[256];
                snprintf(msg, sizeof(msg), "NOT: destino '%s' nao declarado", $2);
                erro_semantico(msg, yylineno);
            }
            else if (dest->tipo != TIPO_BOOL)
            {
                erro_semantico("NOT: destino deve ser bool", yylineno);
            }
            if ($3.tipo != TIPO_INVALIDO && $3.tipo != TIPO_BOOL)
            {
                erro_semantico("NOT: operando deve ser bool", yylineno);
            }
            gci_emitir_unario("NOT", $2, $3.texto);
        }
    ;

if_prefix
    : IF BLOCO_INI ID FIM_LINHA
        {
            Simbolo *cond = buscarSimbolo(tabelaAtual, $3);
            if (cond == NULL)
            {
                char msg[256];
                snprintf(msg, sizeof(msg), "IF: nota guia '%s' nao declarada", $3);
                erro_semantico(msg, yylineno);
            }
            else if (cond->tipo != TIPO_BOOL)
            {
                char msg[256];
                snprintf(msg, sizeof(msg),
                         "IF: nota guia '%s' deve ser bool, mas e %s",
                         $3, tipoParaString(cond->tipo));
                erro_semantico(msg, yylineno);
            }

            char *lf = gci_nova_label();
            gci_push_if_label(lf);
            gci_emitir_jump_condicional($3, lf);
            free(lf);
        }
    ;

if_stmt
    : if_prefix stmt_list END_BLOCO
        {
            char *lf = gci_pop_if_label();
            gci_emitir_label(lf);
            free(lf);
        }
    | if_prefix stmt_list END_BLOCO ELSE BLOCO_INI
        {
            char *lfim = gci_nova_label();
            gci_emitir_jump(lfim);
            char *lf = gci_pop_if_label();
            gci_emitir_label(lf);
            free(lf);
            gci_push_if_label(lfim);
            free(lfim);
        }
      stmt_list END_BLOCO
        {
            char *lfim = gci_pop_if_label();
            gci_emitir_label(lfim);
            free(lfim);
        }
    ;

while_prefix
    : WHILE BLOCO_INI
        {
            char *ini = gci_nova_label();
            char *fim = gci_nova_label();
            gci_push_while(ini, fim);
            gci_emitir_label(ini);
            profundidade_loop++;
        }
    ;

while_stmt
    : while_prefix ID FIM_LINHA
        {
            Simbolo *cond = buscarSimbolo(tabelaAtual, $2);
            if (cond == NULL)
            {
                char msg[256];
                snprintf(msg, sizeof(msg), "WHILE: nota guia '%s' nao declarada", $2);
                erro_semantico(msg, yylineno);
            }
            else if (cond->tipo != TIPO_BOOL)
            {
                char msg[256];
                snprintf(msg, sizeof(msg),
                         "WHILE: nota guia '%s' deve ser bool, mas e %s",
                         $2, tipoParaString(cond->tipo));
                erro_semantico(msg, yylineno);
            }
            gci_emitir_jump_condicional($2, gci_get_while_fim());
        }
      stmt_list END_BLOCO
        {
            gci_emitir_jump(gci_get_while_inicio());
            gci_emitir_label(gci_get_while_fim());
            gci_pop_while();
            if (profundidade_loop > 0) profundidade_loop--;
        }
    ;

return_stmt
    : KW_RETURN operando FIM_LINHA
        {
            if (nome_funcao_atual[0] == '\0')
            {
                erro_semantico("return usado fora de uma funcao", yylineno);
            }
            else if ($2.tipo != TIPO_INVALIDO &&
                     $2.tipo != TIPO_NULL &&
                     $2.tipo != tipo_retorno_atual)
            {
                char msg[256];
                snprintf(msg, sizeof(msg),
                         "return em '%s': tipo %s incompativel com retorno declarado %s",
                         nome_funcao_atual,
                         tipoParaString($2.tipo),
                         tipoParaString(tipo_retorno_atual));
                erro_semantico(msg, yylineno);
            }
            gci_emitir_return($2.texto);
        }
    ;

break_stmt
    : KW_BREAK FIM_LINHA
        {
            if (profundidade_loop <= 0)
                erro_semantico("break usado fora de while", yylineno);
            gci_emitir_jump(gci_get_while_fim());
        }
    ;

continue_stmt
    : KW_CONTINUE FIM_LINHA
        {
            if (profundidade_loop <= 0)
                erro_semantico("continue usado fora de while", yylineno);
            gci_emitir_jump(gci_get_while_inicio());
        }
    ;

func_call_stmt
    : CALL ID ID { contagem_args_atual = 0; } operando_list FIM_LINHA
        {
            Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
            AssinaturaFuncao *sig = buscar_assinatura($3);

            if (dest == NULL)
            {
                char msg[256];
                snprintf(msg, sizeof(msg), "CALL: destino '%s' nao declarado", $2);
                erro_semantico(msg, yylineno);
            }
            if (sig == NULL)
            {
                char msg[256];
                snprintf(msg, sizeof(msg), "CALL: funcao '%s' nao declarada", $3);
                erro_semantico(msg, yylineno);
            }
            else
            {
                if (contagem_args_atual != sig->num_params)
                {
                    char msg[256];
                    snprintf(msg, sizeof(msg),
                             "CALL '%s': esperava %d argumento(s), recebeu %d",
                             $3, sig->num_params, contagem_args_atual);
                    erro_semantico(msg, yylineno);
                }
                if (dest != NULL && dest->tipo != sig->retorno)
                {
                    char msg[256];
                    snprintf(msg, sizeof(msg),
                             "CALL '%s': retorno %s incompativel com destino '%s' (%s)",
                             $3, tipoParaString(sig->retorno), $2,
                             tipoParaString(dest->tipo));
                    erro_semantico(msg, yylineno);
                }
            }

            gci_emitir_call($2, $3);
        }
    ;

operando_list
    : operando_list operando
        { contagem_args_atual++; }
    | /* vazio */
    ;

read_list_stmt
    : READ_LIST ID ID operando FIM_LINHA
        {
            Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
            Simbolo *lista = buscarSimbolo(tabelaAtual, $3);

            if (dest == NULL)
            {
                char msg[256];
                snprintf(msg, sizeof(msg), "ReadList: destino '%s' nao declarado", $2);
                erro_semantico(msg, yylineno);
            }
            if (lista == NULL)
            {
                char msg[256];
                snprintf(msg, sizeof(msg), "ReadList: '%s' nao declarado", $3);
                erro_semantico(msg, yylineno);
            }
            else if (lista->tipo != TIPO_LISTA)
            {
                char msg[256];
                snprintf(msg, sizeof(msg), "ReadList: '%s' nao e lista", $3);
                erro_semantico(msg, yylineno);
            }
            if ($4.tipo != TIPO_INVALIDO && $4.tipo != TIPO_INT)
            {
                erro_semantico("ReadList: indice deve ser int", yylineno);
            }

            if (lista != NULL)
            {
                int indice;
                if (literal_int_do_operando($4.texto, $4.tipo, &indice) &&
                    lista->tamanhoLista > 0 &&
                    (indice < 0 || indice >= lista->tamanhoLista))
                {
                    char msg[256];
                    snprintf(msg, sizeof(msg),
                             "ReadList: indice %d fora dos limites de '%s' (tamanho %d)",
                             indice, $3, lista->tamanhoLista);
                    erro_semantico(msg, yylineno);
                }
            }

            gci_emitir_read_list($2, $3, $4.texto);
        }
    ;

write_list_stmt
    : WRITE_LIST ID operando operando FIM_LINHA
        {
            Simbolo *lista = buscarSimbolo(tabelaAtual, $2);

            if (lista == NULL)
            {
                char msg[256];
                snprintf(msg, sizeof(msg), "WriteList: '%s' nao declarado", $2);
                erro_semantico(msg, yylineno);
            }
            else if (lista->tipo != TIPO_LISTA)
            {
                char msg[256];
                snprintf(msg, sizeof(msg), "WriteList: '%s' nao e lista", $2);
                erro_semantico(msg, yylineno);
            }
            if ($3.tipo != TIPO_INVALIDO && $3.tipo != TIPO_INT)
            {
                erro_semantico("WriteList: indice deve ser int", yylineno);
            }

            if (lista != NULL)
            {
                int indice;
                if (literal_int_do_operando($3.texto, $3.tipo, &indice) &&
                    lista->tamanhoLista > 0 &&
                    (indice < 0 || indice >= lista->tamanhoLista))
                {
                    char msg[256];
                    snprintf(msg, sizeof(msg),
                             "WriteList: indice %d fora dos limites de '%s' (tamanho %d)",
                             indice, $2, lista->tamanhoLista);
                    erro_semantico(msg, yylineno);
                }
            }

            gci_emitir_write_list($2, $3.texto, $4.texto);
        }
    ;

%%

static void erro_semantico(const char *msg, int linha)
{
    fprintf(stderr, "Erro semantico na linha %d: %s\n", linha, msg);
}

static Tipo tipo_de_texto(const char *tipo)
{
    if (strcmp(tipo, "int") == 0 || strcmp(tipo, "C/G") == 0) return TIPO_INT;
    if (strcmp(tipo, "float") == 0 || strcmp(tipo, "Am/E") == 0) return TIPO_FLOAT;
    if (strcmp(tipo, "bool") == 0 || strcmp(tipo, "Em/B") == 0) return TIPO_BOOL;
    if (strcmp(tipo, "lista") == 0 || strcmp(tipo, "C7") == 0) return TIPO_LISTA;
    if (strcmp(tipo, "null") == 0 || strcmp(tipo, "G/D") == 0) return TIPO_NULL;
    return TIPO_INVALIDO;
}

static Categoria categoria_de_texto(const char *categoria)
{
    if (strcmp(categoria, "funcao") == 0) return CAT_FUNCAO;
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

static void registrar_assinatura(const char *nome, Tipo retorno, int params)
{
    if (num_assinaturas >= 100) return;
    strncpy(assinaturas[num_assinaturas].nome, nome, 49);
    assinaturas[num_assinaturas].nome[49] = '\0';
    assinaturas[num_assinaturas].retorno = retorno;
    assinaturas[num_assinaturas].num_params = params;
    num_assinaturas++;
}

static AssinaturaFuncao *buscar_assinatura(const char *nome)
{
    int i;
    for (i = 0; i < num_assinaturas; i++)
    {
        if (strcmp(assinaturas[i].nome, nome) == 0)
            return &assinaturas[i];
    }
    return NULL;
}

static int tipo_numerico(Tipo tipo)
{
    return tipo == TIPO_INT || tipo == TIPO_FLOAT;
}

static int tipos_comparaveis(Tipo a, Tipo b)
{
    if (a == TIPO_NULL || b == TIPO_NULL) return 1;
    return a == b;
}

static int literal_int_do_operando(char *texto, Tipo tipo, int *valor)
{
    char *fim;
    long numero;

    if (tipo != TIPO_INT) return 0;

    numero = strtol(texto, &fim, 10);
    if (*texto == '\0' || *fim != '\0') return 0;

    if (valor != NULL) *valor = (int)numero;
    return 1;
}

void yyerror(const char *msg)
{
    (void)msg;
    printf("Erro próximo a linha %d - Programa sintaticamente incorreto\n",
           yylineno);
}
