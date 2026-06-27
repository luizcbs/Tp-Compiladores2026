#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "gci.h"

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
char* gci_get_while_inicio() { return pilha_inicio_while[topo_pilha_while]; }
char* gci_get_while_fim()    { return pilha_fim_while[topo_pilha_while]; }

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
    printf("    %s %s, %s, %s\n", op, dest, src1, src2);
}

void gci_emitir_unario(const char* op,
                       const char* dest,
                       const char* src)
{
    printf("    %s %s, %s\n", op, dest, src);
}

void gci_emitir_copy(const char* dest, const char* src)
{
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
 * DESVIOS E LABELS
 * ================================================================ */

void gci_emitir_jump_condicional(const char* condicao, const char* label)
{
    printf("    IF_FALSE %s GOTO %s\n", condicao, label);
}

void gci_emitir_jump(const char* label)
{
    printf("    GOTO %s\n", label);
}

void gci_emitir_label(const char* label)
{
    printf("%s:\n", label);
}

/* ================================================================
 * FUNÇÕES E VETORES
 * ================================================================ */

void gci_emitir_call(const char* dest, const char* func)
{
    printf("    CALL %s, %s\n", dest, func);
}

void gci_emitir_return(const char* valor)
{
    printf("    RETURN %s\n", valor);
}

void gci_emitir_read_list(const char* dest,
                          const char* lista,
                          const char* indice)
{
    printf("    GET_ARR %s, %s[%s]\n", dest, lista, indice);
}

void gci_emitir_write_list(const char* lista,
                           const char* indice,
                           const char* valor)
{
    printf("    SET_ARR %s[%s], %s\n", lista, indice, valor);
}
