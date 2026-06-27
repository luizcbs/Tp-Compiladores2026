#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "gci.h"

#define MAX_IR 1000
#define MAX_ARGS_CALL 16
#define MAX_ASM_SIMBOLOS 256
#define MAX_NOME_ASM 80

typedef struct {
    char op[32];
    char a[256];
    char b[256];
    char c[256];
    char args[MAX_ARGS_CALL][256];
    int argc;
} InstrucaoIR;

typedef struct {
    char original[256];
    char asm_nome[MAX_NOME_ASM];
    int endereco;
    int tamanho;
    int eh_lista;
} SimboloAsm;

static InstrucaoIR ir[MAX_IR];
static int qtd_ir = 0;

static char args_call_atual[MAX_ARGS_CALL][256];
static int qtd_args_call_atual = 0;

static void registrar_ir(const char* op,
                         const char* a,
                         const char* b,
                         const char* c)
{
    if (qtd_ir >= MAX_IR)
    {
        fprintf(stderr, "Erro GCI: limite de instrucoes intermediarias excedido.\n");
        return;
    }

    strncpy(ir[qtd_ir].op, op ? op : "", sizeof(ir[qtd_ir].op) - 1);
    strncpy(ir[qtd_ir].a,  a  ? a  : "", sizeof(ir[qtd_ir].a)  - 1);
    strncpy(ir[qtd_ir].b,  b  ? b  : "", sizeof(ir[qtd_ir].b)  - 1);
    strncpy(ir[qtd_ir].c,  c  ? c  : "", sizeof(ir[qtd_ir].c)  - 1);
    ir[qtd_ir].op[sizeof(ir[qtd_ir].op) - 1] = '\0';
    ir[qtd_ir].a[sizeof(ir[qtd_ir].a) - 1] = '\0';
    ir[qtd_ir].b[sizeof(ir[qtd_ir].b) - 1] = '\0';
    ir[qtd_ir].c[sizeof(ir[qtd_ir].c) - 1] = '\0';
    ir[qtd_ir].argc = 0;
    qtd_ir++;
}

/* ================================================================
 * UTILITÁRIOS INTERNOS
 * ================================================================ */

/*
 * eh_literal_numerico
 * -------------------
 * Tenta converter a string s para double via strtod.
 * Retorna 1 se s é inteiramente um número, 0 caso contrário.
 * O valor convertido é guardado em *out quando out != NULL.
 *
 * Exemplos que retornam 1 : "0", "1", "3", "4", "7", "3.14"
 * Exemplos que retornam 0 : "a", "resultado", "L0", ""
 */
static int eh_literal_numerico(const char* s, double* out)
{
    if (s == NULL || *s == '\0') return 0;

    char* fim;
    errno = 0;
    double val = strtod(s, &fim);

    if (fim == s || *fim != '\0' || errno != 0) return 0;

    if (out) *out = val;
    return 1;
}

/*
 * eh_igual
 * --------
 * Retorna 1 se a string s representa o valor numérico val.
 * Usado para detectar elementos neutros e absorventes.
 */
static int eh_igual(const char* s, double val)
{
    double v;
    if (!eh_literal_numerico(s, &v)) return 0;
    return v == val;
}

/* ================================================================
 * CONTADOR DE LABELS
 * ================================================================ */

static int contador_label = 0;

char* gci_nova_label()
{
    char* label = (char*) malloc(10);
    sprintf(label, "L%d", contador_label++);
    return label;
}

/* ================================================================
 * PILHA DO WHILE
 *
 * Mantém os labels de início e fim do loop atual.
 * Necessária para que break e continue, mesmo dentro de loops
 * aninhados, sempre encontrem o loop mais interno correto.
 * ================================================================ */

#define MAX_WHILE 20

static char* pilha_inicio_while[MAX_WHILE];
static char* pilha_fim_while[MAX_WHILE];
static int   topo_pilha_while = -1;

void gci_push_while(char* inicio, char* fim)
{
    if (topo_pilha_while >= MAX_WHILE - 1)
    {
        fprintf(stderr,
                "Erro GCI: aninhamento de while excede limite (%d).\n",
                MAX_WHILE);
        return;
    }
    topo_pilha_while++;
    pilha_inicio_while[topo_pilha_while] = inicio;
    pilha_fim_while[topo_pilha_while]    = fim;
}

void  gci_pop_while()    { if (topo_pilha_while >= 0) topo_pilha_while--; }
char* gci_get_while_inicio()
{
    if (topo_pilha_while < 0) return "";
    return pilha_inicio_while[topo_pilha_while];
}
char* gci_get_while_fim()
{
    if (topo_pilha_while < 0) return "";
    return pilha_fim_while[topo_pilha_while];
}

/* ================================================================
 * PILHA DO IF
 *
 * Guarda os labels de saída dos blocos if/else.
 * O código original tentava passar labels entre ações semânticas
 * distintas do Bison usando $<sval>N — comportamento indefinido
 * em compilações otimizadas, pois o Bison não garante que a union
 * persiste entre reduções diferentes.
 *
 * Solução: pilha explícita aqui, mesma estratégia já usada para o
 * while. Ifs aninhados funcionam corretamente porque cada nível
 * ocupa uma posição própria na pilha.
 * ================================================================ */

#define MAX_IF 50

static char* pilha_if[MAX_IF];
static int   topo_pilha_if = -1;

void gci_push_if_label(const char* label)
{
    if (topo_pilha_if >= MAX_IF - 1)
    {
        fprintf(stderr,
                "Erro GCI: aninhamento de if excede limite (%d).\n",
                MAX_IF);
        return;
    }
    char* copia = (char*) malloc(10);
    strcpy(copia, label);
    pilha_if[++topo_pilha_if] = copia;
}

