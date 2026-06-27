#ifndef GCI_H
#define GCI_H

/* ================================================================
 * gci.h — Gerador de Código Intermediário (GCI)
 * ================================================================
 *
 * Este módulo é responsável por emitir instruções de código
 * intermediário no formato de três endereços. Ele é chamado
 * pelas ações semânticas do translate.y no momento em que o
 * Bison reduz cada construção da linguagem.
 *
 * Além da emissão básica, o módulo implementa três otimizações
 * aplicadas em tempo de compilação, sem necessidade de buffer:
 *
 *   1. Desdobramento de constante (constant folding)
 *      Se os dois operandos são literais, o resultado é calculado
 *      em compile-time e emitido como COPY.
 *      Ex: ADD x, 3, 4  →  COPY x, 7
 *
 *   2. Identidade algébrica
 *      Operações com elementos neutros ou absorventes são
 *      substituídas por COPY.
 *      Ex: ADD x, a, 0  →  COPY x, a
 *      Ex: MUL x, a, 0  →  COPY x, 0
 *
 *   3. Redução de esforço
 *      Multiplicação por 2 é substituída por adição dupla,
 *      mais eficiente em arquiteturas sem instrução MUL nativa
 *      (como o MOS6502, alvo do TP4).
 *      Ex: MUL x, a, 2  →  ADD x, a, a
 *
 * As otimizações são aplicadas em cascata por
 * gci_emitir_operacao_otimizada(), ponto de entrada principal
 * para todas as instruções binárias do translate.y.
 * ================================================================ */

/* ---------------------------------------------------------------
 * Labels e pilhas de controle de fluxo
 * --------------------------------------------------------------- */

/* Gera um label único crescente: L0, L1, L2 ... */
char* gci_nova_label();

/* Pilha do while — permite break/continue em loops aninhados */
void  gci_push_while(char* inicio, char* fim);
void  gci_pop_while();
char* gci_get_while_inicio();
char* gci_get_while_fim();

/* Pilha do if — evita comportamento indefinido ao acessar
   labels entre ações semânticas separadas do Bison */
void  gci_push_if_label(const char* label);
char* gci_pop_if_label();

/* ---------------------------------------------------------------
 * Emissão com otimizações (ponto de entrada principal)
 * --------------------------------------------------------------- */

/* Aplica constant folding → identidade algébrica → redução de
   esforço → emissão direta, nessa ordem. */
void gci_emitir_operacao_otimizada(const char* op,
                                   const char* dest,
                                   const char* src1,
                                   const char* src2);

/* ---------------------------------------------------------------
 * Emissão direta (sem otimização)
 * --------------------------------------------------------------- */
void gci_emitir_operacao(const char* op,
                         const char* dest,
                         const char* src1,
                         const char* src2);

void gci_emitir_unario(const char* op,
                       const char* dest,
                       const char* src);

void gci_emitir_copy(const char* dest, const char* src);

/* ---------------------------------------------------------------
 * Desvios e labels
 * --------------------------------------------------------------- */
void gci_emitir_jump_condicional(const char* condicao,
                                 const char* label);
void gci_emitir_jump(const char* label);
void gci_emitir_label(const char* label);

/* ---------------------------------------------------------------
 * Funções e vetores
 * --------------------------------------------------------------- */
void gci_emitir_call(const char* dest, const char* func);
void gci_emitir_return(const char* valor);
void gci_emitir_read_list(const char* dest,
                          const char* lista,
                          const char* indice);
void gci_emitir_write_list(const char* lista,
                           const char* indice,
                           const char* valor);

#endif /* GCI_H */
