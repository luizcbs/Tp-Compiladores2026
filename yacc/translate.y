

%code requires {
    #include "TabelaSimbolo.h"
}

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "TabelaSimbolo.h"

extern int  yylineno;
extern TabelaSimbolo *tabelaAtual;
int  yylex(void);
void yyerror(const char *msg);

/* ── Assinaturas de função (retorno + nº de parâmetros) ──
 * Simbolo.tipo ja guarda o retorno da funcao (inserido como "funcao"),
 * mas o numero de parametros nao existe na tabela do Topico 2. */
typedef struct { char nome[50]; Tipo retorno; int num_params; } AssinaturaFuncao;
static AssinaturaFuncao assinaturas[100];
static int              num_assinaturas = 0;

/* ── Tamanhos de vetor — necessario para bounds checking.
 * Nao existe campo equivalente em Simbolo; mantido aqui ate o
 * Topico 2 decidir se adiciona um campo "tamanho" na struct. */
typedef struct { char nome[50]; int tamanho; } InfoVetor;
static InfoVetor vetores[100];
static int       num_vetores = 0;

/* ── Contexto da função em declaração ── */
static Tipo tipo_retorno_atual    = TIPO_NULL;
static char nome_funcao_atual[50] = "";
static int  contagem_params_atual = 0;
static int  contagem_args_atual   = 0;

static void erro_semantico(const char *msg, int linha)
{
    fprintf(stderr, "Erro semantico na linha %d: %s\n", linha, msg);
}

/* Acorde/texto → Tipo. G/D e F/C NAO aparecem mais aqui: null e
 * literal (NULL_LIT) e char foi removido da linguagem no TP3. */
static Tipo tipo_de_texto(const char *s)
{
    if (strcmp(s, "C/G")  == 0) return TIPO_INT;
    if (strcmp(s, "Am/E") == 0) return TIPO_FLOAT;
    if (strcmp(s, "Em/B") == 0) return TIPO_BOOL;
    if (strcmp(s, "C7")   == 0) return TIPO_LISTA;
    return TIPO_NULL; /* nao deveria ocorrer com o lexer atualizado */
}

static Categoria categoria_de_texto(const char *s)
{
    if (strcmp(s, "funcao")    == 0) return CAT_FUNCAO;
    if (strcmp(s, "parametro") == 0) return CAT_PARAMETRO;
    return CAT_VARIAVEL;
}

static void inserir_simbolo(char *nome, char *tipo_str, char *cat_str, int linha)
{
    Simbolo s = criarSimbolo(nome, tipo_de_texto(tipo_str),
                              categoria_de_texto(cat_str), linha);
    inserirSimbolo(tabelaAtual, s);
}

static void registrar_assinatura(const char *nome, Tipo retorno, int params)
{
    if (num_assinaturas >= 100) return;
    strncpy(assinaturas[num_assinaturas].nome, nome, 49);
    assinaturas[num_assinaturas].retorno    = retorno;
    assinaturas[num_assinaturas].num_params = params;
    num_assinaturas++;
}

static AssinaturaFuncao *buscar_assinatura(const char *nome)
{
    int i;
    for (i = 0; i < num_assinaturas; i++)
        if (strcmp(assinaturas[i].nome, nome) == 0)
            return &assinaturas[i];
    return NULL;
}

static void registrar_vetor(const char *nome, int tamanho)
{
    if (num_vetores >= 100) return;
    strncpy(vetores[num_vetores].nome, nome, 49);
    vetores[num_vetores].tamanho = tamanho;
    num_vetores++;
}

/* Retorna -1 se o vetor nao foi encontrado no registro local. */
static int buscar_tamanho_vetor(const char *nome)
{
    int i;
    for (i = 0; i < num_vetores; i++)
        if (strcmp(vetores[i].nome, nome) == 0)
            return vetores[i].tamanho;
    return -1;
}

static int tipo_numerico(Tipo t)
{
    return t == TIPO_INT || t == TIPO_FLOAT;
}

