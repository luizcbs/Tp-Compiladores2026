/* translate.y — Soundy Script — TP3: Análise Semântica
 * Tópico 3: Gabriel | Semântica: Kayo, Rodrigo
 * yyerror() e main() ficam no Tópico 4; tabela_simbolos no Tópico 2.
 *
 * Tokens e %union conferidos contra lex/soundy.l real do grupo.
 * Funções de tabela (buscarSimbolo, criarSimbolo, tipoParaString)
 * usam a API real de TabelaSimbolo.h — não reimplementadas aqui.
 */

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

/* ── Assinaturas de função (nº de parâmetros) ──
 * O retorno da função já fica em Simbolo.tipo (inserido como "funcao");
 * só o nº de parâmetros não existe na tabela do Tópico 2. */
typedef struct { char nome[50]; int num_params; } AssinaturaFuncao;
static AssinaturaFuncao assinaturas[100];
static int              num_assinaturas = 0;

/* ── Contexto da função em declaração ── */
static Tipo tipo_retorno_atual    = TIPO_NULL;
static char nome_funcao_atual[50] = "";
static int  contagem_params_atual = 0;
static int  contagem_args_atual   = 0;

static void erro_semantico(const char *msg, int linha)
{
    fprintf(stderr, "Erro semantico na linha %d: %s\n", linha, msg);
}

/* Acorde/texto → Tipo (espelha o que soundy.l reconhece como TIPO) */
static Tipo tipo_de_texto(const char *s)
{
    if (strcmp(s, "C/G")  == 0) return TIPO_INT;
    if (strcmp(s, "Am/E") == 0) return TIPO_FLOAT;
    if (strcmp(s, "Em/B") == 0) return TIPO_BOOL;
    if (strcmp(s, "F/C")  == 0) return TIPO_CHAR;
    if (strcmp(s, "G/D")  == 0) return TIPO_NULL;
    if (strcmp(s, "C7")   == 0) return TIPO_LISTA;
    return TIPO_NULL;
}

static Categoria categoria_de_texto(const char *s)
{
    if (strcmp(s, "funcao")    == 0) return CAT_FUNCAO;
    if (strcmp(s, "parametro") == 0) return CAT_PARAMETRO;
    return CAT_VARIAVEL;
}

/* Monta Simbolo via criarSimbolo() (Tópico 2) e insere na tabela atual. */
static void inserir_simbolo(char *nome, char *tipo_str, char *cat_str, int linha)
{
    Simbolo s = criarSimbolo(nome, tipo_de_texto(tipo_str),
                              categoria_de_texto(cat_str), linha);
    inserirSimbolo(tabelaAtual, s);
}

static void registrar_assinatura(const char *nome, int params)
{
    if (num_assinaturas >= 100) return;
    strncpy(assinaturas[num_assinaturas].nome, nome, 49);
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

/* Retorna 1 se o tipo é numérico (int ou float). */
static int tipo_numerico(Tipo t)
{
    return t == TIPO_INT || t == TIPO_FLOAT;
}

/* Retorna 1 se os dois tipos podem ser comparados entre si. */
static int tipos_comparaveis(Tipo a, Tipo b)
{
    if (a == TIPO_NULL || b == TIPO_NULL) return 1;
    return a == b;
}
%}

%union {
    int    ival;      /* LIT_INT, LIT_BOOL                 */
    double fval;      /* LIT_FLOAT                          */
    char   sval[256]; /* ID, TIPO, LIT_CHAR/STRING, ACORDE_LIVRE */
    Tipo   tval;      /* propagação de tipo (TP3)           */
}

/* ── Tokens — nomes idênticos aos retornados por lex/soundy.l ── */
%token FIM_LINHA
%token <sval> TIPO
%token VAR FUNC
%token IF ELSE WHILE
%token KW_RETURN KW_BREAK KW_CONTINUE
%token BLOCO_INI END_BLOCO
%token READ_LIST WRITE_LIST

%token OP_ADD OP_SUB OP_MUL OP_DIV
%token OP_AND OP_OR OP_NOT
%token OP_EQ OP_NEQ OP_GT OP_LT OP_GTE OP_LTE

