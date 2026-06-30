%{
/*
 * Soundy Script -- Analisador Lexico (Trabalho Pratico 4)
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "../yacc/translate.tab.h"

%}

%option noyywrap

ws          [ \t]+
newline     \n
comment     "//"[^\n]*

/* Literais */
null        "B7"

/* Alfabeto Quaternário Musical (Base 4) e Identificadores */
letra_var   ("G"|"D"|"A"|"E")
letra_num   ("Cmaj7"|"Dmaj7"|"Emaj7"|"Fmaj7")

/* Tipos */
int         "C7"
float       "D7"
bool        "E7"
tipo        ({int}|{float}|{bool})

/* Acordes */
cifra       [A-G]
alter       [#b]

minor       "m"
maj         "maj"
dim         "dim"
plus        "+"

softs       (9|(11)|(13))
ext_num     ({softs}|7)
ext_alt     ((b5)|(b9)|(#9)|(#11)|(b13))
sus         "sus"(2|4)
bass        "/"{cifra}{alter}?

mood_body   ({dim}|{plus})7?
maj_body    {maj}{ext_num}?
min_body    {minor}{ext_num}?{ext_alt}?
dom_body    {ext_num}{ext_alt}?{sus}?

chord_body  ({mood_body}|{maj_body}|{min_body}|{dom_body}|{sus})
chord       {cifra}{alter}?{chord_body}?{bass}?

%%

{ws}            { /* ignora espacos e tabs */ }
{newline}       { yylineno++; }
{comment}       { /* ignora comentario */ }

"B"[ \t]+"C"    { return FIM_LINHA; }
"F#"            { return FIM_LINHA; }

"F7"            { strncpy(yylval.sval, yytext, 255); return KW_LISTA; }
{tipo}          { strncpy(yylval.sval, yytext, 255); return TIPO; }

"Em"            { return OP_ADD; }
"Cm"            { return OP_SUB; }
"Am"            { return OP_MUL; }
"Bm"            { return OP_DIV; }

"Dm"            { return OP_AND; }
"Gm"            { return OP_OR;  }
"Fm"            { return OP_NOT; }

"Dm7"           { return OP_EQ;  }
"Cdim7"         { return OP_NEQ; }
"Gmaj7"         { return OP_GT;  }
"Fdim7"         { return OP_LT;  }
"Am7"           { return OP_GTE; }
"Bm7"           { return OP_LTE; }

"G7"            { return VAR; }
"A7"            { return FUNC; }
"F#maj7"        { return CALL; }

"Cm7"           { return READ_LIST; }
"Bbmaj7"        { return WRITE_LIST; }

"Ebmaj7"        { return WHILE; }
"C#"            { return ELSE; }
"F"             { return IF; }
"F#7"           { return KW_RETURN; }
"Bdim7"         { return KW_BREAK; }
"Abmaj7"        { return KW_CONTINUE; }

"C"             { return BLOCO_INI; }
"Bbm"           { return END_BLOCO; }

"Bb"            { yylval.ival = 1; return LIT_BOOL; }
"Ab"            { yylval.ival = 0; return LIT_BOOL; }

{null}          { return LIT_NULL; }


({letra_var}[ \t\n]*)+"F#m" { 
                /* 1. Remove espacos e o terminador F#m para salvar um nome limpo */
                char clean_name[256] = "";
                int j = 0;
                for(int i = 0; yytext[i] != '\0'; i++) {
                    if(yytext[i] != ' ' && yytext[i] != '\t' && yytext[i] != '\n') {
                        clean_name[j++] = yytext[i];
                    }
                }
                clean_name[j] = '\0';
                
                /* Remove os 3 caracteres do final ("F#m") */
                if (j >= 3) clean_name[j-3] = '\0'; 
                
                strncpy(yylval.sval, clean_name, 255);
                return ID; 
            }

({letra_num}[ \t\n]*)+"Bdim"[ \t\n]*({letra_num}[ \t\n]*)+"Abm" { 
                /* Processa floats em Base 4: parte_inteira Bdim parte_fracionaria Abm */
                double val = 0.0;
                double divisor = 4.0;
                int is_fraction = 0;
                char *p = yytext;

                while(*p != '\0') {
                    if(*p == ' ' || *p == '\t' || *p == '\n') { p++; continue; }
                    if(strncmp(p, "Abm", 3) == 0) break;
                    
                    /* Se encontrou a vírgula, ativa o modo fracionário */
                    if(strncmp(p, "Bdim", 4) == 0) { 
                        is_fraction = 1; 
                        p += 4; 
                        continue; 
                    }
                    
                    int digit = -1;
                    if(strncmp(p, "Cmaj7", 5) == 0)      { digit = 0; p += 5; }
                    else if(strncmp(p, "Dmaj7", 5) == 0) { digit = 1; p += 5; }
                    else if(strncmp(p, "Emaj7", 5) == 0) { digit = 2; p += 5; }
                    else if(strncmp(p, "Fmaj7", 5) == 0) { digit = 3; p += 5; }
                    else { p++; continue; }

                    if (!is_fraction) {
                        /* Antes do Bdim: constrói a parte inteira (val * 4 + digito) */
                        val = val * 4.0 + digit;
                    } else {
                        /* Depois do Bdim: constrói a parte fracionária (digito / divisor) */
                        val = val + ((double)digit / divisor);
                        divisor *= 4.0; /* Próxima casa decimal será dividida por 16, depois 64... */
                    }
                }
                yylval.fval = val;
                return LIT_FLOAT; 
            }

({letra_num}[ \t\n]*)+"Abm" { 
                /* 2. Processa os acordes em Base 4 e converte para decimal */
                int val = 0;
                char *p = yytext;
                while(*p != '\0') {
                    if(*p == ' ' || *p == '\t' || *p == '\n') { p++; continue; }
                    if(strncmp(p, "Abm", 3) == 0) break;
                    
                    if(strncmp(p, "Cmaj7", 5) == 0)      { val = val * 4 + 0; p += 5; }
                    else if(strncmp(p, "Dmaj7", 5) == 0) { val = val * 4 + 1; p += 5; }
                    else if(strncmp(p, "Emaj7", 5) == 0) { val = val * 4 + 2; p += 5; }
                    else if(strncmp(p, "Fmaj7", 5) == 0) { val = val * 4 + 3; p += 5; }
                    else { p++; }
                }
                yylval.ival = val;
                return LIT_INT; 
            }

{chord}         { strncpy(yylval.sval, yytext, 255); return ACORDE_LIVRE; }

.               { fprintf(stderr, "Erro lexico na linha %d: caractere desconhecido '%s'\n", yylineno, yytext); }

%%