static int tipos_comparaveis(Tipo a, Tipo b)
{
    if (a == TIPO_NULL || b == TIPO_NULL) return 1;
    return a == b;
}
%}

%union {
    int    ival;
    double fval;
    char   sval[256];
    Tipo   tval;
}

%token FIM_LINHA
%token <sval> TIPO
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
%token <sval> ID
%token <sval> ACORDE_LIVRE
%token NULL_LIT

%type <tval> operando

%%

program   : decl_list | %empty ;
decl_list : decl_list decl | decl ;
decl      : func_decl | stmt ;

/* ══════════════════════════════════════════════════════
 * DECLARAÇÃO DE VARIÁVEL (doc 4.4 — agora sempre fecha com FIM_LINHA)
 *   TIPO VAR ID END_BLOCO FIM_LINHA              — sem valor inicial
 *   TIPO VAR ID END_BLOCO operando FIM_LINHA      — com valor inicial
 * ══════════════════════════════════════════════════════ */
var_decl
    : TIPO VAR ID END_BLOCO FIM_LINHA
    {
        inserir_simbolo($3, $1, "variavel", yylineno);
    }

    | TIPO VAR ID END_BLOCO operando FIM_LINHA
    {
        Tipo t_decl = tipo_de_texto($1);
        if ($5 != TIPO_NULL && $5 != t_decl) {
            char msg[512];
            snprintf(msg, sizeof(msg),
                "variavel '%s': valor inicial incompativel com tipo declarado", $3);
            erro_semantico(msg, yylineno);
        }
        inserir_simbolo($3, $1, "variavel", yylineno);
    }

    /* ══════════════════════════════════════════════════
     * DECLARAÇÃO DE VETOR (doc 1.2 / 4.5 — tamanho obrigatorio)
     *   TIPO(lista) TIPO(elemento) ID END_BLOCO '[' LIT_INT ']' FIM_LINHA
     * Ex.: C7 C/G notas Cm [8] B C
     * ══════════════════════════════════════════════════ */
    | TIPO TIPO ID END_BLOCO '[' LIT_INT ']' FIM_LINHA
    {
        if (strcmp($1, "C7") != 0) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "vetor '%s': tipo composto esperado e C7 (lista)", $3);
            erro_semantico(msg, yylineno);
        }
        if ($6 <= 0) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "vetor '%s': tamanho deve ser > 0 (recebeu %d)", $3, $6);
            erro_semantico(msg, yylineno);
        }
        inserir_simbolo($3, $1, "variavel", yylineno);
        registrar_vetor($3, $6);
    }
    ;

/* ══════════════════════════════════════════════════════
 * DECLARAÇÃO DE FUNÇÃO (doc 8.2 — END_BLOCO logo apos o ID)
 * func_header reduz apos "TIPO FUNC ID END_BLOCO": insere a funcao
 * no escopo pai e abre o escopo filho antes dos parametros.
 * ══════════════════════════════════════════════════════ */
func_decl
    : func_header param_list BLOCO_INI stmt_list END_BLOCO
    {
        registrar_assinatura(nome_funcao_atual, tipo_retorno_atual,
                             contagem_params_atual);
        sairTabelaSimbolo(&tabelaAtual);
    }
    | func_header BLOCO_INI stmt_list END_BLOCO
    {
        registrar_assinatura(nome_funcao_atual, tipo_retorno_atual, 0);
        sairTabelaSimbolo(&tabelaAtual);
    }
    ;

func_header
    : TIPO FUNC ID END_BLOCO
    {
        inserir_simbolo($3, $1, "funcao", yylineno);
        tipo_retorno_atual    = tipo_de_texto($1);
        strncpy(nome_funcao_atual, $3, 49);
        contagem_params_atual = 0;

        TabelaSimbolo *filho = criarTabelaSimbolo($3, tabelaAtual);
        adicionarFilho(tabelaAtual, filho);
        entrarTabalaSimbolo(&tabelaAtual, filho);
    }
    ;

param_list : param_list param | param ;