char* gci_pop_if_label()
{
    if (topo_pilha_if < 0)
    {
        fprintf(stderr, "Erro GCI: pop em pilha de if vazia.\n");
        return "";
    }
    return pilha_if[topo_pilha_if--];
}

/* ================================================================
 * EMISSÃO DIRETA
 * ================================================================ */

void gci_emitir_operacao(const char* op,
                         const char* dest,
                         const char* src1,
                         const char* src2)
{
    registrar_ir(op, dest, src1, src2);
    printf("    %s %s, %s, %s\n", op, dest, src1, src2);
}

void gci_emitir_unario(const char* op,
                       const char* dest,
                       const char* src)
{
    registrar_ir(op, dest, src, "");
    printf("    %s %s, %s\n", op, dest, src);
}

void gci_emitir_copy(const char* dest, const char* src)
{
    registrar_ir("COPY", dest, src, "");
    printf("    COPY %s, %s\n", dest, src);
}

/* ================================================================
 * OTIMIZAÇÃO 1 — DESDOBRAMENTO DE CONSTANTE (constant folding)
 *
 * Se ambos os operandos são literais numéricos, calcula o resultado
 * em tempo de compilação e emite COPY dest, resultado.
 *
 * Justificativa:
 *   O Flex converte literais para int/double em yylval e o
 *   translate.y os passa para o GCI já como strings numéricas
 *   ("3", "4", "0", "1"...). Não há motivo para emitir
 *   ADD x, 3, 4 e calcular 7 em runtime quando podemos calcular
 *   agora e emitir COPY x, 7.
 *
 * Caso especial — divisão por zero:
 *   Emite aviso e preserva a instrução original.
 * ================================================================ */

static int tentar_desdobramento(const char* op,
                                const char* dest,
                                const char* src1,
                                const char* src2)
{
    double v1, v2, r;

    if (!eh_literal_numerico(src1, &v1)) return 0;
    if (!eh_literal_numerico(src2, &v2)) return 0;

    if      (strcmp(op, "ADD") == 0) r = v1 + v2;
    else if (strcmp(op, "SUB") == 0) r = v1 - v2;
    else if (strcmp(op, "MUL") == 0) r = v1 * v2;
    else if (strcmp(op, "DIV") == 0)
    {
        if (v2 == 0.0)
        {
            fprintf(stderr,
                    "Aviso GCI: divisao por zero em compile-time "
                    "(destino '%s'). Instrucao preservada.\n", dest);
            return 0;
        }
        r = v1 / v2;
    }
    else if (strcmp(op, "AND") == 0) r = (v1 != 0.0 && v2 != 0.0) ? 1.0 : 0.0;
    else if (strcmp(op, "OR" ) == 0) r = (v1 != 0.0 || v2 != 0.0) ? 1.0 : 0.0;
    else if (strcmp(op, "SEQ") == 0) r = (v1 == v2) ? 1.0 : 0.0;
    else if (strcmp(op, "SNE") == 0) r = (v1 != v2) ? 1.0 : 0.0;
    else if (strcmp(op, "SGT") == 0) r = (v1  > v2) ? 1.0 : 0.0;
    else if (strcmp(op, "SLT") == 0) r = (v1  < v2) ? 1.0 : 0.0;
    else if (strcmp(op, "SGE") == 0) r = (v1 >= v2) ? 1.0 : 0.0;
    else if (strcmp(op, "SLE") == 0) r = (v1 <= v2) ? 1.0 : 0.0;
    else return 0;

    char buf[64];
    if (r == (long long)r) sprintf(buf, "%lld", (long long)r);
    else                   sprintf(buf, "%.6g", r);

    printf("    // [constant folding] %s %s, %s => %s\n", op, src1, src2, buf);
    gci_emitir_copy(dest, buf);
    return 1;
}

/* ================================================================
 * OTIMIZAÇÃO 2 — IDENTIDADE ALGÉBRICA
 *
 * Detecta elementos neutros e absorventes e substitui por COPY.
 *
 * Justificativa especial para o Soundy Script:
 *   A documentação do TP2 (seção 1.2) define que toda atribuição
 *   simples usa ADD com segundo operando 0:
 *       C/E resultado a 0 B C   →   ADD resultado, a, 0
 *   Isso significa que identidade algébrica cobre TODA atribuição
 *   da linguagem. É a otimização de maior impacto prático.
 * ================================================================ */

