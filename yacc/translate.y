%{
/*
 * Soundy Script -- Analisador Sintatico (Trabalho Pratico 2)
 * Topico 3: Gramatica e Analisador Sintatico
 * Este arquivo concentra a gramatica e as acoes semanticas do parser.
 * A interface de execucao do compilador fica em main.c.
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
int  yylex(void);
void yyerror(const char *msg);
static void inserir_simbolo(const char *nome, const char *tipo, const char *categoria, int linha);
static Tipo tipo_de_texto(const char *tipo);
static Categoria categoria_de_texto(const char *categoria);

extern TabelaSimbolo *global;
extern TabelaSimbolo *tabelaAtual;

static void verificar_operacao_binaria(const char *dest_name, const char *op1_name, const char *op2_name, const char *operacao);
static int is_literal(const char *str);
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
%type <sval> operando

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
 * ---------------------------------------------------------- */
operando
    : ID             { strcpy($$, $1); }
    | LIT_INT        { sprintf($$, "%d", $1); }
    | LIT_FLOAT      { sprintf($$, "%f", $1); }
    | LIT_CHAR       { strcpy($$, $1); }
    | LIT_STRING     { strcpy($$, $1); }
    | LIT_BOOL       { sprintf($$, "%d", $1); }
    | ACORDE_LIVRE   { strcpy($$, $1); }
    ;

/* ----------------------------------------------------------
 * OPERACOES BINARIAS DE TRES ENDERECOS (E ATRIBUICAO)
 * ---------------------------------------------------------- */
op_binario
    : OP_ADD ID operando operando FIM_LINHA
        { verificar_operacao_binaria($2, $3, $4, "soma"); }
    | OP_SUB ID operando operando FIM_LINHA
        { verificar_operacao_binaria($2, $3, $4, "subtracao"); }
    | OP_MUL ID operando operando FIM_LINHA
        { verificar_operacao_binaria($2, $3, $4, "multiplicacao"); }
    | OP_DIV ID operando operando FIM_LINHA
        { verificar_operacao_binaria($2, $3, $4, "divisao"); }
    | OP_AND ID operando operando FIM_LINHA
        { verificar_operacao_binaria($2, $3, $4, "and"); }
    | OP_OR  ID operando operando FIM_LINHA
        { verificar_operacao_binaria($2, $3, $4, "or"); }
    | OP_EQ  ID operando operando FIM_LINHA
        { verificar_operacao_binaria($2, $3, $4, "igual"); }
    | OP_NEQ ID operando operando FIM_LINHA
        { verificar_operacao_binaria($2, $3, $4, "diferente"); }
    | OP_GT  ID operando operando FIM_LINHA
        { verificar_operacao_binaria($2, $3, $4, "maior"); }
    | OP_LT  ID operando operando FIM_LINHA
        { verificar_operacao_binaria($2, $3, $4, "menor"); }
    | OP_GTE ID operando operando FIM_LINHA
        { verificar_operacao_binaria($2, $3, $4, "maior ou igual"); }
    | OP_LTE ID operando operando FIM_LINHA
        { verificar_operacao_binaria($2, $3, $4, "menor ou igual"); }
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

// Função auxiliar para ignorar literais na hora de buscar na Tabela
static int is_literal(const char *str) {
    if (str[0] >= '0' && str[0] <= '9') return 1;
    if (strcmp(str, "0") == 0 || strcmp(str, "1") == 0) return 1; // bools do lexer
    return 0;
}

static void verificar_operacao_binaria(const char *dest_name, const char *op1_name, const char *op2_name, const char *operacao) 
{
    if (tabelaAtual == NULL) return;

    // 1. Verifica Existência do Destino
    Simbolo *dest = buscarSimbolo(tabelaAtual, (char*)dest_name);
    if (dest == NULL) {
        printf("Erro Semantico (Linha %d): Variavel de destino '%s' nao declarada.\n", yylineno, dest_name);
        return; 
    }

    // 2. Verifica Existência do Operando 1 (se não for um número literal)
    Simbolo *s_op1 = NULL;
    if (!is_literal(op1_name)) {
        s_op1 = buscarSimbolo(tabelaAtual, (char*)op1_name);
        if (s_op1 == NULL) {
            printf("Erro Semantico (Linha %d): Variavel '%s' nao declarada antes do uso.\n", yylineno, op1_name);
        }
    }

    // 3. Verifica Existência do Operando 2 (se não for um número literal)
    Simbolo *s_op2 = NULL;
    if (!is_literal(op2_name)) {
        s_op2 = buscarSimbolo(tabelaAtual, (char*)op2_name);
        if (s_op2 == NULL) {
            printf("Erro Semantico (Linha %d): Variavel '%s' nao declarada antes do uso.\n", yylineno, op2_name);
        }
    }

    // =========================================================
    // 4. VERIFICAÇÃO DE TIPOS
    // =========================================================
    
    // A. OPERAÇÕES ARITMÉTICAS
    if (strcmp(operacao, "soma") == 0 || strcmp(operacao, "subtracao") == 0 || 
        strcmp(operacao, "multiplicacao") == 0 || strcmp(operacao, "divisao") == 0) 
    {
        if (dest->tipo != TIPO_INT && dest->tipo != TIPO_FLOAT) {
            printf("Erro Semantico (Linha %d): Operacao de '%s' exige destino numerico (Encontrado: '%s').\n", 
                   yylineno, operacao, dest_name);
        }
        
        if (s_op1 != NULL && s_op1->tipo != TIPO_INT && s_op1->tipo != TIPO_FLOAT) {
            printf("Erro Semantico (Linha %d): Operando '%s' invalido para conta matematica.\n", yylineno, op1_name);
        }
        if (s_op2 != NULL && s_op2->tipo != TIPO_INT && s_op2->tipo != TIPO_FLOAT) {
            printf("Erro Semantico (Linha %d): Operando '%s' invalido para conta matematica.\n", yylineno, op2_name);
        }
    }
    
    // B. OPERAÇÕES LÓGICAS (AND, OR)
    else if (strcmp(operacao, "and") == 0 || strcmp(operacao, "or") == 0) 
    {
        if (dest->tipo != TIPO_BOOL) {
            printf("Erro Semantico (Linha %d): Operacao logica '%s' exige que o destino seja Booleano.\n", yylineno, operacao);
        }
        
        if (s_op1 != NULL && s_op1->tipo != TIPO_BOOL) {
            printf("Erro Semantico (Linha %d): Operando '%s' deve ser Booleano para a operacao '%s'.\n", yylineno, op1_name, operacao);
        }
        if (s_op2 != NULL && s_op2->tipo != TIPO_BOOL) {
            printf("Erro Semantico (Linha %d): Operando '%s' deve ser Booleano para a operacao '%s'.\n", yylineno, op2_name, operacao);
        }
    }

    // C. OPERAÇÕES RELACIONAIS (Maior, Menor, Igual, Diferente, etc.)
    else if (strcmp(operacao, "igual") == 0 || strcmp(operacao, "diferente") == 0 || 
             strcmp(operacao, "maior") == 0 || strcmp(operacao, "menor") == 0 || 
             strcmp(operacao, "maior ou igual") == 0 || strcmp(operacao, "menor ou igual") == 0) 
    {
        // O destino obrigatoriamente precisa ser Bool para guardar o Verdadeiro ou Falso do teste
        if (dest->tipo != TIPO_BOOL) {
            printf("Erro Semantico (Linha %d): Operacao relacional '%s' exige destino Booleano (variavel '%s' nao e Bool).\n", 
                   yylineno, operacao, dest_name);
        }

        // Operandos de grandeza (>, <, >=, <=) normalmente exigem valores numéricos para comparação
        if (strcmp(operacao, "igual") != 0 && strcmp(operacao, "diferente") != 0) {
            if (s_op1 != NULL && s_op1->tipo != TIPO_INT && s_op1->tipo != TIPO_FLOAT) {
                printf("Erro Semantico (Linha %d): Operando '%s' deve ser numerico para a comparacao '%s'.\n", yylineno, op1_name, operacao);
            }
            if (s_op2 != NULL && s_op2->tipo != TIPO_INT && s_op2->tipo != TIPO_FLOAT) {
                printf("Erro Semantico (Linha %d): Operando '%s' deve ser numerico para a comparacao '%s'.\n", yylineno, op2_name, operacao);
            }
        }
    }
}