%token <ival> LIT_INT
%token <fval> LIT_FLOAT
%token <sval> LIT_CHAR
%token <sval> LIT_STRING
%token <ival> LIT_BOOL
%token <sval> ID
%token <sval> ACORDE_LIVRE

%type <tval> operando

/* Resolve a ambiguidade: TIPO VAR ID END_BLOCO termina aqui,
 * ou continua para "operando FIM_LINHA"? Ver var_decl. */
%nonassoc DECL_SEM_INICIALIZACAO
%nonassoc ID LIT_INT LIT_FLOAT LIT_CHAR LIT_STRING LIT_BOOL ACORDE_LIVRE

%%

program   : decl_list | %empty ;
decl_list : decl_list decl | decl ;
decl      : func_decl | stmt ;

/* ══════════════════════════════════════════════════════
 * DECLARAÇÃO DE VARIÁVEL
 *   TIPO VAR ID END_BLOCO                    — sem valor inicial
 *   TIPO VAR ID END_BLOCO operando FIM_LINHA — com valor inicial
 * Verifica: tipo do valor inicial compatível com tipo declarado.
 * ══════════════════════════════════════════════════════ */
var_decl
    : TIPO VAR ID END_BLOCO %prec DECL_SEM_INICIALIZACAO
    {
        inserir_simbolo($3, $1, "variavel", yylineno);
    }

    | TIPO VAR ID END_BLOCO operando FIM_LINHA
    {
        Tipo t_decl = tipo_de_texto($1);
        if ($5 != TIPO_NULL && $5 != t_decl) {
            char msg[400];
            snprintf(msg, sizeof(msg),
                "variavel '%s': valor inicial (%s) incompativel com tipo declarado (%s)",
                $3, tipoParaString($5), tipoParaString(t_decl));
            erro_semantico(msg, yylineno);
        }
        inserir_simbolo($3, $1, "variavel", yylineno);
    }
    ;

/* ══════════════════════════════════════════════════════
 * DECLARAÇÃO DE FUNÇÃO
 * func_header reduz logo após "TIPO FUNC ID": insere a função no
 * escopo pai e já abre o escopo filho (parâmetros entram nele).
 * ══════════════════════════════════════════════════════ */
func_decl
    : func_header param_list BLOCO_INI stmt_list END_BLOCO
    {
        registrar_assinatura(nome_funcao_atual, contagem_params_atual);
        sairTabelaSimbolo(&tabelaAtual);
    }
    | func_header BLOCO_INI stmt_list END_BLOCO
    {
        registrar_assinatura(nome_funcao_atual, 0);
        sairTabelaSimbolo(&tabelaAtual);
    }
    ;

func_header
    : TIPO FUNC ID
    {
        inserir_simbolo($3, $1, "funcao", yylineno);
        tipo_retorno_atual = tipo_de_texto($1);
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
 * IF / IF-ELSE — a nota guia (ID) deve ser bool.
 * ══════════════════════════════════════════════════════ */
if_stmt
    : IF BLOCO_INI ID FIM_LINHA stmt_list END_BLOCO
    {
        Simbolo *s = buscarSimbolo(tabelaAtual, $3);
        if (s == NULL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "IF: nota guia '%s' nao declarada", $3);
            erro_semantico(msg, yylineno);
        } else if (s->tipo != TIPO_BOOL) {
            char msg[400]; snprintf(msg, sizeof(msg),
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
            char msg[400]; snprintf(msg, sizeof(msg),
                "IF/ELSE: nota guia '%s' nao declarada", $3);
            erro_semantico(msg, yylineno);
        } else if (s->tipo != TIPO_BOOL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "IF/ELSE: nota guia '%s' deve ser bool, mas e %s",
                $3, tipoParaString(s->tipo));
            erro_semantico(msg, yylineno);
        }
    }
    ;

/* ══════════════════════════════════════════════════════
 * WHILE — nota guia deve ser bool.
 * ══════════════════════════════════════════════════════ */
