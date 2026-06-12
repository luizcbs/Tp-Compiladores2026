%{
/*
 * Soundy Script -- Analisador Lexico (Trabalho Pratico 2)
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
float_lit   [0-9]+"."[0-9]+
null        "G/D"

/* Alfabeto Quaternário Musical (Base 4) e Identificadores */
letra_var   ("G"|"D"|"A"|"E")
letra_num   ("Cmaj7"|"Dmaj7"|"Emaj7"|"Fmaj7")

/* Tipos */
int         "C/G"
float       "Am/E"
bool        "Em/B"
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

"C7"            { strncpy(yylval.sval, yytext, 255); return KW_LISTA; }
{tipo}          { strncpy(yylval.sval, yytext, 255); return TIPO; }

"C/E"           { return OP_ADD; }
"Dm/F#"         { return OP_SUB; }
"E/G"           { return OP_MUL; }
"F/A"           { return OP_DIV; }

"G/B"           { return OP_AND; }
"Am/C"          { return OP_OR; }
"Bm/D"          { return OP_NOT; }

"C7/E"          { return OP_EQ; }
"Dm7/F#"        { return OP_NEQ; }
"E7/G"          { return OP_GT; }
"F7/A"          { return OP_LT; }
"G7/B"          { return OP_GTE; }
"A7/C#"         { return OP_LTE; }

"Dm/A"          { return VAR; }
"Bm/F#"         { return FUNC; }
"A/C#"          { return CALL; }

"C7maj"         { return READ_LIST; }
"Cm7"           { return WRITE_LIST; }

"Bm"            { return WHILE; }
"Em"            { return ELSE; }
"F"             { return IF; }
"Am"            { return KW_RETURN; }
"G#dim"         { return KW_BREAK; }
"A7"            { return KW_CONTINUE; }

"C"             { return BLOCO_INI; }
"Cm"            { return END_BLOCO; }

"true"          { yylval.ival = 1; return LIT_BOOL; }
"false"         { yylval.ival = 0; return LIT_BOOL; }

{null}          { return LIT_NULL; }

{float_lit}     { yylval.fval = atof(yytext); return LIT_FLOAT; }

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

({letra_num}[ \t\n]*)+"G#m" { 
                /* 2. Processa os acordes em Base 4 e converte para decimal */
                int val = 0;
                char *p = yytext;
                while(*p != '\0') {
                    if(*p == ' ' || *p == '\t' || *p == '\n') { p++; continue; }
                    if(strncmp(p, "G#m", 3) == 0) break;
                    
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
