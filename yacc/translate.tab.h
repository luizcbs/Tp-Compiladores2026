/* A Bison parser, made by GNU Bison 3.8.2.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2021 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.  */

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

/* DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
   especially those whose name start with YY_ or yy_.  They are
   private implementation details that can be changed or removed.  */

#ifndef YY_YY_YACC_TRANSLATE_TAB_H_INCLUDED
# define YY_YY_YACC_TRANSLATE_TAB_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif
/* "%code requires" blocks.  */
#line 9 "yacc/translate.y"

    #include "TabelaSimbolo.h"

#line 53 "yacc/translate.tab.h"

/* Token kinds.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    YYEMPTY = -2,
    YYEOF = 0,                     /* "end of file"  */
    YYerror = 256,                 /* error  */
    YYUNDEF = 257,                 /* "invalid token"  */
    FIM_LINHA = 258,               /* FIM_LINHA  */
    TIPO = 259,                    /* TIPO  */
    VAR = 260,                     /* VAR  */
    FUNC = 261,                    /* FUNC  */
    CALL = 262,                    /* CALL  */
    IF = 263,                      /* IF  */
    ELSE = 264,                    /* ELSE  */
    WHILE = 265,                   /* WHILE  */
    KW_RETURN = 266,               /* KW_RETURN  */
    KW_BREAK = 267,                /* KW_BREAK  */
    KW_CONTINUE = 268,             /* KW_CONTINUE  */
    BLOCO_INI = 269,               /* BLOCO_INI  */
    END_BLOCO = 270,               /* END_BLOCO  */
    READ_LIST = 271,               /* READ_LIST  */
    WRITE_LIST = 272,              /* WRITE_LIST  */
    OP_ADD = 273,                  /* OP_ADD  */
    OP_SUB = 274,                  /* OP_SUB  */
    OP_MUL = 275,                  /* OP_MUL  */
    OP_DIV = 276,                  /* OP_DIV  */
    OP_AND = 277,                  /* OP_AND  */
    OP_OR = 278,                   /* OP_OR  */
    OP_NOT = 279,                  /* OP_NOT  */
    OP_EQ = 280,                   /* OP_EQ  */
    OP_NEQ = 281,                  /* OP_NEQ  */
    OP_GT = 282,                   /* OP_GT  */
    OP_LT = 283,                   /* OP_LT  */
    OP_GTE = 284,                  /* OP_GTE  */
    OP_LTE = 285,                  /* OP_LTE  */
    LIT_INT = 286,                 /* LIT_INT  */
    LIT_FLOAT = 287,               /* LIT_FLOAT  */
    LIT_BOOL = 288,                /* LIT_BOOL  */
    ID = 289,                      /* ID  */
    ACORDE_LIVRE = 290,            /* ACORDE_LIVRE  */
    NULL_LIT = 291                 /* NULL_LIT  */
  };
  typedef enum yytokentype yytoken_kind_t;
#endif

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
union YYSTYPE
{
#line 122 "yacc/translate.y"

    int    ival;
    double fval;
    char   sval[256];
    Tipo   tval;

#line 113 "yacc/translate.tab.h"

};
typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;


int yyparse (void);


#endif /* !YY_YY_YACC_TRANSLATE_TAB_H_INCLUDED  */
