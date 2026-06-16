#ifndef GCI_H
#define GCI_H

// Funções para controle de fluxo (If, While, Else)
char* gci_nova_label();
void gci_push_while(char* inicio, char* fim);
void gci_pop_while();
char* gci_get_while_inicio();
char* gci_get_while_fim();

// Funções de emissão de código (Aritmética, Lógica e Relacional)
void gci_emitir_operacao(const char* op, const char* dest, const char* src1, const char* src2);
void gci_emitir_unario(const char* op, const char* dest, const char* src);

// Funções de emissão de desvios (Jumps)
void gci_emitir_jump_condicional(const char* condicao, const char* label);
void gci_emitir_jump(const char* label);
void gci_emitir_label(const char* label);

/* Funções e Vetores (Escopo Completo) */
void gci_emitir_call(const char* dest, const char* func);
void gci_emitir_read_list(const char* dest, const char* lista, const char* indice);
void gci_emitir_write_list(const char* lista, const char* indice, const char* valor);

#endif