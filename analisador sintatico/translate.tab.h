/* A Bison parser, made by GNU Bison 2.3.  */

/* Skeleton interface for Bison's Yacc-like parsers in C

   Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002, 2003, 2004, 2005, 2006
   Free Software Foundation, Inc.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     FIM_LINHA = 258,
     TIPO = 259,
     VAR = 260,
     FUNC = 261,
     IF = 262,
     ELSE = 263,
     WHILE = 264,
     KW_RETURN = 265,
     KW_BREAK = 266,
     KW_CONTINUE = 267,
     BLOCO_INI = 268,
     END_BLOCO = 269,
     READ_LIST = 270,
     WRITE_LIST = 271,
     OP_ADD = 272,
     OP_SUB = 273,
     OP_MUL = 274,
     OP_DIV = 275,
     OP_AND = 276,
     OP_OR = 277,
     OP_NOT = 278,
     OP_EQ = 279,
     OP_NEQ = 280,
     OP_GT = 281,
     OP_LT = 282,
     OP_GTE = 283,
     OP_LTE = 284,
     LIT_INT = 285,
     LIT_FLOAT = 286,
     LIT_CHAR = 287,
     LIT_STRING = 288,
     LIT_BOOL = 289,
     ID = 290,
     ACORDE_LIVRE = 291,
     DECL_SEM_INICIALIZACAO = 292
   };
#endif
/* Tokens.  */
#define FIM_LINHA 258
#define TIPO 259
#define VAR 260
#define FUNC 261
#define IF 262
#define ELSE 263
#define WHILE 264
#define KW_RETURN 265
#define KW_BREAK 266
#define KW_CONTINUE 267
#define BLOCO_INI 268
#define END_BLOCO 269
#define READ_LIST 270
#define WRITE_LIST 271
#define OP_ADD 272
#define OP_SUB 273
#define OP_MUL 274
#define OP_DIV 275
#define OP_AND 276
#define OP_OR 277
#define OP_NOT 278
#define OP_EQ 279
#define OP_NEQ 280
#define OP_GT 281
#define OP_LT 282
#define OP_GTE 283
#define OP_LTE 284
#define LIT_INT 285
#define LIT_FLOAT 286
#define LIT_CHAR 287
#define LIT_STRING 288
#define LIT_BOOL 289
#define ID 290
#define ACORDE_LIVRE 291
#define DECL_SEM_INICIALIZACAO 292




#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef union YYSTYPE
#line 46 "analisador sintatico/translate.y"
{
    int    ival;
    double fval;
    char   sval[256];
}
/* Line 1529 of yacc.c.  */
#line 129 "analisador sintatico/translate.tab.h"
	YYSTYPE;
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
# define YYSTYPE_IS_TRIVIAL 1
#endif

extern YYSTYPE yylval;