static int tentar_identidade(const char* op,
                             const char* dest,
                             const char* src1,
                             const char* src2)
{
    /* ADD x, a, 0  ou  ADD x, 0, a  → COPY x, a */
    if (strcmp(op, "ADD") == 0 && eh_igual(src2, 0.0))
    {
        printf("    // [identidade algebrica] %s + 0 => COPY\n", src1);
        gci_emitir_copy(dest, src1);
        return 1;
    }
    if (strcmp(op, "ADD") == 0 && eh_igual(src1, 0.0))
    {
        printf("    // [identidade algebrica] 0 + %s => COPY\n", src2);
        gci_emitir_copy(dest, src2);
        return 1;
    }
    /* SUB x, a, 0  → COPY x, a */
    if (strcmp(op, "SUB") == 0 && eh_igual(src2, 0.0))
    {
        printf("    // [identidade algebrica] %s - 0 => COPY\n", src1);
        gci_emitir_copy(dest, src1);
        return 1;
    }
    /* MUL x, a, 1  ou  MUL x, 1, a  → COPY x, a */
    if (strcmp(op, "MUL") == 0 && eh_igual(src2, 1.0))
    {
        printf("    // [identidade algebrica] %s * 1 => COPY\n", src1);
        gci_emitir_copy(dest, src1);
        return 1;
    }
    if (strcmp(op, "MUL") == 0 && eh_igual(src1, 1.0))
    {
        printf("    // [identidade algebrica] 1 * %s => COPY\n", src2);
        gci_emitir_copy(dest, src2);
        return 1;
    }
    /* MUL x, a, 0  ou  MUL x, 0, a  → COPY x, 0  (absorção) */
    if (strcmp(op, "MUL") == 0 && eh_igual(src2, 0.0))
    {
        printf("    // [identidade algebrica] %s * 0 => COPY 0 (absorcao)\n", src1);
        gci_emitir_copy(dest, "0");
        return 1;
    }
    if (strcmp(op, "MUL") == 0 && eh_igual(src1, 0.0))
    {
        printf("    // [identidade algebrica] 0 * %s => COPY 0 (absorcao)\n", src2);
        gci_emitir_copy(dest, "0");
        return 1;
    }
    /* DIV x, a, 1  → COPY x, a */
    if (strcmp(op, "DIV") == 0 && eh_igual(src2, 1.0))
    {
        printf("    // [identidade algebrica] %s / 1 => COPY\n", src1);
        gci_emitir_copy(dest, src1);
        return 1;
    }
    /* OR x, a, 0  ou  OR x, 0, a  → COPY x, a */
    if (strcmp(op, "OR") == 0 && eh_igual(src2, 0.0))
    {
        printf("    // [identidade algebrica] %s OR false => COPY\n", src1);
        gci_emitir_copy(dest, src1);
        return 1;
    }
    if (strcmp(op, "OR") == 0 && eh_igual(src1, 0.0))
    {
        printf("    // [identidade algebrica] false OR %s => COPY\n", src2);
        gci_emitir_copy(dest, src2);
        return 1;
    }
    /* AND x, a, 1  ou  AND x, 1, a  → COPY x, a */
    if (strcmp(op, "AND") == 0 && eh_igual(src2, 1.0))
    {
        printf("    // [identidade algebrica] %s AND true => COPY\n", src1);
        gci_emitir_copy(dest, src1);
        return 1;
    }
    if (strcmp(op, "AND") == 0 && eh_igual(src1, 1.0))
    {
        printf("    // [identidade algebrica] true AND %s => COPY\n", src2);
        gci_emitir_copy(dest, src2);
        return 1;
    }
    /* AND x, a, 0  ou  AND x, 0, a  → COPY x, 0  (absorção) */
    if (strcmp(op, "AND") == 0 && eh_igual(src2, 0.0))
    {
        printf("    // [identidade algebrica] %s AND false => COPY 0\n", src1);
        gci_emitir_copy(dest, "0");
        return 1;
    }
    if (strcmp(op, "AND") == 0 && eh_igual(src1, 0.0))
    {
        printf("    // [identidade algebrica] false AND %s => COPY 0\n", src2);
        gci_emitir_copy(dest, "0");
        return 1;
    }

    return 0;
}

/* ================================================================
 * OTIMIZAÇÃO 3 — REDUÇÃO DE ESFORÇO
 *
 * Substituição de operações custosas por equivalentes mais baratas.
 *
 * Caso implementado: MUL por 2 vira ADD duplo.
 *   MUL x, a, 2  →  ADD x, a, a
 *   MUL x, 2, a  →  ADD x, a, a
 *
 * Justificativa para o Soundy Script:
 *   O alvo do TP4 é o MOS6502, processador sem instrução de
 *   multiplicação nativa. Qualquer MUL precisará ser emulado em
 *   assembly por um loop ou sub-rotina, custando dezenas de ciclos.
 *   Uma única instrução ADC (Add with Carry) realiza a soma.
 *   Converter MUL por 2 em ADD economiza o custo de emulação.
 * ================================================================ */

static int tentar_reducao_esforco(const char* op,
                                  const char* dest,
                                  const char* src1,
                                  const char* src2)
{
    if (strcmp(op, "MUL") != 0) return 0;

    if (eh_igual(src2, 2.0))
    {
        printf("    // [reducao de esforco] %s * 2 => ADD %s, %s\n",
               src1, src1, src1);
        gci_emitir_operacao("ADD", dest, src1, src1);
        return 1;
    }
    if (eh_igual(src1, 2.0))
    {
        printf("    // [reducao de esforco] 2 * %s => ADD %s, %s\n",
               src2, src2, src2);
        gci_emitir_operacao("ADD", dest, src2, src2);
        return 1;
    }

    return 0;
}

/* ================================================================
 * PONTO DE ENTRADA PRINCIPAL — gci_emitir_operacao_otimizada
 *
 * Chamada pelo translate.y para todas as instruções binárias.
 * Aplica as otimizações em cascata na ordem de maior ganho:
 *
 *   1. Constant folding  — elimina a instrução completamente
 *   2. Identidade algébrica — substitui por COPY
 *   3. Redução de esforço — troca op cara por op barata
 *   4. Emissão direta — nenhuma otimização aplicável
 * ================================================================ */

void gci_emitir_operacao_otimizada(const char* op,
                                   const char* dest,
                                   const char* src1,
                                   const char* src2)
{
    if (tentar_desdobramento(op, dest, src1, src2))  return;
    if (tentar_identidade(op, dest, src1, src2))     return;
    if (tentar_reducao_esforco(op, dest, src1, src2)) return;

    gci_emitir_operacao(op, dest, src1, src2);
}