while_stmt
    : WHILE BLOCO_INI ID FIM_LINHA stmt_list END_BLOCO
    {
        Simbolo *s = buscarSimbolo(tabelaAtual, $3);
        if (s == NULL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "WHILE: nota guia '%s' nao declarada", $3);
            erro_semantico(msg, yylineno);
        } else if (s->tipo != TIPO_BOOL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "WHILE: nota guia '%s' deve ser bool, mas e %s",
                $3, tipoParaString(s->tipo));
            erro_semantico(msg, yylineno);
        }
    }
    ;

/* ══════════════════════════════════════════════════════
 * RETURN (Am / KW_RETURN)
 * Verifica: fora de função; tipo retornado ≠ tipo declarado.
 * ══════════════════════════════════════════════════════ */
return_stmt
    : KW_RETURN operando FIM_LINHA
    {
        if (tipo_retorno_atual == TIPO_NULL && nome_funcao_atual[0] == '\0') {
            erro_semantico("return (Am) usado fora de uma funcao", yylineno);
        } else if ($2 != TIPO_NULL && $2 != tipo_retorno_atual) {
            char msg[400];
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
 * READLIST — C7maj
 * $2=destino  $3=lista  $4=tipo do índice
 * ══════════════════════════════════════════════════════ */
read_list_stmt
    : READ_LIST ID ID operando FIM_LINHA
    {
        Simbolo *dest  = buscarSimbolo(tabelaAtual, $2);
        Simbolo *lista = buscarSimbolo(tabelaAtual, $3);

        if (dest == NULL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "ReadList: destino '%s' nao declarado", $2);
            erro_semantico(msg, yylineno);
        }
        if (lista == NULL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "ReadList: '%s' nao declarado", $3);
            erro_semantico(msg, yylineno);
        } else if (lista->tipo != TIPO_LISTA) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "ReadList: '%s' nao e uma lista (e %s)", $3, tipoParaString(lista->tipo));
            erro_semantico(msg, yylineno);
        }
        if ($4 != TIPO_INT) {
            char msg[400]; snprintf(msg, sizeof(msg),
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
            char msg[400]; snprintf(msg, sizeof(msg),
                "WriteList: '%s' nao declarado", $2);
            erro_semantico(msg, yylineno);
        } else if (lista->tipo != TIPO_LISTA) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "WriteList: '%s' nao e uma lista (e %s)", $2, tipoParaString(lista->tipo));
            erro_semantico(msg, yylineno);
        }
        if ($3 != TIPO_INT) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "WriteList: indice deve ser int, mas e %s", tipoParaString($3));
            erro_semantico(msg, yylineno);
        }
    }
    ;

/* ══════════════════════════════════════════════════════
 * CHAMADA DE FUNÇÃO — ID operando_list FIM_LINHA
 * (sem token dedicado: o ID inicial é o nome da função chamada)
 * Verifica: função declarada; nº de argumentos == nº de parâmetros.
 * ══════════════════════════════════════════════════════ */
func_call_stmt
    : ID { contagem_args_atual = 0; } operando_list FIM_LINHA
    {
        AssinaturaFuncao *sig = buscar_assinatura($1);
        if (sig == NULL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "chamada: funcao '%s' nao declarada (declare antes de chamar)", $1);
            erro_semantico(msg, yylineno);
        } else if (contagem_args_atual != sig->num_params) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "chamada '%s': esperava %d argumento(s), recebeu %d",
                $1, sig->num_params, contagem_args_atual);
            erro_semantico(msg, yylineno);
        }
    }
    ;

operando_list
    : operando_list operando { contagem_args_atual++; }
    | %empty
    ;

/* ══════════════════════════════════════════════════════
 * OPERADORES BINÁRIOS (três endereços): OP destino op1 op2 FIM_LINHA
 * Aritméticos → destino/operandos numéricos (int ou float)
 * Lógicos     → destino/operandos bool
 * Igualdade   → destino bool; operandos do mesmo tipo
 * Ordem       → destino bool; operandos numéricos
 * ══════════════════════════════════════════════════════ */