param
    : TIPO ID
    {
        inserir_simbolo($2, $1, "parametro", yylineno);
        contagem_params_atual++;
    }
    ;

stmt_list : stmt_list stmt | %empty ;

stmt
    : var_decl | op_binario | op_unario
    | if_stmt | while_stmt | return_stmt
    | break_stmt | continue_stmt
    | read_list_stmt | write_list_stmt | func_call_stmt
    ;

/* ══════════════════════════════════════════════════════
 * IF / IF-ELSE — nota guia deve ser bool (doc 7.1, 7.2)
 * ══════════════════════════════════════════════════════ */
if_stmt
    : IF BLOCO_INI ID FIM_LINHA stmt_list END_BLOCO
    {
        Simbolo *s = buscarSimbolo(tabelaAtual, $3);
        if (s == NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "IF: nota guia '%s' nao declarada", $3);
            erro_semantico(msg, yylineno);
        } else if (s->tipo != TIPO_BOOL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "IF: nota guia '%s' deve ser bool, mas e %s",
                $3, tipoParaString(s->tipo));
            erro_semantico(msg, yylineno);
        }
    }

    | IF BLOCO_INI ID FIM_LINHA stmt_list END_BLOCO
      ELSE BLOCO_INI stmt_list END_BLOCO
    {
        Simbolo *s = buscarSimbolo(tabelaAtual, $3);
        if (s == NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "IF/ELSE: nota guia '%s' nao declarada", $3);
            erro_semantico(msg, yylineno);
        } else if (s->tipo != TIPO_BOOL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "IF/ELSE: nota guia '%s' deve ser bool, mas e %s",
                $3, tipoParaString(s->tipo));
            erro_semantico(msg, yylineno);
        }
    }
    ;

/* ══════════════════════════════════════════════════════
 * WHILE — nota guia deve ser bool (doc 7.3)
 * ══════════════════════════════════════════════════════ */
while_stmt
    : WHILE BLOCO_INI ID FIM_LINHA stmt_list END_BLOCO
    {
        Simbolo *s = buscarSimbolo(tabelaAtual, $3);
        if (s == NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "WHILE: nota guia '%s' nao declarada", $3);
            erro_semantico(msg, yylineno);
        } else if (s->tipo != TIPO_BOOL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "WHILE: nota guia '%s' deve ser bool, mas e %s",
                $3, tipoParaString(s->tipo));
            erro_semantico(msg, yylineno);
        }
    }
    ;

/* ══════════════════════════════════════════════════════
 * RETURN (Am / KW_RETURN) — tipo retornado == tipo da funcao
 * ══════════════════════════════════════════════════════ */
return_stmt
    : KW_RETURN operando FIM_LINHA
    {
        if (nome_funcao_atual[0] == '\0') {
            erro_semantico("return (Am) usado fora de uma funcao", yylineno);
        } else if ($2 != TIPO_NULL && $2 != tipo_retorno_atual) {
            char msg[512];
            snprintf(msg, sizeof(msg),
                "return em '%s': tipo retornado (%s) incompativel com retorno declarado (%s)",
                nome_funcao_atual, tipoParaString($2), tipoParaString(tipo_retorno_atual));
            erro_semantico(msg, yylineno);
        }
    }
    ;

break_stmt    : KW_BREAK    FIM_LINHA ;
continue_stmt : KW_CONTINUE FIM_LINHA ;

/* ══════════════════════════════════════════════════════
 * READLIST — C7maj — bounds checking agora possivel (doc 4.7)
 * $2=destino  $3=lista  $4=tipo do índice
 * ══════════════════════════════════════════════════════ */