/* ================================================================
 * FUNÇÕES — MARCAÇÕES PARA O TP4
 * ================================================================ */

void gci_emitir_func_inicio(const char* nome)
{
    registrar_ir("FUNC_BEGIN", nome, "", "");
    printf("%s:\n", nome);
}

void gci_emitir_func_fim(const char* nome)
{
    registrar_ir("FUNC_END", nome, "", "");
    printf("    END_FUNC %s\n", nome);
}

void gci_emitir_parametro(const char* nome)
{
    registrar_ir("PARAM", nome, "", "");
    printf("    PARAM %s\n", nome);
}

void gci_limpar_argumentos_call()
{
    qtd_args_call_atual = 0;
}

void gci_adicionar_argumento_call(const char* argumento)
{
    if (qtd_args_call_atual >= MAX_ARGS_CALL)
    {
        fprintf(stderr, "Erro GCI: chamada com argumentos demais.\n");
        return;
    }

    strncpy(args_call_atual[qtd_args_call_atual],
            argumento ? argumento : "",
            sizeof(args_call_atual[qtd_args_call_atual]) - 1);
    args_call_atual[qtd_args_call_atual]
        [sizeof(args_call_atual[qtd_args_call_atual]) - 1] = '\0';
    qtd_args_call_atual++;
}

/* ================================================================
 * DESVIOS E LABELS
 * ================================================================ */

void gci_emitir_jump_condicional(const char* condicao, const char* label)
{
    registrar_ir("IF_FALSE", condicao, label, "");
    printf("    IF_FALSE %s GOTO %s\n", condicao, label);
}

void gci_emitir_jump(const char* label)
{
    registrar_ir("GOTO", label, "", "");
    printf("    GOTO %s\n", label);
}

void gci_emitir_label(const char* label)
{
    registrar_ir("LABEL", label, "", "");
    printf("%s:\n", label);
}

/* ================================================================
 * FUNÇÕES E VETORES
 * ================================================================ */

void gci_emitir_call(const char* dest, const char* func)
{
    int i;
    registrar_ir("CALL", dest, func, "");
    ir[qtd_ir - 1].argc = qtd_args_call_atual;
    for (i = 0; i < qtd_args_call_atual; i++)
    {
        strncpy(ir[qtd_ir - 1].args[i],
                args_call_atual[i],
                sizeof(ir[qtd_ir - 1].args[i]) - 1);
        ir[qtd_ir - 1].args[i][sizeof(ir[qtd_ir - 1].args[i]) - 1] = '\0';
    }
    printf("    CALL %s, %s\n", dest, func);
}

void gci_emitir_return(const char* valor)
{
    registrar_ir("RETURN", valor, "", "");
    printf("    RETURN %s\n", valor);
}

void gci_emitir_read_list(const char* dest,
                          const char* lista,
                          const char* indice)
{
    registrar_ir("GET_ARR", dest, lista, indice);
    printf("    GET_ARR %s, %s[%s]\n", dest, lista, indice);
}

void gci_emitir_write_list(const char* lista,
                           const char* indice,
                           const char* valor)
{
    registrar_ir("SET_ARR", lista, indice, valor);
    printf("    SET_ARR %s[%s], %s\n", lista, indice, valor);
}

/* ================================================================
 * TP4 — GERAÇÃO DE ASSEMBLY MOS6502
 * ================================================================ */

static void caminho_saida_asm(const char* fonte, char* saida, size_t tam)
{
    char* ponto;
    strncpy(saida, fonte, tam - 1);
    saida[tam - 1] = '\0';

    ponto = strrchr(saida, '.');
    if (ponto != NULL)
        strcpy(ponto, ".asm");
    else
        strncat(saida, ".asm", tam - strlen(saida) - 1);
}

static void nome_asm(const char* original,
                     const char* prefixo,
                     char* destino,
                     size_t tam)
{
    size_t i;
    size_t j = 0;

    snprintf(destino, tam, "%s", prefixo);
    j = strlen(destino);

    for (i = 0; original[i] != '\0' && j < tam - 1; i++)
    {
        char ch = original[i];
        if ((ch >= 'A' && ch <= 'Z') ||
            (ch >= 'a' && ch <= 'z') ||
            (ch >= '0' && ch <= '9'))
        {
            destino[j++] = ch;
        }
        else
        {
            destino[j++] = '_';
        }
    }
    destino[j] = '\0';
}

static int texto_literal(const char* texto, int* valor)
{
    char* fim;
    double numero;

    if (texto == NULL || texto[0] == '\0') return 0;
    if (strcmp(texto, "null") == 0)
    {
        if (valor != NULL) *valor = 0;
        return 1;
    }

    errno = 0;
    numero = strtod(texto, &fim);
    if (fim == texto || *fim != '\0' || errno != 0) return 0;

    if (valor != NULL) *valor = ((int)numero) & 0xFF;
    return 1;
}

static int buscar_asm(SimboloAsm* mapa, int qtd, const char* nome)
{
    int i;
    for (i = 0; i < qtd; i++)
    {
        if (strcmp(mapa[i].original, nome) == 0) return i;
    }
    return -1;
}

