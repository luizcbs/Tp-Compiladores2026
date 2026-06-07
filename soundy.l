%{
/*
 * Soundy Script -- Analisador Lexico (Trabalho Pratico 1)
 *
 * Compilar:
 *   flex lex.l
 *   gcc lex.yy.c -o soundy
 *
 * Executar:
 *   ./soundy programa.sndy
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int lineno = 1;

/* Retorna o nome portugues de uma nota musical */
static const char *nome_nota(char c) {
    switch (c) {
        case 'A': return "La";
        case 'B': return "Si";
        case 'C': return "Do";
        case 'D': return "Re";
        case 'E': return "Mi";
        case 'F': return "Fa";
        case 'G': return "Sol";
    }
    return "?";
}

static const char *casa_ext_num(const char *s, int *len) {
    if (s[0]=='1' && s[1]=='3') { *len=2; return "decima-terceira"; }
    if (s[0]=='1' && s[1]=='1') { *len=2; return "decima-primeira"; }
    if (s[0]=='9')               { *len=1; return "nona"; }
    if (s[0]=='7')               { *len=1; return "setima"; }
    *len=0; return NULL;
}

static const char *casa_ext_alt(const char *s, int *len) {
    if (s[0]=='b' && s[1]=='1' && s[2]=='3') { *len=3; return "decima-terceira menor"; }
    if (s[0]=='#' && s[1]=='1' && s[2]=='1') { *len=3; return "decima-primeira aumentada"; }
    if (s[0]=='b' && s[1]=='5')              { *len=2; return "quinta diminuta"; }
    if (s[0]=='b' && s[1]=='9')              { *len=2; return "nona menor"; }
    if (s[0]=='#' && s[1]=='9')              { *len=2; return "nona aumentada"; }
    *len=0; return NULL;
}

/*
 * descreve_acorde -- chamada apenas para acordes que NAO sao
 * palavras-chave da linguagem. Produz descricao musical.
 */
void descreve_acorde(const char *s) {
    char desc[512] = "";
    int i = 0, len = 0;
    const char *tmp;

    strcat(desc, nome_nota(s[i++]));

    if      (s[i] == '#') { strcat(desc, " sustenido"); i++; }
    else if (s[i] == 'b') { strcat(desc, " bemol");    i++; }

    if (s[i]=='d' && s[i+1]=='i' && s[i+2]=='m') {
        i += 3;
        if (s[i]=='7') { strcat(desc, " diminuto com setima"); i++; }
        else             strcat(desc, " diminuto");
    }
    else if (s[i] == '+') {
        i++;
        if (s[i]=='7') { strcat(desc, " aumentado com setima"); i++; }
        else             strcat(desc, " aumentado");
    }
    else if (s[i]=='m' && s[i+1]=='a' && s[i+2]=='j') {
        i += 3;
        strcat(desc, " maior");
        tmp = casa_ext_num(s+i, &len);
        if (tmp) { strcat(desc, " com "); strcat(desc, tmp); i += len; }
    }
    else if (s[i] == 'm') {
        i++;
        strcat(desc, " menor");
        tmp = casa_ext_num(s+i, &len);
        if (tmp) {
            strcat(desc, " com "); strcat(desc, tmp); i += len;
            const char *ea = casa_ext_alt(s+i, &len);
            if (ea) { strcat(desc, " e "); strcat(desc, ea); i += len; }
        } else {
            tmp = casa_ext_alt(s+i, &len);
            if (tmp) { strcat(desc, " e "); strcat(desc, tmp); i += len; }
        }
    }
    else if (s[i]=='s' && s[i+1]=='u' && s[i+2]=='s') {
        i += 3;
        if (s[i]=='2') { strcat(desc, " suspenso na segunda"); i++; }
        else             strcat(desc, " suspenso na quarta");  i++;
    }
    else {
        tmp = casa_ext_num(s+i, &len);
        if (tmp) {
            strcat(desc, " com "); strcat(desc, tmp); i += len;
            tmp = casa_ext_alt(s+i, &len);
            if (tmp) { strcat(desc, " e "); strcat(desc, tmp); i += len; }
            if (s[i]=='s' && s[i+1]=='u' && s[i+2]=='s') {
                i += 3;
                if (s[i]=='2') { strcat(desc, " suspenso na segunda"); i++; }
                else             strcat(desc, " suspenso na quarta");  i++;
            }
        }
    }

    if (s[i] == '/') {
        i++;
        strcat(desc, " com baixo em ");
        strcat(desc, nome_nota(s[i++]));
        if      (s[i]=='#') strcat(desc, " sustenido");
        else if (s[i]=='b') strcat(desc, " bemol");
    }

    printf("LINHA %-3d | ACORDE_LIVRE   | %-10s | %s\n", lineno, s, desc);
}
%}

%option noyywrap

ws          [ \t]+
newline     \n
comment     "//"[^\n]*

