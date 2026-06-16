    #include <stdio.h>
#include <stdlib.h>
#include "gci.h"

static int contador_label = 0;
static char* pilha_inicio_while[20];
static char* pilha_fim_while[20];
static int topo_pilha_while = -1;

char* gci_nova_label() {
    char* label = (char*) malloc(10);
    sprintf(label, "L%d", contador_label++);
    return label;
}

void gci_push_while(char* inicio, char* fim) {
    topo_pilha_while++;
    pilha_inicio_while[topo_pilha_while] = inicio;
    pilha_fim_while[topo_pilha_while] = fim;
}

void gci_pop_while() { topo_pilha_while--; }

char* gci_get_while_inicio() { return pilha_inicio_while[topo_pilha_while]; }
char* gci_get_while_fim() { return pilha_fim_while[topo_pilha_while]; }

void gci_emitir_operacao(const char* op, const char* dest, const char* src1, const char* src2) {
    printf("    %s %s, %s, %s\n", op, dest, src1, src2);
}

void gci_emitir_unario(const char* op, const char* dest, const char* src) {
    printf("    %s %s, %s\n", op, dest, src);
}

void gci_emitir_jump_condicional(const char* condicao, const char* label) {
    printf("    IF_FALSE %s GOTO %s\n", condicao, label);
}

void gci_emitir_jump(const char* label) {
    printf("    GOTO %s\n", label);
}

void gci_emitir_label(const char* label) {
    printf("%s:\n", label);
}

/* --- Escopo Completo --- */

void gci_emitir_call(const char* dest, const char* func) {
    // Na arquitetura de 3 endereços, salvamos o retorno da func no dest
    printf("    CALL %s, %s\n", dest, func);
}

void gci_emitir_read_list(const char* dest, const char* lista, const char* indice) {
    printf("    GET_ARR %s, %s[%s]\n", dest, lista, indice);
}

void gci_emitir_write_list(const char* lista, const char* indice, const char* valor) {
    printf("    SET_ARR %s[%s], %s\n", lista, indice, valor);
}