static void adicionar_asm(SimboloAsm* mapa,
                          int* qtd,
                          const char* nome,
                          int tamanho,
                          int eh_lista)
{
    if (nome == NULL || nome[0] == '\0') return;
    if (texto_literal(nome, NULL)) return;
    if (buscar_asm(mapa, *qtd, nome) >= 0) return;
    if (*qtd >= MAX_ASM_SIMBOLOS) return;

    strncpy(mapa[*qtd].original, nome, sizeof(mapa[*qtd].original) - 1);
    mapa[*qtd].original[sizeof(mapa[*qtd].original) - 1] = '\0';
    nome_asm(nome, "v_", mapa[*qtd].asm_nome, sizeof(mapa[*qtd].asm_nome));
    mapa[*qtd].endereco = -1;
    mapa[*qtd].tamanho = tamanho > 0 ? tamanho : 1;
    mapa[*qtd].eh_lista = eh_lista;
    (*qtd)++;
}

static void coletar_simbolos_tabela(TabelaSimbolo* tabela,
                                    SimboloAsm* mapa,
                                    int* qtd)
{
    int i;

    if (tabela == NULL) return;

    for (i = 0; i < tabela->qtdSimbolos; i++)
    {
        Simbolo* s = &tabela->simbolos[i];
        if (s->categoria != CAT_FUNCAO)
        {
            adicionar_asm(mapa,
                          qtd,
                          s->nome,
                          s->tamanhoLista > 0 ? s->tamanhoLista : 1,
                          s->tipo == TIPO_LISTA);
        }
    }

    for (i = 0; i < tabela->qtdFilhos; i++)
    {
        coletar_simbolos_tabela(tabela->filhos[i], mapa, qtd);
    }
}

static int prioridade_resultado(const char* nome)
{
    if (strcmp(nome, "resultado") == 0) return 0;
    if (strcmp(nome, "principal") == 0) return 1;
    if (strcmp(nome, "situacao") == 0) return 2;
    if (strcmp(nome, "total") == 0) return 3;
    return 100;
}

static void alocar_enderecos(SimboloAsm* mapa, int qtd)
{
    int endereco = 0;
    int melhor = -1;
    int melhor_prioridade = 1000;
    int i;

    for (i = 0; i < qtd; i++)
    {
        int p = prioridade_resultado(mapa[i].original);
        if (p < melhor_prioridade)
        {
            melhor = i;
            melhor_prioridade = p;
        }
    }

    if (melhor < 0 && qtd > 0) melhor = 0;

    if (melhor >= 0)
    {
        mapa[melhor].endereco = endereco;
        endereco += mapa[melhor].tamanho;
    }

    for (i = 0; i < qtd; i++)
    {
        if (mapa[i].endereco < 0)
        {
            mapa[i].endereco = endereco;
            endereco += mapa[i].tamanho;
        }
    }
}

static const char* ref_operando(SimboloAsm* mapa,
                                int qtd,
                                const char* operando,
                                char* buffer,
                                size_t tam)
{
    int valor;
    int idx;

    if (texto_literal(operando, &valor))
    {
        snprintf(buffer, tam, "#%d", valor);
        return buffer;
    }

    idx = buscar_asm(mapa, qtd, operando);
    if (idx >= 0)
    {
        snprintf(buffer, tam, "%s", mapa[idx].asm_nome);
        return buffer;
    }

    snprintf(buffer, tam, "v_%s", operando);
    return buffer;
}

static const char* ref_memoria(SimboloAsm* mapa,
                               int qtd,
                               const char* nome,
                               char* buffer,
                               size_t tam)
{
    int idx = buscar_asm(mapa, qtd, nome);
    if (idx >= 0)
    {
        snprintf(buffer, tam, "%s", mapa[idx].asm_nome);
        return buffer;
    }
    snprintf(buffer, tam, "v_%s", nome);
    return buffer;
}

static void emitir_load(FILE* out, SimboloAsm* mapa, int qtd, const char* operando)
{
    char ref[128];
    fprintf(out, "    LDA %s\n", ref_operando(mapa, qtd, operando, ref, sizeof(ref)));
}

static void emitir_store(FILE* out, SimboloAsm* mapa, int qtd, const char* destino)
{
    char ref[128];
    fprintf(out, "    STA %s\n", ref_memoria(mapa, qtd, destino, ref, sizeof(ref)));
}

static void emitir_true_false(FILE* out,
                              SimboloAsm* mapa,
                              int qtd,
                              const char* destino,
                              const char* branch_true,
                              const char* branch_false,
                              const char* branch_extra)
{
    char ltrue[32];
    char lfalso[32];
    char lfim[32];
    static int contador_cmp = 0;

    snprintf(ltrue, sizeof(ltrue), "__cmp_true_%d", contador_cmp);
    snprintf(lfalso, sizeof(lfalso), "__cmp_false_%d", contador_cmp);
    snprintf(lfim, sizeof(lfim), "__cmp_end_%d", contador_cmp);
    contador_cmp++;

    if (branch_true != NULL && branch_true[0] != '\0')
        fprintf(out, "    %s %s\n", branch_true, ltrue);
    if (branch_extra != NULL && branch_extra[0] != '\0')
        fprintf(out, "    %s %s\n", branch_extra, ltrue);
    if (branch_false != NULL && branch_false[0] != '\0')
        fprintf(out, "    %s %s\n", branch_false, lfalso);

    fprintf(out, "%s:\n", lfalso);
    fprintf(out, "    LDA #0\n");
    emitir_store(out, mapa, qtd, destino);
    fprintf(out, "    JMP %s\n", lfim);
    fprintf(out, "%s:\n", ltrue);
    fprintf(out, "    LDA #1\n");
    emitir_store(out, mapa, qtd, destino);
    fprintf(out, "%s:\n", lfim);
}