/* Definições de Literais*/
float_lit   [0-9]+"."[0-9]+
int_lit     [0-9]+
char_lit    '.'
string_lit  ["][^"]*["]

id          [A-Za-z][A-Za-z0-9_]*

cifra       [A-G]
alter       [#b]

minor       "m"
maj         "maj"
dim         "dim"
plus        "+"
mood        ({minor}|{maj})

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

{ws}        { /* ignora espacos e tabs */ }
{newline}   { lineno++; }
{comment}   { /* ignora comentario */ }

"B"[ \t]+"C"    { printf("LINHA %-3d | FIM_LINHA      | %s\n", lineno, yytext); }

"C/G"       { printf("LINHA %-3d | TIPO           | %-10s | int\n",   lineno, yytext); }
"Am/E"      { printf("LINHA %-3d | TIPO           | %-10s | float\n", lineno, yytext); }
"Em/B"      { printf("LINHA %-3d | TIPO           | %-10s | bool\n",  lineno, yytext); }
"F/C"       { printf("LINHA %-3d | TIPO           | %-10s | char\n",  lineno, yytext); }
"G/D"       { printf("LINHA %-3d | TIPO           | %-10s | null\n",  lineno, yytext); }
"C7"        { printf("LINHA %-3d | TIPO           | %-10s | lista\n", lineno, yytext); }

"C/E"       { printf("LINHA %-3d | OP_ARIT        | %-10s | soma (+)\n",           lineno, yytext); }
"Dm/F#"     { printf("LINHA %-3d | OP_ARIT        | %-10s | subtracao (-)\n",      lineno, yytext); }
"E/G"       { printf("LINHA %-3d | OP_ARIT        | %-10s | multiplicacao (*)\n",  lineno, yytext); }
"F/A"       { printf("LINHA %-3d | OP_ARIT        | %-10s | divisao (/)\n",        lineno, yytext); }

"G/B"       { printf("LINHA %-3d | OP_LOGICO      | %-10s | and\n", lineno, yytext); }
"Am/C"      { printf("LINHA %-3d | OP_LOGICO      | %-10s | or\n",  lineno, yytext); }
"Bm/D"      { printf("LINHA %-3d | OP_LOGICO      | %-10s | not\n", lineno, yytext); }

"C7/E"      { printf("LINHA %-3d | OP_REL         | %-10s | igual (==)\n",          lineno, yytext); }
"Dm7/F#"    { printf("LINHA %-3d | OP_REL         | %-10s | diferente (!=)\n",      lineno, yytext); }
"E7/G"      { printf("LINHA %-3d | OP_REL         | %-10s | maior que (>)\n",       lineno, yytext); }
"F7/A"      { printf("LINHA %-3d | OP_REL         | %-10s | menor que (<)\n",       lineno, yytext); }
"G7/B"      { printf("LINHA %-3d | OP_REL         | %-10s | maior ou igual (>=)\n", lineno, yytext); }
"A7/C#"     { printf("LINHA %-3d | OP_REL         | %-10s | menor ou igual (<=)\n", lineno, yytext); }

"Dm/A"      { printf("LINHA %-3d | VAR            | %s\n", lineno, yytext); }
"Bm/F#"     { printf("LINHA %-3d | FUNC           | %s\n", lineno, yytext); }
"D/F#"      { printf("LINHA %-3d | MOVE           | %s\n", lineno, yytext); }
"Dm"        { printf("LINHA %-3d | READ           | %s\n", lineno, yytext); }
"G"         { printf("LINHA %-3d | PRINT          | %s\n", lineno, yytext); }

"C7maj"     { printf("LINHA %-3d | READ_LIST      | %s\n", lineno, yytext); }
"Cm7"       { printf("LINHA %-3d | WRITE_LIST     | %s\n", lineno, yytext); }

"G#dim"     { printf("LINHA %-3d | BREAK          | %s\n", lineno, yytext); }
"A7"        { printf("LINHA %-3d | CONTINUE       | %s\n", lineno, yytext); }
"Bm"        { printf("LINHA %-3d | WHILE          | %s\n", lineno, yytext); }
"Em"        { printf("LINHA %-3d | ELSE           | %s\n", lineno, yytext); }
"F"         { printf("LINHA %-3d | IF             | %s\n", lineno, yytext); }
"E"         { printf("LINHA %-3d | SWITCH         | %s\n", lineno, yytext); }
"A"         { printf("LINHA %-3d | CASE           | %s\n", lineno, yytext); }

"Cm"        { printf("LINHA %-3d | END_BLOCO      | %s\n", lineno, yytext); }
"C"         { printf("LINHA %-3d | BEGIN          | %s\n", lineno, yytext); }
"Am"        { printf("LINHA %-3d | RETURN         | %s\n", lineno, yytext); }

"true"      { printf("LINHA %-3d | LIT_BOOL       | %-10s | verdadeiro\n", lineno, yytext); }
"false"     { printf("LINHA %-3d | LIT_BOOL       | %-10s | falso\n",      lineno, yytext); }

{float_lit} { printf("LINHA %-3d | LIT_FLOAT      | %s\n", lineno, yytext); }
{int_lit}   { printf("LINHA %-3d | LIT_INT        | %s\n", lineno, yytext); }
{char_lit}  { printf("LINHA %-3d | LIT_CHAR       | %s\n", lineno, yytext); }
{string_lit} { printf("LINHA %-3d | LIT_STRING     | %s\n", lineno, yytext); }

{chord}     { descreve_acorde(yytext); }

{id}        { printf("LINHA %-3d | IDENTIFICADOR  | %s\n", lineno, yytext); }

.           { printf("LINHA %-3d | ERRO_LEXICO    | Caractere desconhecido: '%s'\n", lineno, yytext); }

%%

int main(int argc, char *argv[]) {
    printf("=============================================================\n");
    printf("  Analisador Lexico - Soundy Script\n");
    printf("=============================================================\n");
    yylex();
    printf("=============================================================\n");
    printf("  Analise concluida. Linhas processadas: %d\n", lineno);
    printf("=============================================================\n");
    if (argc > 1) fclose(yyin);
    return 0;
}