op_binario
    /* ── SOMA — C/E ── */
    : OP_ADD ID operando operando FIM_LINHA
    {
        Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
        if (dest == NULL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "soma (C/E): destino '%s' nao declarado", $2);
            erro_semantico(msg, yylineno);
        } else if (!tipo_numerico(dest->tipo)) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "soma (C/E): destino '%s' deve ser numerico, mas e %s",
                $2, tipoParaString(dest->tipo));
            erro_semantico(msg, yylineno);
        }
        if (!tipo_numerico($3) && $3 != TIPO_NULL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "soma (C/E): operando 1 deve ser numerico, mas e %s", tipoParaString($3));
            erro_semantico(msg, yylineno);
        }
        if (!tipo_numerico($4) && $4 != TIPO_NULL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "soma (C/E): operando 2 deve ser numerico, mas e %s", tipoParaString($4));
            erro_semantico(msg, yylineno);
        }
    }

    /* ── SUBTRAÇÃO — Dm/F# ── */
    | OP_SUB ID operando operando FIM_LINHA
    {
        Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
        if (dest == NULL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "subtracao (Dm/F#): destino '%s' nao declarado", $2);
            erro_semantico(msg, yylineno);
        } else if (!tipo_numerico(dest->tipo)) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "subtracao (Dm/F#): destino '%s' deve ser numerico, mas e %s",
                $2, tipoParaString(dest->tipo));
            erro_semantico(msg, yylineno);
        }
        if (!tipo_numerico($3) && $3 != TIPO_NULL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "subtracao (Dm/F#): operando 1 deve ser numerico, mas e %s", tipoParaString($3));
            erro_semantico(msg, yylineno);
        }
        if (!tipo_numerico($4) && $4 != TIPO_NULL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "subtracao (Dm/F#): operando 2 deve ser numerico, mas e %s", tipoParaString($4));
            erro_semantico(msg, yylineno);
        }
    }

    /* ── MULTIPLICAÇÃO — E/G ── */
    | OP_MUL ID operando operando FIM_LINHA
    {
        Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
        if (dest == NULL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "multiplicacao (E/G): destino '%s' nao declarado", $2);
            erro_semantico(msg, yylineno);
        } else if (!tipo_numerico(dest->tipo)) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "multiplicacao (E/G): destino '%s' deve ser numerico, mas e %s",
                $2, tipoParaString(dest->tipo));
            erro_semantico(msg, yylineno);
        }
        if (!tipo_numerico($3) && $3 != TIPO_NULL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "multiplicacao (E/G): operando 1 deve ser numerico, mas e %s", tipoParaString($3));
            erro_semantico(msg, yylineno);
        }
        if (!tipo_numerico($4) && $4 != TIPO_NULL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "multiplicacao (E/G): operando 2 deve ser numerico, mas e %s", tipoParaString($4));
            erro_semantico(msg, yylineno);
        }
    }

    /* ── DIVISÃO — F/A ── */
    | OP_DIV ID operando operando FIM_LINHA
    {
        Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
        if (dest == NULL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "divisao (F/A): destino '%s' nao declarado", $2);
            erro_semantico(msg, yylineno);
        } else if (!tipo_numerico(dest->tipo)) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "divisao (F/A): destino '%s' deve ser numerico, mas e %s",
                $2, tipoParaString(dest->tipo));
            erro_semantico(msg, yylineno);
        }
        if (!tipo_numerico($3) && $3 != TIPO_NULL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "divisao (F/A): operando 1 deve ser numerico, mas e %s", tipoParaString($3));
            erro_semantico(msg, yylineno);
        }
        if (!tipo_numerico($4) && $4 != TIPO_NULL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "divisao (F/A): operando 2 deve ser numerico, mas e %s", tipoParaString($4));
            erro_semantico(msg, yylineno);
        }
    }

    /* ── AND — G/B ── */
    | OP_AND ID operando operando FIM_LINHA
    {
        Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
        if (dest == NULL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "and (G/B): destino '%s' nao declarado", $2);
            erro_semantico(msg, yylineno);
        } else if (dest->tipo != TIPO_BOOL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "and (G/B): destino '%s' deve ser bool, mas e %s",
                $2, tipoParaString(dest->tipo));
            erro_semantico(msg, yylineno);
        }
        if ($3 != TIPO_BOOL && $3 != TIPO_NULL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "and (G/B): operando 1 deve ser bool, mas e %s", tipoParaString($3));
            erro_semantico(msg, yylineno);
        }
        if ($4 != TIPO_BOOL && $4 != TIPO_NULL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "and (G/B): operando 2 deve ser bool, mas e %s", tipoParaString($4));
            erro_semantico(msg, yylineno);
        }
    }

    /* ── OR — Am/C ── */
    | OP_OR ID operando operando FIM_LINHA
    {
        Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
        if (dest == NULL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "or (Am/C): destino '%s' nao declarado", $2);
            erro_semantico(msg, yylineno);
        } else if (dest->tipo != TIPO_BOOL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "or (Am/C): destino '%s' deve ser bool, mas e %s",
                $2, tipoParaString(dest->tipo));
            erro_semantico(msg, yylineno);
        }
        if ($3 != TIPO_BOOL && $3 != TIPO_NULL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "or (Am/C): operando 1 deve ser bool, mas e %s", tipoParaString($3));
            erro_semantico(msg, yylineno);
        }
        if ($4 != TIPO_BOOL && $4 != TIPO_NULL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "or (Am/C): operando 2 deve ser bool, mas e %s", tipoParaString($4));
            erro_semantico(msg, yylineno);
        }
    }

    /* ── IGUAL — C7/E ── */
    | OP_EQ ID operando operando FIM_LINHA
    {
        Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
        if (dest == NULL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "igual (C7/E): destino '%s' nao declarado", $2);
            erro_semantico(msg, yylineno);
        } else if (dest->tipo != TIPO_BOOL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "igual (C7/E): destino '%s' deve ser bool, mas e %s",
                $2, tipoParaString(dest->tipo));
            erro_semantico(msg, yylineno);
        }
        if (!tipos_comparaveis($3, $4)) {
            char msg[400]; snprintf(msg, sizeof(msg),
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
            char msg[400]; snprintf(msg, sizeof(msg),
                "diferente (Dm7/F#): destino '%s' nao declarado", $2);
            erro_semantico(msg, yylineno);
        } else if (dest->tipo != TIPO_BOOL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "diferente (Dm7/F#): destino '%s' deve ser bool, mas e %s",
                $2, tipoParaString(dest->tipo));
            erro_semantico(msg, yylineno);
        }
        if (!tipos_comparaveis($3, $4)) {
            char msg[400]; snprintf(msg, sizeof(msg),
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
            char msg[400]; snprintf(msg, sizeof(msg),
                "maior_que (E7/G): destino '%s' nao declarado", $2);
            erro_semantico(msg, yylineno);
        } else if (dest->tipo != TIPO_BOOL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "maior_que (E7/G): destino '%s' deve ser bool, mas e %s",
                $2, tipoParaString(dest->tipo));
            erro_semantico(msg, yylineno);
        }
        if (!tipo_numerico($3)) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "maior_que (E7/G): operando 1 deve ser numerico, mas e %s", tipoParaString($3));
            erro_semantico(msg, yylineno);
        }
        if (!tipo_numerico($4)) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "maior_que (E7/G): operando 2 deve ser numerico, mas e %s", tipoParaString($4));
            erro_semantico(msg, yylineno);
        }
    }

    /* ── MENOR QUE — F7/A ── */
    | OP_LT ID operando operando FIM_LINHA
    {
        Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
        if (dest == NULL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "menor_que (F7/A): destino '%s' nao declarado", $2);
            erro_semantico(msg, yylineno);
        } else if (dest->tipo != TIPO_BOOL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "menor_que (F7/A): destino '%s' deve ser bool, mas e %s",
                $2, tipoParaString(dest->tipo));
            erro_semantico(msg, yylineno);
        }
        if (!tipo_numerico($3)) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "menor_que (F7/A): operando 1 deve ser numerico, mas e %s", tipoParaString($3));
            erro_semantico(msg, yylineno);
        }
        if (!tipo_numerico($4)) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "menor_que (F7/A): operando 2 deve ser numerico, mas e %s", tipoParaString($4));
            erro_semantico(msg, yylineno);
        }
    }

    /* ── MAIOR OU IGUAL — G7/B ── */
    | OP_GTE ID operando operando FIM_LINHA
    {
        Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
        if (dest == NULL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "maior_igual (G7/B): destino '%s' nao declarado", $2);
            erro_semantico(msg, yylineno);
        } else if (dest->tipo != TIPO_BOOL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "maior_igual (G7/B): destino '%s' deve ser bool, mas e %s",
                $2, tipoParaString(dest->tipo));
            erro_semantico(msg, yylineno);
        }
        if (!tipo_numerico($3)) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "maior_igual (G7/B): operando 1 deve ser numerico, mas e %s", tipoParaString($3));
            erro_semantico(msg, yylineno);
        }
        if (!tipo_numerico($4)) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "maior_igual (G7/B): operando 2 deve ser numerico, mas e %s", tipoParaString($4));
            erro_semantico(msg, yylineno);
        }
    }

    /* ── MENOR OU IGUAL — A7/C# ── */
    | OP_LTE ID operando operando FIM_LINHA
    {
        Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
        if (dest == NULL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "menor_igual (A7/C#): destino '%s' nao declarado", $2);
            erro_semantico(msg, yylineno);
        } else if (dest->tipo != TIPO_BOOL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "menor_igual (A7/C#): destino '%s' deve ser bool, mas e %s",
                $2, tipoParaString(dest->tipo));
            erro_semantico(msg, yylineno);
        }
        if (!tipo_numerico($3)) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "menor_igual (A7/C#): operando 1 deve ser numerico, mas e %s", tipoParaString($3));
            erro_semantico(msg, yylineno);
        }
        if (!tipo_numerico($4)) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "menor_igual (A7/C#): operando 2 deve ser numerico, mas e %s", tipoParaString($4));
            erro_semantico(msg, yylineno);
        }
    }
    ;