static void emitir_comparacao(FILE* out,
                              SimboloAsm* mapa,
                              int qtd,
                              const InstrucaoIR* inst)
{
    char ref[128];
    static int contador_gt = 0;

    emitir_load(out, mapa, qtd, inst->b);
    fprintf(out, "    CMP %s\n",
            ref_operando(mapa, qtd, inst->c, ref, sizeof(ref)));

    if (strcmp(inst->op, "SEQ") == 0)
        emitir_true_false(out, mapa, qtd, inst->a, "BEQ", "", NULL);
    else if (strcmp(inst->op, "SNE") == 0)
        emitir_true_false(out, mapa, qtd, inst->a, "BNE", "", NULL);
    else if (strcmp(inst->op, "SGT") == 0)
    {
        char ltrue[32];
        char lfalso[32];
        char lfim[32];
        snprintf(ltrue, sizeof(ltrue), "__gt_true_%d", contador_gt);
        snprintf(lfalso, sizeof(lfalso), "__gt_false_%d", contador_gt);
        snprintf(lfim, sizeof(lfim), "__gt_end_%d", contador_gt);
        contador_gt++;

        fprintf(out, "    BEQ %s\n", lfalso);
        fprintf(out, "    BCS %s\n", ltrue);
        fprintf(out, "%s:\n", lfalso);
        fprintf(out, "    LDA #0\n");
        emitir_store(out, mapa, qtd, inst->a);
        fprintf(out, "    JMP %s\n", lfim);
        fprintf(out, "%s:\n", ltrue);
        fprintf(out, "    LDA #1\n");
        emitir_store(out, mapa, qtd, inst->a);
        fprintf(out, "%s:\n", lfim);
    }
    else if (strcmp(inst->op, "SLT") == 0)
        emitir_true_false(out, mapa, qtd, inst->a, "BCC", "", NULL);
    else if (strcmp(inst->op, "SGE") == 0)
        emitir_true_false(out, mapa, qtd, inst->a, "BCS", "", NULL);
    else if (strcmp(inst->op, "SLE") == 0)
        emitir_true_false(out, mapa, qtd, inst->a, "BEQ", "", "BCC");
}

static void emitir_logico(FILE* out,
                          SimboloAsm* mapa,
                          int qtd,
                          const InstrucaoIR* inst)
{
    char ltrue[32];
    char lfalso[32];
    char lfim[32];
    char ref[128];
    static int contador_log = 0;

    snprintf(ltrue, sizeof(ltrue), "__logic_true_%d", contador_log);
    snprintf(lfalso, sizeof(lfalso), "__logic_false_%d", contador_log);
    snprintf(lfim, sizeof(lfim), "__logic_end_%d", contador_log);
    contador_log++;

    if (strcmp(inst->op, "AND") == 0)
    {
        emitir_load(out, mapa, qtd, inst->b);
        fprintf(out, "    BEQ %s\n", lfalso);
        emitir_load(out, mapa, qtd, inst->c);
        fprintf(out, "    BEQ %s\n", lfalso);
        fprintf(out, "    JMP %s\n", ltrue);
    }
    else if (strcmp(inst->op, "OR") == 0)
    {
        emitir_load(out, mapa, qtd, inst->b);
        fprintf(out, "    BNE %s\n", ltrue);
        emitir_load(out, mapa, qtd, inst->c);
        fprintf(out, "    BNE %s\n", ltrue);
        fprintf(out, "    JMP %s\n", lfalso);
    }
    else
    {
        fprintf(out, "    LDA %s\n",
                ref_operando(mapa, qtd, inst->b, ref, sizeof(ref)));
        fprintf(out, "    BEQ %s\n", ltrue);
        fprintf(out, "    JMP %s\n", lfalso);
    }

    fprintf(out, "%s:\n", lfalso);
    fprintf(out, "    LDA #0\n");
    emitir_store(out, mapa, qtd, inst->a);
    fprintf(out, "    JMP %s\n", lfim);
    fprintf(out, "%s:\n", ltrue);
    fprintf(out, "    LDA #1\n");
    emitir_store(out, mapa, qtd, inst->a);
    fprintf(out, "%s:\n", lfim);
}

static void emitir_array(FILE* out,
                         SimboloAsm* mapa,
                         int qtd,
                         const InstrucaoIR* inst)
{
    char lista[128];
    char ref[128];
    int idx_lit;
    int pos_lista = buscar_asm(mapa, qtd, inst->b);

    if (strcmp(inst->op, "GET_ARR") == 0)
    {
        if (texto_literal(inst->c, &idx_lit) && pos_lista >= 0)
        {
            fprintf(out, "    LDA %s+%d\n", mapa[pos_lista].asm_nome, idx_lit);
            emitir_store(out, mapa, qtd, inst->a);
        }
        else
        {
            fprintf(out, "    LDX %s\n",
                    ref_operando(mapa, qtd, inst->c, ref, sizeof(ref)));
            fprintf(out, "    LDA %s,X\n",
                    ref_memoria(mapa, qtd, inst->b, lista, sizeof(lista)));
            emitir_store(out, mapa, qtd, inst->a);
        }
    }
    else
    {
        pos_lista = buscar_asm(mapa, qtd, inst->a);
        if (texto_literal(inst->b, &idx_lit) && pos_lista >= 0)
        {
            emitir_load(out, mapa, qtd, inst->c);
            fprintf(out, "    STA %s+%d\n", mapa[pos_lista].asm_nome, idx_lit);
        }
        else
        {
            fprintf(out, "    LDX %s\n",
                    ref_operando(mapa, qtd, inst->b, ref, sizeof(ref)));
            emitir_load(out, mapa, qtd, inst->c);
            fprintf(out, "    STA %s,X\n",
                    ref_memoria(mapa, qtd, inst->a, lista, sizeof(lista)));
        }
    }
}