read_list_stmt
    : READ_LIST ID ID operando FIM_LINHA
    {
        Simbolo *dest  = buscarSimbolo(tabelaAtual, $2);
        Simbolo *lista = buscarSimbolo(tabelaAtual, $3);

        if (dest == NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "ReadList: destino '%s' nao declarado", $2);
            erro_semantico(msg, yylineno);
        }
        if (lista == NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "ReadList: '%s' nao declarado", $3);
            erro_semantico(msg, yylineno);
        } else if (lista->tipo != TIPO_LISTA) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "ReadList: '%s' nao e uma lista (e %s)", $3, tipoParaString(lista->tipo));
            erro_semantico(msg, yylineno);
        }
        if ($4 != TIPO_INT) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "ReadList: indice deve ser int, mas e %s", tipoParaString($4));
            erro_semantico(msg, yylineno);
        }
    }
    ;

/* ══════════════════════════════════════════════════════
 * WRITELIST — Cm7
 * $2=lista  $3=tipo do índice  $4=tipo do valor
 * ══════════════════════════════════════════════════════ */
write_list_stmt
    : WRITE_LIST ID operando operando FIM_LINHA
    {
        Simbolo *lista = buscarSimbolo(tabelaAtual, $2);

        if (lista == NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "WriteList: '%s' nao declarado", $2);
            erro_semantico(msg, yylineno);
        } else if (lista->tipo != TIPO_LISTA) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "WriteList: '%s' nao e uma lista (e %s)", $2, tipoParaString(lista->tipo));
            erro_semantico(msg, yylineno);
        }
        if ($3 != TIPO_INT) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "WriteList: indice deve ser int, mas e %s", tipoParaString($3));
            erro_semantico(msg, yylineno);
        }
    }
    ;

/* ══════════════════════════════════════════════════════
 * CALL — A/C# (doc 8.1) — agora COM destino e checagem de retorno
 *   CALL var_destino nome_func [argumentos] FIM_LINHA
 * ══════════════════════════════════════════════════════ */
func_call_stmt
    : CALL ID ID { contagem_args_atual = 0; } operando_list FIM_LINHA
    {
        Simbolo          *dest = buscarSimbolo(tabelaAtual, $2);
        AssinaturaFuncao *sig  = buscar_assinatura($3);

        if (dest == NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "CALL: destino '%s' nao declarado", $2);
            erro_semantico(msg, yylineno);
        }
        if (sig == NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "CALL: funcao '%s' nao declarada (declare antes de chamar)", $3);
            erro_semantico(msg, yylineno);
        } else {
            if (contagem_args_atual != sig->num_params) {
                char msg[512]; snprintf(msg, sizeof(msg),
                    "CALL '%s': esperava %d argumento(s), recebeu %d",
                    $3, sig->num_params, contagem_args_atual);
                erro_semantico(msg, yylineno);
            }
            if (dest != NULL && dest->tipo != sig->retorno) {
                char msg[512]; snprintf(msg, sizeof(msg),
                    "CALL '%s': retorno (%s) incompativel com destino '%s' (%s)",
                    $3, tipoParaString(sig->retorno), $2, tipoParaString(dest->tipo));
                erro_semantico(msg, yylineno);
            }
        }
    }
    ;

operando_list
    : operando_list operando { contagem_args_atual++; }
    | %empty
    ;

/* ══════════════════════════════════════════════════════
 * OPERADORES BINÁRIOS (três endereços): OP destino op1 op2 FIM_LINHA
 * ══════════════════════════════════════════════════════ */