/* ══════════════════════════════════════════════════════
 * NOT — Bm/D — destino e operando devem ser bool.
 * ══════════════════════════════════════════════════════ */
op_unario
    : OP_NOT ID operando FIM_LINHA
    {
        Simbolo *dest = buscarSimbolo(tabelaAtual, $2);
        if (dest == NULL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "not (Bm/D): destino '%s' nao declarado", $2);
            erro_semantico(msg, yylineno);
        } else if (dest->tipo != TIPO_BOOL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "not (Bm/D): destino '%s' deve ser bool, mas e %s",
                $2, tipoParaString(dest->tipo));
            erro_semantico(msg, yylineno);
        }
        if ($3 != TIPO_BOOL && $3 != TIPO_NULL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "not (Bm/D): operando deve ser bool, mas e %s", tipoParaString($3));
            erro_semantico(msg, yylineno);
        }
    }
    ;

/* ══════════════════════════════════════════════════════
 * OPERANDO — propaga Tipo para cima na árvore sintática.
 * ══════════════════════════════════════════════════════ */
operando
    : ID
    {
        Simbolo *s = buscarSimbolo(tabelaAtual, $1);
        if (s == NULL) {
            char msg[400]; snprintf(msg, sizeof(msg),
                "variavel '%s' usada sem ter sido declarada", $1);
            erro_semantico(msg, yylineno);
            $$ = TIPO_NULL;
        } else {
            $$ = s->tipo;
        }
    }
    | LIT_INT    { $$ = TIPO_INT;   }
    | LIT_FLOAT  { $$ = TIPO_FLOAT; }
    | LIT_CHAR   { $$ = TIPO_CHAR;  }
    | LIT_STRING { $$ = TIPO_CHAR;  } /* sem tipo string dedicado na tabela */
    | LIT_BOOL   { $$ = TIPO_BOOL;  }
    | ACORDE_LIVRE { $$ = TIPO_NULL; } /* acorde livre: opaco/wildcard */
    ;

%%