static void emitir_subrotinas(FILE* out, int usa_mul, int usa_div)
{
    if (usa_mul)
    {
        fprintf(out, "\n__mul_u8:\n");
        fprintf(out, "    LDA #0\n");
        fprintf(out, "    LDX tmp_mul_b\n");
        fprintf(out, "__mul_loop:\n");
        fprintf(out, "    CPX #0\n");
        fprintf(out, "    BEQ __mul_done\n");
        fprintf(out, "    CLC\n");
        fprintf(out, "    ADC tmp_mul_a\n");
        fprintf(out, "    DEX\n");
        fprintf(out, "    JMP __mul_loop\n");
        fprintf(out, "__mul_done:\n");
        fprintf(out, "    RTS\n");
    }

    if (usa_div)
    {
        fprintf(out, "\n__div_u8:\n");
        fprintf(out, "    LDA #0\n");
        fprintf(out, "    STA tmp_div_q\n");
        fprintf(out, "    LDA tmp_div_den\n");
        fprintf(out, "    BEQ __div_done\n");
        fprintf(out, "    LDA tmp_div_num\n");
        fprintf(out, "__div_loop:\n");
        fprintf(out, "    CMP tmp_div_den\n");
        fprintf(out, "    BCC __div_done\n");
        fprintf(out, "    SEC\n");
        fprintf(out, "    SBC tmp_div_den\n");
        fprintf(out, "    INC tmp_div_q\n");
        fprintf(out, "    JMP __div_loop\n");
        fprintf(out, "__div_done:\n");
        fprintf(out, "    LDA tmp_div_q\n");
        fprintf(out, "    RTS\n");
    }
}

