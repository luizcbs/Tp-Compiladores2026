#ifndef TABELA_SIMBOLOS_H
#define TABELA_SIMBOLOS_H

#define MAX_SIMBOLOS 100
#define MAX_FILHOS 50

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef enum {
    TIPO_INT,
    TIPO_FLOAT,
    TIPO_BOOL,
    TIPO_CHAR,
    TIPO_NULL,
    TIPO_LISTA
} Tipo;

typedef enum {
    CAT_VARIAVEL,
    CAT_FUNCAO,
    CAT_PARAMETRO
} Categoria;

typedef struct {
    char nome[50];

    Tipo tipo;
    Categoria categoria;

    int linhaDeclaracao;

} Simbolo;

typedef struct tabelaSimbolo {

    char nome[50];

    struct tabelaSimbolo *pai;

    struct tabelaSimbolo *filhos[MAX_FILHOS];
    int qtdFilhos;

    Simbolo simbolos[MAX_SIMBOLOS];
    int qtdSimbolos;

} TabelaSimbolo;

TabelaSimbolo *criarTabelaSimbolo(char *nome, TabelaSimbolo *pai);
void adicionarFilho(TabelaSimbolo *pai, TabelaSimbolo *filho);

Simbolo criarSimbolo(char *nome, Tipo tipo, Categoria categoria, int linha);
int inserirSimbolo(TabelaSimbolo *tabela, Simbolo simbolo);

Simbolo *buscarNaTabelaSimboloAtual(TabelaSimbolo *tabela, char *nome);

void entrarTabalaSimbolo(TabelaSimbolo **tabelaAtual,TabelaSimbolo *novaTabela);
void sairTabelaSimbolo(TabelaSimbolo **tabelaAtual);

char *tipoParaString(Tipo tipo);
char *categoriaParaString(Categoria categoria);

void imprimirArvore(TabelaSimbolo *escopo, int nivel);

#endif