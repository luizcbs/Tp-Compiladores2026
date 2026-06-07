%{
/*
 * Soundy Script -- Analisador Lexico (Trabalho Pratico 2)
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "translate.tab.h"

int yylineno = 1;

%}

%option noyywrap

ws          [ \t]+
newline     \n
comment     "//"[^\n]*

/* Literais */
float_lit   [0-9]+"."[0-9]+
int_lit     [0-9]+
char_lit    '.'
string_lit  \"[^\"]*\"

id          [A-Za-z][A-Za-z0-9_]*

/* Tipos */
int         "C/G"
float       "Am/E"
bool        "Em"
char        "F/C"
null        "G/D"
lista       "C7"
tipo        ({int}|{float}|{bool}|{char}|{null}|{lista})

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

{tipo}          { strncpy(yylval.sval, yytext, 255); return TIPO; }

/* Operadores aritmeticos */
"C/E"           { return OP_ADD; }
"Dm/F#"         { return OP_SUB; }
"E/G"           { return OP_MUL; }
"F/A"           { return OP_DIV; }

/* Operadores logicos */
"G/B"           { return OP_AND; }
"Am/C"          { return OP_OR; }
"Bm/D"          { return OP_NOT; }

/* Operadores relacionais */
"C7/E"          { return OP_EQ; }
"Dm7/F#"        { return OP_NEQ; }
"E7/G"          { return OP_GT; }
"F7/A"          { return OP_LT; }
"G7/B"          { return OP_GTE; }
"A7/C#"         { return OP_LTE; }

/* Declaracao */
"Dm/A"          { return VAR; }
"Bm/F#"         { return FUNC; }

/* Operacoes de lista */
"C7maj"         { return READ_LIST; }
"Cm7"           { return WRITE_LIST; }

/* Controle de fluxo */
"Bm"            { return WHILE; }
"Em"            { return ELSE; }
"F"             { return IF; }
"Am"            { return KW_RETURN; }
"G#dim"         { return KW_BREAK; }
"A7"            { return KW_CONTINUE; }

/* Blocos */
"C"             { return BLOCO_INI; }
"Cm"            { return END_BLOCO; }

/* Literais */
"true"          { yylval.ival = 1; return LIT_BOOL; }
"false"         { yylval.ival = 0; return LIT_BOOL; }

{float_lit}     { yylval.fval = atof(yytext); return LIT_FLOAT; }
{int_lit}       { yylval.ival = atoi(yytext); return LIT_INT; }
{char_lit}      { strncpy(yylval.sval, yytext, 255); return LIT_CHAR; }
{string_lit}    { strncpy(yylval.sval, yytext, 255); return LIT_STRING; }

{chord}         { strncpy(yylval.sval, yytext, 255); return ACORDE_LIVRE; }

{id}            { strncpy(yylval.sval, yytext, 255); return ID; }

.               { fprintf(stderr, "Erro lexico na linha %d: caractere desconhecido '%s'\n", yylineno, yytext); }

%%