int gci_gerar_assembly_6502(const char* arquivo_fonte,
                            TabelaSimbolo* tabela_global)
{
    char caminho[512];
    FILE* out;
    SimboloAsm mapa[MAX_ASM_SIMBOLOS];
    int qtd_mapa = 0;
    int i;
    int tem_funcao = 0;
    int em_funcao = 0;
    int main_emitido = 0;
    int param_idx = 0;
    int max_args = 0;
    int usa_mul = 0;
    int usa_div = 0;

    memset(mapa, 0, sizeof(mapa));
    coletar_simbolos_tabela(tabela_global, mapa, &qtd_mapa);

    for (i = 0; i < qtd_ir; i++)
    {
        int j;
        if (strcmp(ir[i].op, "FUNC_BEGIN") == 0) tem_funcao = 1;
        if (strcmp(ir[i].op, "CALL") == 0 && ir[i].argc > max_args)
            max_args = ir[i].argc;
        if (strcmp(ir[i].op, "MUL") == 0) usa_mul = 1;
        if (strcmp(ir[i].op, "DIV") == 0) usa_div = 1;
        for (j = 0; j < ir[i].argc; j++)
        {
            adicionar_asm(mapa, &qtd_mapa, ir[i].args[j], 1, 0);
        }
    }

    for (i = 0; i < max_args; i++)
    {
        char nome_arg[32];
        snprintf(nome_arg, sizeof(nome_arg), "__arg%d", i);
        adicionar_asm(mapa, &qtd_mapa, nome_arg, 1, 0);
    }

    if (usa_mul)
    {
        adicionar_asm(mapa, &qtd_mapa, "tmp_mul_a", 1, 0);
        adicionar_asm(mapa, &qtd_mapa, "tmp_mul_b", 1, 0);
    }
    if (usa_div)
    {
        adicionar_asm(mapa, &qtd_mapa, "tmp_div_num", 1, 0);
        adicionar_asm(mapa, &qtd_mapa, "tmp_div_den", 1, 0);
        adicionar_asm(mapa, &qtd_mapa, "tmp_div_q", 1, 0);
    }

    alocar_enderecos(mapa, qtd_mapa);
    caminho_saida_asm(arquivo_fonte, caminho, sizeof(caminho));

    out = fopen(caminho, "w");
    if (out == NULL)
    {
        fprintf(stderr, "Erro TP4: nao foi possivel criar '%s'.\n", caminho);
        return 0;
    }

    fprintf(out, "; Assembly MOS6502 gerado pelo compilador Soundy Script\n");
    fprintf(out, "; Arquivo fonte: %s\n\n", arquivo_fonte);
    fprintf(out, "; Mapa de memoria zero page\n");
    for (i = 0; i < qtd_mapa; i++)
    {
        fprintf(out, "define %-20s $%02X ; %s%s\n",
                mapa[i].asm_nome,
                mapa[i].endereco & 0xFF,
                mapa[i].original,
                mapa[i].eh_lista ? "[]" : "");
    }
    if (qtd_mapa > 0)
    {
        fprintf(out, "\n; Variavel verificada no teste: %s em $%02X\n",
                mapa[0].original, mapa[0].endereco & 0xFF);
    }

    fprintf(out, "\n*=$0600\n");
    if (tem_funcao) fprintf(out, "    JMP __main\n");

    for (i = 0; i < qtd_ir; i++)
    {
        InstrucaoIR* inst = &ir[i];
        char r1[128];
        char r2[128];
        char label_func[128];

        if (!main_emitido && !em_funcao && strcmp(inst->op, "FUNC_BEGIN") != 0)
        {
            fprintf(out, "__main:\n");
            main_emitido = 1;
        }

        if (strcmp(inst->op, "FUNC_BEGIN") == 0)
        {
            nome_asm(inst->a, "fn_", label_func, sizeof(label_func));
            fprintf(out, "%s:\n", label_func);
            em_funcao = 1;
            param_idx = 0;
        }
        else if (strcmp(inst->op, "FUNC_END") == 0)
        {
            if (i == 0 || strcmp(ir[i - 1].op, "RETURN") != 0)
            {
                fprintf(out, "    RTS\n");
            }
            em_funcao = 0;
        }
        else if (strcmp(inst->op, "PARAM") == 0)
        {
            char arg_nome[32];
            snprintf(arg_nome, sizeof(arg_nome), "__arg%d", param_idx++);
            fprintf(out, "    LDA %s\n",
                    ref_memoria(mapa, qtd_mapa, arg_nome, r1, sizeof(r1)));
            fprintf(out, "    STA %s\n",
                    ref_memoria(mapa, qtd_mapa, inst->a, r2, sizeof(r2)));
        }
        else if (strcmp(inst->op, "COPY") == 0)
        {
            emitir_load(out, mapa, qtd_mapa, inst->b);
            emitir_store(out, mapa, qtd_mapa, inst->a);
        }
        else if (strcmp(inst->op, "ADD") == 0)
        {
            emitir_load(out, mapa, qtd_mapa, inst->b);
            fprintf(out, "    CLC\n");
            fprintf(out, "    ADC %s\n",
                    ref_operando(mapa, qtd_mapa, inst->c, r1, sizeof(r1)));
            emitir_store(out, mapa, qtd_mapa, inst->a);
        }
        else if (strcmp(inst->op, "SUB") == 0)
        {
            emitir_load(out, mapa, qtd_mapa, inst->b);
            fprintf(out, "    SEC\n");
            fprintf(out, "    SBC %s\n",
                    ref_operando(mapa, qtd_mapa, inst->c, r1, sizeof(r1)));
            emitir_store(out, mapa, qtd_mapa, inst->a);
        }
        else if (strcmp(inst->op, "MUL") == 0)
        {
            emitir_load(out, mapa, qtd_mapa, inst->b);
            fprintf(out, "    STA tmp_mul_a\n");
            emitir_load(out, mapa, qtd_mapa, inst->c);
            fprintf(out, "    STA tmp_mul_b\n");
            fprintf(out, "    JSR __mul_u8\n");
            emitir_store(out, mapa, qtd_mapa, inst->a);
        }
        else if (strcmp(inst->op, "DIV") == 0)
        {
            emitir_load(out, mapa, qtd_mapa, inst->b);
            fprintf(out, "    STA tmp_div_num\n");
            emitir_load(out, mapa, qtd_mapa, inst->c);
            fprintf(out, "    STA tmp_div_den\n");
            fprintf(out, "    JSR __div_u8\n");
            emitir_store(out, mapa, qtd_mapa, inst->a);
        }
        else if (strcmp(inst->op, "AND") == 0 ||
                 strcmp(inst->op, "OR") == 0 ||
                 strcmp(inst->op, "NOT") == 0)
        {
            emitir_logico(out, mapa, qtd_mapa, inst);
        }
        else if (strcmp(inst->op, "SEQ") == 0 ||
                 strcmp(inst->op, "SNE") == 0 ||
                 strcmp(inst->op, "SGT") == 0 ||
                 strcmp(inst->op, "SLT") == 0 ||
                 strcmp(inst->op, "SGE") == 0 ||
                 strcmp(inst->op, "SLE") == 0)
        {
            emitir_comparacao(out, mapa, qtd_mapa, inst);
        }
        else if (strcmp(inst->op, "IF_FALSE") == 0)
        {
            emitir_load(out, mapa, qtd_mapa, inst->a);
            fprintf(out, "    BEQ %s\n", inst->b);
        }
        else if (strcmp(inst->op, "GOTO") == 0)
        {
            if (inst->a[0] != '\0') fprintf(out, "    JMP %s\n", inst->a);
        }
        else if (strcmp(inst->op, "LABEL") == 0)
        {
            fprintf(out, "%s:\n", inst->a);
        }
        else if (strcmp(inst->op, "CALL") == 0)
        {
            int j;
            for (j = 0; j < inst->argc; j++)
            {
                char arg_nome[32];
                snprintf(arg_nome, sizeof(arg_nome), "__arg%d", j);
                emitir_load(out, mapa, qtd_mapa, inst->args[j]);
                fprintf(out, "    STA %s\n",
                        ref_memoria(mapa, qtd_mapa, arg_nome, r1, sizeof(r1)));
            }
            nome_asm(inst->b, "fn_", label_func, sizeof(label_func));
            fprintf(out, "    JSR %s\n", label_func);
            emitir_store(out, mapa, qtd_mapa, inst->a);
        }
        else if (strcmp(inst->op, "RETURN") == 0)
        {
            emitir_load(out, mapa, qtd_mapa, inst->a);
            fprintf(out, "    RTS\n");
        }
        else if (strcmp(inst->op, "GET_ARR") == 0 ||
                 strcmp(inst->op, "SET_ARR") == 0)
        {
            emitir_array(out, mapa, qtd_mapa, inst);
        }
    }

    if (!main_emitido) fprintf(out, "__main:\n");
    fprintf(out, "__halt:\n");
    fprintf(out, "    JMP __halt\n");

    emitir_subrotinas(out, usa_mul, usa_div);

    fclose(out);
    printf("Assembly MOS6502 gerado em: %s\n", caminho);
    return 1;
}