op_binario
    /* ── SOMA — C/E ──
     * Excecao documentada (doc 4.8): permite destino lista quando um
     * dos operandos e o literal null (idiom de atribuicao "0 + null"). */
    : OP_ADD ID operando operando FIM_LINHA
    {
        Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
        int eh_atribuicao_null_em_lista =
            dest != NULL && dest->tipo == TIPO_LISTA &&
            ($3 == TIPO_NULL || $4 == TIPO_NULL);

        if (dest == NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "soma (C/E): destino '%s' nao declarado", $2);
            erro_semantico(msg, yylineno);
        } else if (!tipo_numerico(dest->tipo) && !eh_atribuicao_null_em_lista) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "soma (C/E): destino '%s' deve ser numerico, mas e %s",
                $2, tipoParaString(dest->tipo));
            erro_semantico(msg, yylineno);
        }
        if (!eh_atribuicao_null_em_lista) {
            if (!tipo_numerico($3) && $3 != TIPO_NULL) {
                char msg[512]; snprintf(msg, sizeof(msg),
                    "soma (C/E): operando 1 deve ser numerico, mas e %s", tipoParaString($3));
                erro_semantico(msg, yylineno);
            }
            if (!tipo_numerico($4) && $4 != TIPO_NULL) {
                char msg[512]; snprintf(msg, sizeof(msg),
                    "soma (C/E): operando 2 deve ser numerico, mas e %s", tipoParaString($4));
                erro_semantico(msg, yylineno);
            }
        }
    }

    /* ── SUBTRAÇÃO — Dm/F# ── */
    | OP_SUB ID operando operando FIM_LINHA
    {
        Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
        if (dest == NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "subtracao (Dm/F#): destino '%s' nao declarado", $2);
            erro_semantico(msg, yylineno);
        } else if (!tipo_numerico(dest->tipo)) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "subtracao (Dm/F#): destino '%s' deve ser numerico, mas e %s",
                $2, tipoParaString(dest->tipo));
            erro_semantico(msg, yylineno);
        }
        if (!tipo_numerico($3) && $3 != TIPO_NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "subtracao (Dm/F#): operando 1 deve ser numerico, mas e %s", tipoParaString($3));
            erro_semantico(msg, yylineno);
        }
        if (!tipo_numerico($4) && $4 != TIPO_NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "subtracao (Dm/F#): operando 2 deve ser numerico, mas e %s", tipoParaString($4));
            erro_semantico(msg, yylineno);
        }
    }

    /* ── MULTIPLICAÇÃO — E/G ── */
    | OP_MUL ID operando operando FIM_LINHA
    {
        Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
        if (dest == NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "multiplicacao (E/G): destino '%s' nao declarado", $2);
            erro_semantico(msg, yylineno);
        } else if (!tipo_numerico(dest->tipo)) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "multiplicacao (E/G): destino '%s' deve ser numerico, mas e %s",
                $2, tipoParaString(dest->tipo));
            erro_semantico(msg, yylineno);
        }
        if (!tipo_numerico($3) && $3 != TIPO_NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "multiplicacao (E/G): operando 1 deve ser numerico, mas e %s", tipoParaString($3));
            erro_semantico(msg, yylineno);
        }
        if (!tipo_numerico($4) && $4 != TIPO_NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "multiplicacao (E/G): operando 2 deve ser numerico, mas e %s", tipoParaString($4));
            erro_semantico(msg, yylineno);
        }
    }

    /* ── DIVISÃO — F/A ── */
    | OP_DIV ID operando operando FIM_LINHA
    {
        Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
        if (dest == NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "divisao (F/A): destino '%s' nao declarado", $2);
            erro_semantico(msg, yylineno);
        } else if (!tipo_numerico(dest->tipo)) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "divisao (F/A): destino '%s' deve ser numerico, mas e %s",
                $2, tipoParaString(dest->tipo));
            erro_semantico(msg, yylineno);
        }
        if (!tipo_numerico($3) && $3 != TIPO_NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "divisao (F/A): operando 1 deve ser numerico, mas e %s", tipoParaString($3));
            erro_semantico(msg, yylineno);
        }
        if (!tipo_numerico($4) && $4 != TIPO_NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "divisao (F/A): operando 2 deve ser numerico, mas e %s", tipoParaString($4));
            erro_semantico(msg, yylineno);
        }
    }

    /* ── AND — G/B ── */
    | OP_AND ID operando operando FIM_LINHA
    {
        Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
        if (dest == NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "and (G/B): destino '%s' nao declarado", $2);
            erro_semantico(msg, yylineno);
        } else if (dest->tipo != TIPO_BOOL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "and (G/B): destino '%s' deve ser bool, mas e %s",
                $2, tipoParaString(dest->tipo));
            erro_semantico(msg, yylineno);
        }
        if ($3 != TIPO_BOOL && $3 != TIPO_NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "and (G/B): operando 1 deve ser bool, mas e %s", tipoParaString($3));
            erro_semantico(msg, yylineno);
        }
        if ($4 != TIPO_BOOL && $4 != TIPO_NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "and (G/B): operando 2 deve ser bool, mas e %s", tipoParaString($4));
            erro_semantico(msg, yylineno);
        }
    }

    /* ── OR — Am/C ── */
    | OP_OR ID operando operando FIM_LINHA
    {
        Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
        if (dest == NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "or (Am/C): destino '%s' nao declarado", $2);
            erro_semantico(msg, yylineno);
        } else if (dest->tipo != TIPO_BOOL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "or (Am/C): destino '%s' deve ser bool, mas e %s",
                $2, tipoParaString(dest->tipo));
            erro_semantico(msg, yylineno);
        }
        if ($3 != TIPO_BOOL && $3 != TIPO_NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "or (Am/C): operando 1 deve ser bool, mas e %s", tipoParaString($3));
            erro_semantico(msg, yylineno);
        }
        if ($4 != TIPO_BOOL && $4 != TIPO_NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "or (Am/C): operando 2 deve ser bool, mas e %s", tipoParaString($4));
            erro_semantico(msg, yylineno);
        }
    }

    /* ── IGUAL — C7/E ── */
    | OP_EQ ID operando operando FIM_LINHA
    {
        Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
        if (dest == NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "igual (C7/E): destino '%s' nao declarado", $2);
            erro_semantico(msg, yylineno);
        } else if (dest->tipo != TIPO_BOOL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "igual (C7/E): destino '%s' deve ser bool, mas e %s",
                $2, tipoParaString(dest->tipo));
            erro_semantico(msg, yylineno);
        }
        if (!tipos_comparaveis($3, $4)) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "igual (C7/E): operandos de tipos diferentes (%s vs %s)",
                tipoParaString($3), tipoParaString($4));
            erro_semantico(msg, yylineno);
        }
    }

    /* ── DIFERENTE — Dm7/F# ── */
    | OP_NEQ ID operando operando FIM_LINHA
    {
        Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
        if (dest == NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "diferente (Dm7/F#): destino '%s' nao declarado", $2);
            erro_semantico(msg, yylineno);
        } else if (dest->tipo != TIPO_BOOL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "diferente (Dm7/F#): destino '%s' deve ser bool, mas e %s",
                $2, tipoParaString(dest->tipo));
            erro_semantico(msg, yylineno);
        }
        if (!tipos_comparaveis($3, $4)) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "diferente (Dm7/F#): operandos de tipos diferentes (%s vs %s)",
                tipoParaString($3), tipoParaString($4));
            erro_semantico(msg, yylineno);
        }
    }

    /* ── MAIOR QUE — E7/G ── */
    | OP_GT ID operando operando FIM_LINHA
    {
        Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
        if (dest == NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "maior_que (E7/G): destino '%s' nao declarado", $2);
            erro_semantico(msg, yylineno);
        } else if (dest->tipo != TIPO_BOOL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "maior_que (E7/G): destino '%s' deve ser bool, mas e %s",
                $2, tipoParaString(dest->tipo));
            erro_semantico(msg, yylineno);
        }
        if (!tipo_numerico($3)) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "maior_que (E7/G): operando 1 deve ser numerico, mas e %s", tipoParaString($3));
            erro_semantico(msg, yylineno);
        }
        if (!tipo_numerico($4)) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "maior_que (E7/G): operando 2 deve ser numerico, mas e %s", tipoParaString($4));
            erro_semantico(msg, yylineno);
        }
    }

    /* ── MENOR QUE — F7/A ── */
    | OP_LT ID operando operando FIM_LINHA
    {
        Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
        if (dest == NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "menor_que (F7/A): destino '%s' nao declarado", $2);
            erro_semantico(msg, yylineno);
        } else if (dest->tipo != TIPO_BOOL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "menor_que (F7/A): destino '%s' deve ser bool, mas e %s",
                $2, tipoParaString(dest->tipo));
            erro_semantico(msg, yylineno);
        }
        if (!tipo_numerico($3)) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "menor_que (F7/A): operando 1 deve ser numerico, mas e %s", tipoParaString($3));
            erro_semantico(msg, yylineno);
        }
        if (!tipo_numerico($4)) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "menor_que (F7/A): operando 2 deve ser numerico, mas e %s", tipoParaString($4));
            erro_semantico(msg, yylineno);
        }
    }

    /* ── MAIOR OU IGUAL — G7/B ── */
    | OP_GTE ID operando operando FIM_LINHA
    {
        Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
        if (dest == NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "maior_igual (G7/B): destino '%s' nao declarado", $2);
            erro_semantico(msg, yylineno);
        } else if (dest->tipo != TIPO_BOOL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "maior_igual (G7/B): destino '%s' deve ser bool, mas e %s",
                $2, tipoParaString(dest->tipo));
            erro_semantico(msg, yylineno);
        }
        if (!tipo_numerico($3)) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "maior_igual (G7/B): operando 1 deve ser numerico, mas e %s", tipoParaString($3));
            erro_semantico(msg, yylineno);
        }
        if (!tipo_numerico($4)) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "maior_igual (G7/B): operando 2 deve ser numerico, mas e %s", tipoParaString($4));
            erro_semantico(msg, yylineno);
        }
    }

    /* ── MENOR OU IGUAL — A7/C# ── */
    | OP_LTE ID operando operando FIM_LINHA
    {
        Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
        if (dest == NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "menor_igual (A7/C#): destino '%s' nao declarado", $2);
            erro_semantico(msg, yylineno);
        } else if (dest->tipo != TIPO_BOOL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "menor_igual (A7/C#): destino '%s' deve ser bool, mas e %s",
                $2, tipoParaString(dest->tipo));
            erro_semantico(msg, yylineno);
        }
        if (!tipo_numerico($3)) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "menor_igual (A7/C#): operando 1 deve ser numerico, mas e %s", tipoParaString($3));
            erro_semantico(msg, yylineno);
        }
        if (!tipo_numerico($4)) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "menor_igual (A7/C#): operando 2 deve ser numerico, mas e %s", tipoParaString($4));
            erro_semantico(msg, yylineno);
        }
    }
    ;

/* ══════════════════════════════════════════════════════
 * NOT — Bm/D — destino e operando devem ser bool
 * ══════════════════════════════════════════════════════ */
op_unario
    : OP_NOT ID operando FIM_LINHA
    {
        Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
        if (dest == NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "not (Bm/D): destino '%s' nao declarado", $2);
            erro_semantico(msg, yylineno);
        } else if (dest->tipo != TIPO_BOOL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "not (Bm/D): destino '%s' deve ser bool, mas e %s",
                $2, tipoParaString(dest->tipo));
            erro_semantico(msg, yylineno);
        }
        if ($3 != TIPO_BOOL && $3 != TIPO_NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "not (Bm/D): operando deve ser bool, mas e %s", tipoParaString($3));
            erro_semantico(msg, yylineno);
        }
    }
    ;

/* ══════════════════════════════════════════════════════
 * OPERANDO (doc secao 10, ajustado ao TP3: sem char/string,
 * com null como literal)
 * ══════════════════════════════════════════════════════ */
operando
    : ID
    {
        Simbolo *s = buscarSimbolo(tabelaAtual, $1);
        if (s == NULL) {
            char msg[512]; snprintf(msg, sizeof(msg),
                "variavel '%s' usada sem ter sido declarada", $1);
            erro_semantico(msg, yylineno);
            $$ = TIPO_NULL;
        } else {
            $$ = s->tipo;
        }
    }
    | LIT_INT      { $$ = TIPO_INT;   }
    | LIT_FLOAT    { $$ = TIPO_FLOAT; }
    | LIT_BOOL     { $$ = TIPO_BOOL;  }
    | NULL_LIT     { $$ = TIPO_NULL;  }
    | ACORDE_LIVRE { $$ = TIPO_NULL;  } /* opaco/wildcard */
    ;

%%
