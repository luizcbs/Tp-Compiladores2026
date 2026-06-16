/* A Bison parser, made by GNU Bison 3.8.2.  */

/* Bison implementation for Yacc-like parsers in C

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

/* C LALR(1) parser skeleton written by Richard Stallman, by
   simplifying the original so-called "semantic" parser.  */

/* DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
   especially those whose name start with YY_ or yy_.  They are
   private implementation details that can be changed or removed.  */

/* All symbols defined below should begin with yy or YY, to avoid
   infringing on user name space.  This should be done even for local
   variables, as they might otherwise be expanded by user macros.
   There are some unavoidable exceptions within include files to
   define necessary library symbols; they are noted "INFRINGES ON
   USER NAME SPACE" below.  */

/* Identify Bison output, and Bison version.  */
#define YYBISON 30802

/* Bison version string.  */
#define YYBISON_VERSION "3.8.2"

/* Skeleton name.  */
#define YYSKELETON_NAME "yacc.c"

/* Pure parsers.  */
#define YYPURE 0

/* Push parsers.  */
#define YYPUSH 0

/* Pull parsers.  */
#define YYPULL 1




/* First part of user prologue.  */
#line 1 "yacc/translate.y"

/* Analisador Sintatico e GCI - Soundy Script (TP3) */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "TabelaSimbolo.h"
#include "gci.h"

extern int yylineno;
int  yylex(void);
void yyerror(const char *msg);

/* Funcoes auxiliares */
static void inserir_simbolo(const char *nome, const char *tipo, const char *categoria, int linha);
static Tipo tipo_de_texto(const char *tipo);
static Categoria categoria_de_texto(const char *categoria);

extern TabelaSimbolo *global;
extern TabelaSimbolo *tabelaAtual;

#line 93 "yacc/translate.tab.c"

# ifndef YY_CAST
#  ifdef __cplusplus
#   define YY_CAST(Type, Val) static_cast<Type> (Val)
#   define YY_REINTERPRET_CAST(Type, Val) reinterpret_cast<Type> (Val)
#  else
#   define YY_CAST(Type, Val) ((Type) (Val))
#   define YY_REINTERPRET_CAST(Type, Val) ((Type) (Val))
#  endif
# endif
# ifndef YY_NULLPTR
#  if defined __cplusplus
#   if 201103L <= __cplusplus
#    define YY_NULLPTR nullptr
#   else
#    define YY_NULLPTR 0
#   endif
#  else
#   define YY_NULLPTR ((void*)0)
#  endif
# endif

#include "translate.tab.h"
/* Symbol kind.  */
enum yysymbol_kind_t
{
  YYSYMBOL_YYEMPTY = -2,
  YYSYMBOL_YYEOF = 0,                      /* "end of file"  */
  YYSYMBOL_YYerror = 1,                    /* error  */
  YYSYMBOL_YYUNDEF = 2,                    /* "invalid token"  */
  YYSYMBOL_FIM_LINHA = 3,                  /* FIM_LINHA  */
  YYSYMBOL_TIPO = 4,                       /* TIPO  */
  YYSYMBOL_VAR = 5,                        /* VAR  */
  YYSYMBOL_FUNC = 6,                       /* FUNC  */
  YYSYMBOL_IF = 7,                         /* IF  */
  YYSYMBOL_ELSE = 8,                       /* ELSE  */
  YYSYMBOL_WHILE = 9,                      /* WHILE  */
  YYSYMBOL_KW_RETURN = 10,                 /* KW_RETURN  */
  YYSYMBOL_KW_BREAK = 11,                  /* KW_BREAK  */
  YYSYMBOL_KW_CONTINUE = 12,               /* KW_CONTINUE  */
  YYSYMBOL_BLOCO_INI = 13,                 /* BLOCO_INI  */
  YYSYMBOL_END_BLOCO = 14,                 /* END_BLOCO  */
  YYSYMBOL_READ_LIST = 15,                 /* READ_LIST  */
  YYSYMBOL_WRITE_LIST = 16,                /* WRITE_LIST  */
  YYSYMBOL_OP_ADD = 17,                    /* OP_ADD  */
  YYSYMBOL_OP_SUB = 18,                    /* OP_SUB  */
  YYSYMBOL_OP_MUL = 19,                    /* OP_MUL  */
  YYSYMBOL_OP_DIV = 20,                    /* OP_DIV  */
  YYSYMBOL_OP_AND = 21,                    /* OP_AND  */
  YYSYMBOL_OP_OR = 22,                     /* OP_OR  */
  YYSYMBOL_OP_NOT = 23,                    /* OP_NOT  */
  YYSYMBOL_OP_EQ = 24,                     /* OP_EQ  */
  YYSYMBOL_OP_NEQ = 25,                    /* OP_NEQ  */
  YYSYMBOL_OP_GT = 26,                     /* OP_GT  */
  YYSYMBOL_OP_LT = 27,                     /* OP_LT  */
  YYSYMBOL_OP_GTE = 28,                    /* OP_GTE  */
  YYSYMBOL_OP_LTE = 29,                    /* OP_LTE  */
  YYSYMBOL_LIT_INT = 30,                   /* LIT_INT  */
  YYSYMBOL_LIT_FLOAT = 31,                 /* LIT_FLOAT  */
  YYSYMBOL_LIT_CHAR = 32,                  /* LIT_CHAR  */
  YYSYMBOL_LIT_STRING = 33,                /* LIT_STRING  */
  YYSYMBOL_LIT_BOOL = 34,                  /* LIT_BOOL  */
  YYSYMBOL_ID = 35,                        /* ID  */
  YYSYMBOL_ACORDE_LIVRE = 36,              /* ACORDE_LIVRE  */
  YYSYMBOL_DECL_SEM_INICIALIZACAO = 37,    /* DECL_SEM_INICIALIZACAO  */
  YYSYMBOL_YYACCEPT = 38,                  /* $accept  */
  YYSYMBOL_program = 39,                   /* program  */
  YYSYMBOL_decl_list = 40,                 /* decl_list  */
  YYSYMBOL_decl = 41,                      /* decl  */
  YYSYMBOL_var_decl = 42,                  /* var_decl  */
  YYSYMBOL_func_decl = 43,                 /* func_decl  */
  YYSYMBOL_param_list = 44,                /* param_list  */
  YYSYMBOL_param = 45,                     /* param  */
  YYSYMBOL_stmt_list = 46,                 /* stmt_list  */
  YYSYMBOL_stmt = 47,                      /* stmt  */
  YYSYMBOL_operando = 48,                  /* operando  */
  YYSYMBOL_op_binario = 49,                /* op_binario  */
  YYSYMBOL_op_unario = 50,                 /* op_unario  */
  YYSYMBOL_if_prefix = 51,                 /* if_prefix  */
  YYSYMBOL_if_stmt = 52,                   /* if_stmt  */
  YYSYMBOL_53_1 = 53,                      /* @1  */
  YYSYMBOL_while_prefix = 54,              /* while_prefix  */
  YYSYMBOL_while_stmt = 55,                /* while_stmt  */
  YYSYMBOL_56_2 = 56,                      /* $@2  */
  YYSYMBOL_return_stmt = 57,               /* return_stmt  */
  YYSYMBOL_break_stmt = 58,                /* break_stmt  */
  YYSYMBOL_continue_stmt = 59,             /* continue_stmt  */
  YYSYMBOL_func_call_stmt = 60,            /* func_call_stmt  */
  YYSYMBOL_operando_list = 61,             /* operando_list  */
  YYSYMBOL_read_list_stmt = 62,            /* read_list_stmt  */
  YYSYMBOL_write_list_stmt = 63            /* write_list_stmt  */
};
typedef enum yysymbol_kind_t yysymbol_kind_t;




#ifdef short
# undef short
#endif

/* On compilers that do not define __PTRDIFF_MAX__ etc., make sure
   <limits.h> and (if available) <stdint.h> are included
   so that the code can choose integer types of a good width.  */

#ifndef __PTRDIFF_MAX__
# include <limits.h> /* INFRINGES ON USER NAME SPACE */
# if defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stdint.h> /* INFRINGES ON USER NAME SPACE */
#  define YY_STDINT_H
# endif
#endif

/* Narrow types that promote to a signed type and that can represent a
   signed or unsigned integer of at least N bits.  In tables they can
   save space and decrease cache pressure.  Promoting to a signed type
   helps avoid bugs in integer arithmetic.  */

#ifdef __INT_LEAST8_MAX__
typedef __INT_LEAST8_TYPE__ yytype_int8;
#elif defined YY_STDINT_H
typedef int_least8_t yytype_int8;
#else
typedef signed char yytype_int8;
#endif

#ifdef __INT_LEAST16_MAX__
typedef __INT_LEAST16_TYPE__ yytype_int16;
#elif defined YY_STDINT_H
typedef int_least16_t yytype_int16;
#else
typedef short yytype_int16;
#endif

/* Work around bug in HP-UX 11.23, which defines these macros
   incorrectly for preprocessor constants.  This workaround can likely
   be removed in 2023, as HPE has promised support for HP-UX 11.23
   (aka HP-UX 11i v2) only through the end of 2022; see Table 2 of
   <https://h20195.www2.hpe.com/V2/getpdf.aspx/4AA4-7673ENW.pdf>.  */
#ifdef __hpux
# undef UINT_LEAST8_MAX
# undef UINT_LEAST16_MAX
# define UINT_LEAST8_MAX 255
# define UINT_LEAST16_MAX 65535
#endif

#if defined __UINT_LEAST8_MAX__ && __UINT_LEAST8_MAX__ <= __INT_MAX__
typedef __UINT_LEAST8_TYPE__ yytype_uint8;
#elif (!defined __UINT_LEAST8_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST8_MAX <= INT_MAX)
typedef uint_least8_t yytype_uint8;
#elif !defined __UINT_LEAST8_MAX__ && UCHAR_MAX <= INT_MAX
typedef unsigned char yytype_uint8;
#else
typedef short yytype_uint8;
#endif

#if defined __UINT_LEAST16_MAX__ && __UINT_LEAST16_MAX__ <= __INT_MAX__
typedef __UINT_LEAST16_TYPE__ yytype_uint16;
#elif (!defined __UINT_LEAST16_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST16_MAX <= INT_MAX)
typedef uint_least16_t yytype_uint16;
#elif !defined __UINT_LEAST16_MAX__ && USHRT_MAX <= INT_MAX
typedef unsigned short yytype_uint16;
#else
typedef int yytype_uint16;
#endif

#ifndef YYPTRDIFF_T
# if defined __PTRDIFF_TYPE__ && defined __PTRDIFF_MAX__
#  define YYPTRDIFF_T __PTRDIFF_TYPE__
#  define YYPTRDIFF_MAXIMUM __PTRDIFF_MAX__
# elif defined PTRDIFF_MAX
#  ifndef ptrdiff_t
#   include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  endif
#  define YYPTRDIFF_T ptrdiff_t
#  define YYPTRDIFF_MAXIMUM PTRDIFF_MAX
# else
#  define YYPTRDIFF_T long
#  define YYPTRDIFF_MAXIMUM LONG_MAX
# endif
#endif

#ifndef YYSIZE_T
# ifdef __SIZE_TYPE__
#  define YYSIZE_T __SIZE_TYPE__
# elif defined size_t
#  define YYSIZE_T size_t
# elif defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  define YYSIZE_T size_t
# else
#  define YYSIZE_T unsigned
# endif
#endif

#define YYSIZE_MAXIMUM                                  \
  YY_CAST (YYPTRDIFF_T,                                 \
           (YYPTRDIFF_MAXIMUM < YY_CAST (YYSIZE_T, -1)  \
            ? YYPTRDIFF_MAXIMUM                         \
            : YY_CAST (YYSIZE_T, -1)))

#define YYSIZEOF(X) YY_CAST (YYPTRDIFF_T, sizeof (X))


/* Stored state numbers (used for stacks). */
typedef yytype_uint8 yy_state_t;

/* State numbers in computations.  */
typedef int yy_state_fast_t;

#ifndef YY_
# if defined YYENABLE_NLS && YYENABLE_NLS
#  if ENABLE_NLS
#   include <libintl.h> /* INFRINGES ON USER NAME SPACE */
#   define YY_(Msgid) dgettext ("bison-runtime", Msgid)
#  endif
# endif
# ifndef YY_
#  define YY_(Msgid) Msgid
# endif
#endif


#ifndef YY_ATTRIBUTE_PURE
# if defined __GNUC__ && 2 < __GNUC__ + (96 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_PURE __attribute__ ((__pure__))
# else
#  define YY_ATTRIBUTE_PURE
# endif
#endif

#ifndef YY_ATTRIBUTE_UNUSED
# if defined __GNUC__ && 2 < __GNUC__ + (7 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_UNUSED __attribute__ ((__unused__))
# else
#  define YY_ATTRIBUTE_UNUSED
# endif
#endif

/* Suppress unused-variable warnings by "using" E.  */
#if ! defined lint || defined __GNUC__
# define YY_USE(E) ((void) (E))
#else
# define YY_USE(E) /* empty */
#endif

/* Suppress an incorrect diagnostic about yylval being uninitialized.  */
#if defined __GNUC__ && ! defined __ICC && 406 <= __GNUC__ * 100 + __GNUC_MINOR__
# if __GNUC__ * 100 + __GNUC_MINOR__ < 407
#  define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN                           \
    _Pragma ("GCC diagnostic push")                                     \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")
# else
#  define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN                           \
    _Pragma ("GCC diagnostic push")                                     \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")              \
    _Pragma ("GCC diagnostic ignored \"-Wmaybe-uninitialized\"")
# endif
# define YY_IGNORE_MAYBE_UNINITIALIZED_END      \
    _Pragma ("GCC diagnostic pop")
#else
# define YY_INITIAL_VALUE(Value) Value
#endif
#ifndef YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_END
#endif
#ifndef YY_INITIAL_VALUE
# define YY_INITIAL_VALUE(Value) /* Nothing. */
#endif

#if defined __cplusplus && defined __GNUC__ && ! defined __ICC && 6 <= __GNUC__
# define YY_IGNORE_USELESS_CAST_BEGIN                          \
    _Pragma ("GCC diagnostic push")                            \
    _Pragma ("GCC diagnostic ignored \"-Wuseless-cast\"")
# define YY_IGNORE_USELESS_CAST_END            \
    _Pragma ("GCC diagnostic pop")
#endif
#ifndef YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_END
#endif


#define YY_ASSERT(E) ((void) (0 && (E)))

#if !defined yyoverflow

/* The parser invokes alloca or malloc; define the necessary symbols.  */

# ifdef YYSTACK_USE_ALLOCA
#  if YYSTACK_USE_ALLOCA
#   ifdef __GNUC__
#    define YYSTACK_ALLOC __builtin_alloca
#   elif defined __BUILTIN_VA_ARG_INCR
#    include <alloca.h> /* INFRINGES ON USER NAME SPACE */
#   elif defined _AIX
#    define YYSTACK_ALLOC __alloca
#   elif defined _MSC_VER
#    include <malloc.h> /* INFRINGES ON USER NAME SPACE */
#    define alloca _alloca
#   else
#    define YYSTACK_ALLOC alloca
#    if ! defined _ALLOCA_H && ! defined EXIT_SUCCESS
#     include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
      /* Use EXIT_SUCCESS as a witness for stdlib.h.  */
#     ifndef EXIT_SUCCESS
#      define EXIT_SUCCESS 0
#     endif
#    endif
#   endif
#  endif
# endif

# ifdef YYSTACK_ALLOC
   /* Pacify GCC's 'empty if-body' warning.  */
#  define YYSTACK_FREE(Ptr) do { /* empty */; } while (0)
#  ifndef YYSTACK_ALLOC_MAXIMUM
    /* The OS might guarantee only one guard page at the bottom of the stack,
       and a page size can be as small as 4096 bytes.  So we cannot safely
       invoke alloca (N) if N exceeds 4096.  Use a slightly smaller number
       to allow for a few compiler-allocated temporary stack slots.  */
#   define YYSTACK_ALLOC_MAXIMUM 4032 /* reasonable circa 2006 */
#  endif
# else
#  define YYSTACK_ALLOC YYMALLOC
#  define YYSTACK_FREE YYFREE
#  ifndef YYSTACK_ALLOC_MAXIMUM
#   define YYSTACK_ALLOC_MAXIMUM YYSIZE_MAXIMUM
#  endif
#  if (defined __cplusplus && ! defined EXIT_SUCCESS \
       && ! ((defined YYMALLOC || defined malloc) \
             && (defined YYFREE || defined free)))
#   include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#   ifndef EXIT_SUCCESS
#    define EXIT_SUCCESS 0
#   endif
#  endif
#  ifndef YYMALLOC
#   define YYMALLOC malloc
#   if ! defined malloc && ! defined EXIT_SUCCESS
void *malloc (YYSIZE_T); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
#  ifndef YYFREE
#   define YYFREE free
#   if ! defined free && ! defined EXIT_SUCCESS
void free (void *); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
# endif
#endif /* !defined yyoverflow */

#if (! defined yyoverflow \
     && (! defined __cplusplus \
         || (defined YYSTYPE_IS_TRIVIAL && YYSTYPE_IS_TRIVIAL)))

/* A type that is properly aligned for any stack member.  */
union yyalloc
{
  yy_state_t yyss_alloc;
  YYSTYPE yyvs_alloc;
};

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAXIMUM (YYSIZEOF (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# define YYSTACK_BYTES(N) \
     ((N) * (YYSIZEOF (yy_state_t) + YYSIZEOF (YYSTYPE)) \
      + YYSTACK_GAP_MAXIMUM)

# define YYCOPY_NEEDED 1

/* Relocate STACK from its old location to the new one.  The
   local variables YYSIZE and YYSTACKSIZE give the old and new number of
   elements in the stack, and YYPTR gives the new location of the
   stack.  Advance YYPTR to a properly aligned location for the next
   stack.  */
# define YYSTACK_RELOCATE(Stack_alloc, Stack)                           \
    do                                                                  \
      {                                                                 \
        YYPTRDIFF_T yynewbytes;                                         \
        YYCOPY (&yyptr->Stack_alloc, Stack, yysize);                    \
        Stack = &yyptr->Stack_alloc;                                    \
        yynewbytes = yystacksize * YYSIZEOF (*Stack) + YYSTACK_GAP_MAXIMUM; \
        yyptr += yynewbytes / YYSIZEOF (*yyptr);                        \
      }                                                                 \
    while (0)

#endif

#if defined YYCOPY_NEEDED && YYCOPY_NEEDED
/* Copy COUNT objects from SRC to DST.  The source and destination do
   not overlap.  */
# ifndef YYCOPY
#  if defined __GNUC__ && 1 < __GNUC__
#   define YYCOPY(Dst, Src, Count) \
      __builtin_memcpy (Dst, Src, YY_CAST (YYSIZE_T, (Count)) * sizeof (*(Src)))
#  else
#   define YYCOPY(Dst, Src, Count)              \
      do                                        \
        {                                       \
          YYPTRDIFF_T yyi;                      \
          for (yyi = 0; yyi < (Count); yyi++)   \
            (Dst)[yyi] = (Src)[yyi];            \
        }                                       \
      while (0)
#  endif
# endif
#endif /* !YYCOPY_NEEDED */

/* YYFINAL -- State number of the termination state.  */
#define YYFINAL  71
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   251

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  38
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  26
/* YYNRULES -- Number of rules.  */
#define YYNRULES  62
/* YYNSTATES -- Number of states.  */
#define YYNSTATES  152

/* YYMAXUTOK -- Last valid token kind.  */
#define YYMAXUTOK   292


/* YYTRANSLATE(TOKEN-NUM) -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex, with out-of-bounds checking.  */
#define YYTRANSLATE(YYX)                                \
  (0 <= (YYX) && (YYX) <= YYMAXUTOK                     \
   ? YY_CAST (yysymbol_kind_t, yytranslate[YYX])        \
   : YYSYMBOL_YYUNDEF)

/* YYTRANSLATE[TOKEN-NUM] -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex.  */
static const yytype_int8 yytranslate[] =
{
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     1,     2,     3,     4,
       5,     6,     7,     8,     9,    10,    11,    12,    13,    14,
      15,    16,    17,    18,    19,    20,    21,    22,    23,    24,
      25,    26,    27,    28,    29,    30,    31,    32,    33,    34,
      35,    36,    37
};

#if YYDEBUG
/* YYRLINE[YYN] -- Source line where rule number YYN was defined.  */
static const yytype_uint8 yyrline[] =
{
       0,    72,    72,    73,    77,    78,    82,    83,    88,    90,
      96,    98,   103,   104,   108,   114,   115,   119,   120,   121,
     122,   123,   124,   125,   126,   127,   128,   129,   134,   135,
     136,   137,   138,   139,   140,   145,   146,   147,   148,   149,
     150,   151,   152,   153,   154,   155,   156,   160,   165,   173,
     178,   177,   190,   203,   202,   215,   219,   224,   230,   235,
     236,   240,   245
};
#endif

/** Accessing symbol of state STATE.  */
#define YY_ACCESSING_SYMBOL(State) YY_CAST (yysymbol_kind_t, yystos[State])

#if YYDEBUG || 0
/* The user-facing name of the symbol whose (internal) number is
   YYSYMBOL.  No bounds checking.  */
static const char *yysymbol_name (yysymbol_kind_t yysymbol) YY_ATTRIBUTE_UNUSED;

/* YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals.  */
static const char *const yytname[] =
{
  "\"end of file\"", "error", "\"invalid token\"", "FIM_LINHA", "TIPO",
  "VAR", "FUNC", "IF", "ELSE", "WHILE", "KW_RETURN", "KW_BREAK",
  "KW_CONTINUE", "BLOCO_INI", "END_BLOCO", "READ_LIST", "WRITE_LIST",
  "OP_ADD", "OP_SUB", "OP_MUL", "OP_DIV", "OP_AND", "OP_OR", "OP_NOT",
  "OP_EQ", "OP_NEQ", "OP_GT", "OP_LT", "OP_GTE", "OP_LTE", "LIT_INT",
  "LIT_FLOAT", "LIT_CHAR", "LIT_STRING", "LIT_BOOL", "ID", "ACORDE_LIVRE",
  "DECL_SEM_INICIALIZACAO", "$accept", "program", "decl_list", "decl",
  "var_decl", "func_decl", "param_list", "param", "stmt_list", "stmt",
  "operando", "op_binario", "op_unario", "if_prefix", "if_stmt", "@1",
  "while_prefix", "while_stmt", "$@2", "return_stmt", "break_stmt",
  "continue_stmt", "func_call_stmt", "operando_list", "read_list_stmt",
  "write_list_stmt", YY_NULLPTR
};

static const char *
yysymbol_name (yysymbol_kind_t yysymbol)
{
  return yytname[yysymbol];
}
#endif

#define YYPACT_NINF (-103)

#define yypact_value_is_default(Yyn) \
  ((Yyn) == YYPACT_NINF)

#define YYTABLE_NINF (-1)

#define yytable_value_is_error(Yyn) \
  0

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
static const yytype_int16 yypact[] =
{
     186,    13,   -12,     9,   192,    20,    37,     8,    22,    24,
      46,    48,    49,    56,    73,    75,    76,    83,   100,   102,
     103,   110,  -103,    44,   186,  -103,  -103,  -103,  -103,  -103,
    -103,  -103,  -103,   127,  -103,  -103,  -103,  -103,  -103,  -103,
    -103,   129,   130,   137,  -103,  -103,  -103,  -103,  -103,  -103,
    -103,  -103,    61,  -103,  -103,   154,   192,   192,   192,   192,
     192,   192,   192,   192,   192,   192,   192,   192,   192,   192,
      18,  -103,  -103,    51,   188,   178,    29,   196,  -103,   192,
     192,   192,   192,   192,   192,   192,   192,   197,   192,   192,
     192,   192,   192,   192,  -103,  -103,   211,   209,  -103,  -103,
     192,   183,  -103,    43,  -103,  -103,   216,   217,   226,   227,
     228,   229,   230,   231,  -103,   232,   233,   234,   235,   236,
     237,   238,  -103,   239,  -103,    78,  -103,  -103,  -103,  -103,
    -103,  -103,  -103,  -103,  -103,  -103,  -103,  -103,  -103,  -103,
    -103,  -103,  -103,   105,  -103,  -103,   132,  -103,  -103,  -103,
     159,  -103
};

/* YYDEFACT[STATE-NUM] -- Default reduction number in state STATE-NUM.
   Performed when YYTABLE does not specify something else to do.  Zero
   means the default is an error.  */
static const yytype_int8 yydefact[] =
{
       3,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,    60,     0,     2,     5,    17,     6,     7,    18,
      19,    16,    20,     0,    21,    22,    23,    24,    27,    25,
      26,     0,     0,     0,    52,    29,    30,    31,    32,    33,
      28,    34,     0,    56,    57,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     1,     4,     0,     0,     0,     0,     0,    55,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,    58,    59,     0,    49,    15,    53,
       8,     0,    16,     0,    13,    48,     0,     0,     0,     0,
       0,     0,     0,     0,    47,     0,     0,     0,     0,     0,
       0,     0,    16,     0,    14,     0,    16,    12,    61,    62,
      35,    36,    37,    38,    39,    40,    41,    42,    43,    44,
      45,    46,    50,     0,     9,    11,     0,    16,    54,    10,
       0,    51
};

/* YYPGOTO[NTERM-NUM].  */
static const yytype_int16 yypgoto[] =
{
    -103,  -103,  -103,   219,  -103,  -103,  -103,   138,  -102,    17,
     -54,  -103,  -103,  -103,  -103,  -103,  -103,  -103,  -103,  -103,
    -103,  -103,  -103,  -103,  -103,  -103
};

/* YYDEFGOTO[NTERM-NUM].  */
static const yytype_uint8 yydefgoto[] =
{
       0,    23,    24,    25,    26,    27,   103,   104,    73,    98,
      52,    29,    30,    31,    32,   147,    33,    34,   122,    35,
      36,    37,    38,    70,    39,    40
};

/* YYTABLE[YYPACT[STATE-NUM]] -- What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule whose
   number is the opposite.  If YYTABLE_NINF, syntax error.  */
static const yytype_uint8 yytable[] =
{
     125,    43,    80,    81,    82,    83,    84,    85,    86,    87,
      88,    89,    90,    91,    92,    93,    95,    28,    41,    42,
     143,    94,    44,    53,   146,   106,   107,   108,   109,   110,
     111,   112,   113,   101,   115,   116,   117,   118,   119,   120,
      54,    28,   102,    55,    71,   150,   123,   101,    45,    46,
      47,    48,    49,    50,    51,    96,   126,    56,     2,    57,
       3,     4,     5,     6,    78,    97,     7,     8,     9,    10,
      11,    12,    13,    14,    15,    16,    17,    18,    19,    20,
      21,    58,    96,    59,    60,     2,    22,     3,     4,     5,
       6,    61,   145,     7,     8,     9,    10,    11,    12,    13,
      14,    15,    16,    17,    18,    19,    20,    21,    62,    96,
      63,    64,     2,    22,     3,     4,     5,     6,    65,   148,
       7,     8,     9,    10,    11,    12,    13,    14,    15,    16,
      17,    18,    19,    20,    21,    66,    96,    67,    68,     2,
      22,     3,     4,     5,     6,    69,   149,     7,     8,     9,
      10,    11,    12,    13,    14,    15,    16,    17,    18,    19,
      20,    21,    74,    96,    75,    76,     2,    22,     3,     4,
       5,     6,    77,   151,     7,     8,     9,    10,    11,    12,
      13,    14,    15,    16,    17,    18,    19,    20,    21,    79,
       1,    99,   100,     2,    22,     3,     4,     5,     6,   105,
     114,     7,     8,     9,    10,    11,    12,    13,    14,    15,
      16,    17,    18,    19,    20,    21,    41,   121,   124,   128,
     129,    22,    45,    46,    47,    48,    49,    50,    51,   130,
     131,   132,   133,   134,   135,   136,   137,   138,   139,   140,
     141,   127,   144,    72,     0,     0,     0,     0,     0,     0,
       0,   142
};

static const yytype_int16 yycheck[] =
{
     102,    13,    56,    57,    58,    59,    60,    61,    62,    63,
      64,    65,    66,    67,    68,    69,    70,     0,     5,     6,
     122,     3,    13,     3,   126,    79,    80,    81,    82,    83,
      84,    85,    86,     4,    88,    89,    90,    91,    92,    93,
       3,    24,    13,    35,     0,   147,   100,     4,    30,    31,
      32,    33,    34,    35,    36,     4,    13,    35,     7,    35,
       9,    10,    11,    12,     3,    14,    15,    16,    17,    18,
      19,    20,    21,    22,    23,    24,    25,    26,    27,    28,
      29,    35,     4,    35,    35,     7,    35,     9,    10,    11,
      12,    35,    14,    15,    16,    17,    18,    19,    20,    21,
      22,    23,    24,    25,    26,    27,    28,    29,    35,     4,
      35,    35,     7,    35,     9,    10,    11,    12,    35,    14,
      15,    16,    17,    18,    19,    20,    21,    22,    23,    24,
      25,    26,    27,    28,    29,    35,     4,    35,    35,     7,
      35,     9,    10,    11,    12,    35,    14,    15,    16,    17,
      18,    19,    20,    21,    22,    23,    24,    25,    26,    27,
      28,    29,    35,     4,    35,    35,     7,    35,     9,    10,
      11,    12,    35,    14,    15,    16,    17,    18,    19,    20,
      21,    22,    23,    24,    25,    26,    27,    28,    29,    35,
       4,     3,    14,     7,    35,     9,    10,    11,    12,     3,
       3,    15,    16,    17,    18,    19,    20,    21,    22,    23,
      24,    25,    26,    27,    28,    29,     5,     8,    35,     3,
       3,    35,    30,    31,    32,    33,    34,    35,    36,     3,
       3,     3,     3,     3,     3,     3,     3,     3,     3,     3,
       3,   103,     3,    24,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    13
};

/* YYSTOS[STATE-NUM] -- The symbol kind of the accessing symbol of
   state STATE-NUM.  */
static const yytype_int8 yystos[] =
{
       0,     4,     7,     9,    10,    11,    12,    15,    16,    17,
      18,    19,    20,    21,    22,    23,    24,    25,    26,    27,
      28,    29,    35,    39,    40,    41,    42,    43,    47,    49,
      50,    51,    52,    54,    55,    57,    58,    59,    60,    62,
      63,     5,     6,    13,    13,    30,    31,    32,    33,    34,
      35,    36,    48,     3,     3,    35,    35,    35,    35,    35,
      35,    35,    35,    35,    35,    35,    35,    35,    35,    35,
      61,     0,    41,    46,    35,    35,    35,    35,     3,    35,
      48,    48,    48,    48,    48,    48,    48,    48,    48,    48,
      48,    48,    48,    48,     3,    48,     4,    14,    47,     3,
      14,     4,    13,    44,    45,     3,    48,    48,    48,    48,
      48,    48,    48,    48,     3,    48,    48,    48,    48,    48,
      48,     8,    56,    48,    35,    46,    13,    45,     3,     3,
       3,     3,     3,     3,     3,     3,     3,     3,     3,     3,
       3,     3,    13,    46,     3,    14,    46,    53,    14,    14,
      46,    14
};

/* YYR1[RULE-NUM] -- Symbol kind of the left-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr1[] =
{
       0,    38,    39,    39,    40,    40,    41,    41,    42,    42,
      43,    43,    44,    44,    45,    46,    46,    47,    47,    47,
      47,    47,    47,    47,    47,    47,    47,    47,    48,    48,
      48,    48,    48,    48,    48,    49,    49,    49,    49,    49,
      49,    49,    49,    49,    49,    49,    49,    50,    51,    52,
      53,    52,    54,    56,    55,    57,    58,    59,    60,    61,
      61,    62,    63
};

/* YYR2[RULE-NUM] -- Number of symbols on the right-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr2[] =
{
       0,     2,     1,     0,     2,     1,     1,     1,     4,     6,
       7,     6,     2,     1,     2,     2,     0,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     5,     5,     5,     5,     5,
       5,     5,     5,     5,     5,     5,     5,     4,     4,     3,
       0,     8,     2,     0,     6,     3,     2,     2,     3,     2,
       0,     5,     5
};


enum { YYENOMEM = -2 };

#define yyerrok         (yyerrstatus = 0)
#define yyclearin       (yychar = YYEMPTY)

#define YYACCEPT        goto yyacceptlab
#define YYABORT         goto yyabortlab
#define YYERROR         goto yyerrorlab
#define YYNOMEM         goto yyexhaustedlab


#define YYRECOVERING()  (!!yyerrstatus)

#define YYBACKUP(Token, Value)                                    \
  do                                                              \
    if (yychar == YYEMPTY)                                        \
      {                                                           \
        yychar = (Token);                                         \
        yylval = (Value);                                         \
        YYPOPSTACK (yylen);                                       \
        yystate = *yyssp;                                         \
        goto yybackup;                                            \
      }                                                           \
    else                                                          \
      {                                                           \
        yyerror (YY_("syntax error: cannot back up")); \
        YYERROR;                                                  \
      }                                                           \
  while (0)

/* Backward compatibility with an undocumented macro.
   Use YYerror or YYUNDEF. */
#define YYERRCODE YYUNDEF


/* Enable debugging if requested.  */
#if YYDEBUG

# ifndef YYFPRINTF
#  include <stdio.h> /* INFRINGES ON USER NAME SPACE */
#  define YYFPRINTF fprintf
# endif

# define YYDPRINTF(Args)                        \
do {                                            \
  if (yydebug)                                  \
    YYFPRINTF Args;                             \
} while (0)




# define YY_SYMBOL_PRINT(Title, Kind, Value, Location)                    \
do {                                                                      \
  if (yydebug)                                                            \
    {                                                                     \
      YYFPRINTF (stderr, "%s ", Title);                                   \
      yy_symbol_print (stderr,                                            \
                  Kind, Value); \
      YYFPRINTF (stderr, "\n");                                           \
    }                                                                     \
} while (0)


/*-----------------------------------.
| Print this symbol's value on YYO.  |
`-----------------------------------*/

static void
yy_symbol_value_print (FILE *yyo,
                       yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep)
{
  FILE *yyoutput = yyo;
  YY_USE (yyoutput);
  if (!yyvaluep)
    return;
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  YY_USE (yykind);
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}


/*---------------------------.
| Print this symbol on YYO.  |
`---------------------------*/

static void
yy_symbol_print (FILE *yyo,
                 yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep)
{
  YYFPRINTF (yyo, "%s %s (",
             yykind < YYNTOKENS ? "token" : "nterm", yysymbol_name (yykind));

  yy_symbol_value_print (yyo, yykind, yyvaluep);
  YYFPRINTF (yyo, ")");
}

/*------------------------------------------------------------------.
| yy_stack_print -- Print the state stack from its BOTTOM up to its |
| TOP (included).                                                   |
`------------------------------------------------------------------*/

static void
yy_stack_print (yy_state_t *yybottom, yy_state_t *yytop)
{
  YYFPRINTF (stderr, "Stack now");
  for (; yybottom <= yytop; yybottom++)
    {
      int yybot = *yybottom;
      YYFPRINTF (stderr, " %d", yybot);
    }
  YYFPRINTF (stderr, "\n");
}

# define YY_STACK_PRINT(Bottom, Top)                            \
do {                                                            \
  if (yydebug)                                                  \
    yy_stack_print ((Bottom), (Top));                           \
} while (0)


/*------------------------------------------------.
| Report that the YYRULE is going to be reduced.  |
`------------------------------------------------*/

static void
yy_reduce_print (yy_state_t *yyssp, YYSTYPE *yyvsp,
                 int yyrule)
{
  int yylno = yyrline[yyrule];
  int yynrhs = yyr2[yyrule];
  int yyi;
  YYFPRINTF (stderr, "Reducing stack by rule %d (line %d):\n",
             yyrule - 1, yylno);
  /* The symbols being reduced.  */
  for (yyi = 0; yyi < yynrhs; yyi++)
    {
      YYFPRINTF (stderr, "   $%d = ", yyi + 1);
      yy_symbol_print (stderr,
                       YY_ACCESSING_SYMBOL (+yyssp[yyi + 1 - yynrhs]),
                       &yyvsp[(yyi + 1) - (yynrhs)]);
      YYFPRINTF (stderr, "\n");
    }
}

# define YY_REDUCE_PRINT(Rule)          \
do {                                    \
  if (yydebug)                          \
    yy_reduce_print (yyssp, yyvsp, Rule); \
} while (0)

/* Nonzero means print parse trace.  It is left uninitialized so that
   multiple parsers can coexist.  */
int yydebug;
#else /* !YYDEBUG */
# define YYDPRINTF(Args) ((void) 0)
# define YY_SYMBOL_PRINT(Title, Kind, Value, Location)
# define YY_STACK_PRINT(Bottom, Top)
# define YY_REDUCE_PRINT(Rule)
#endif /* !YYDEBUG */


/* YYINITDEPTH -- initial size of the parser's stacks.  */
#ifndef YYINITDEPTH
# define YYINITDEPTH 200
#endif

/* YYMAXDEPTH -- maximum size the stacks can grow to (effective only
   if the built-in stack extension method is used).

   Do not make this value too large; the results are undefined if
   YYSTACK_ALLOC_MAXIMUM < YYSTACK_BYTES (YYMAXDEPTH)
   evaluated with infinite-precision integer arithmetic.  */

#ifndef YYMAXDEPTH
# define YYMAXDEPTH 10000
#endif






/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

static void
yydestruct (const char *yymsg,
            yysymbol_kind_t yykind, YYSTYPE *yyvaluep)
{
  YY_USE (yyvaluep);
  if (!yymsg)
    yymsg = "Deleting";
  YY_SYMBOL_PRINT (yymsg, yykind, yyvaluep, yylocationp);

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  YY_USE (yykind);
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}


/* Lookahead token kind.  */
int yychar;

/* The semantic value of the lookahead symbol.  */
YYSTYPE yylval;
/* Number of syntax errors so far.  */
int yynerrs;




/*----------.
| yyparse.  |
`----------*/

int
yyparse (void)
{
    yy_state_fast_t yystate = 0;
    /* Number of tokens to shift before error messages enabled.  */
    int yyerrstatus = 0;

    /* Refer to the stacks through separate pointers, to allow yyoverflow
       to reallocate them elsewhere.  */

    /* Their size.  */
    YYPTRDIFF_T yystacksize = YYINITDEPTH;

    /* The state stack: array, bottom, top.  */
    yy_state_t yyssa[YYINITDEPTH];
    yy_state_t *yyss = yyssa;
    yy_state_t *yyssp = yyss;

    /* The semantic value stack: array, bottom, top.  */
    YYSTYPE yyvsa[YYINITDEPTH];
    YYSTYPE *yyvs = yyvsa;
    YYSTYPE *yyvsp = yyvs;

  int yyn;
  /* The return value of yyparse.  */
  int yyresult;
  /* Lookahead symbol kind.  */
  yysymbol_kind_t yytoken = YYSYMBOL_YYEMPTY;
  /* The variables used to return semantic value and location from the
     action routines.  */
  YYSTYPE yyval;



#define YYPOPSTACK(N)   (yyvsp -= (N), yyssp -= (N))

  /* The number of symbols on the RHS of the reduced rule.
     Keep to zero when no symbol should be popped.  */
  int yylen = 0;

  YYDPRINTF ((stderr, "Starting parse\n"));

  yychar = YYEMPTY; /* Cause a token to be read.  */

  goto yysetstate;


/*------------------------------------------------------------.
| yynewstate -- push a new state, which is found in yystate.  |
`------------------------------------------------------------*/
yynewstate:
  /* In all cases, when you get here, the value and location stacks
     have just been pushed.  So pushing a state here evens the stacks.  */
  yyssp++;


/*--------------------------------------------------------------------.
| yysetstate -- set current state (the top of the stack) to yystate.  |
`--------------------------------------------------------------------*/
yysetstate:
  YYDPRINTF ((stderr, "Entering state %d\n", yystate));
  YY_ASSERT (0 <= yystate && yystate < YYNSTATES);
  YY_IGNORE_USELESS_CAST_BEGIN
  *yyssp = YY_CAST (yy_state_t, yystate);
  YY_IGNORE_USELESS_CAST_END
  YY_STACK_PRINT (yyss, yyssp);

  if (yyss + yystacksize - 1 <= yyssp)
#if !defined yyoverflow && !defined YYSTACK_RELOCATE
    YYNOMEM;
#else
    {
      /* Get the current used size of the three stacks, in elements.  */
      YYPTRDIFF_T yysize = yyssp - yyss + 1;

# if defined yyoverflow
      {
        /* Give user a chance to reallocate the stack.  Use copies of
           these so that the &'s don't force the real ones into
           memory.  */
        yy_state_t *yyss1 = yyss;
        YYSTYPE *yyvs1 = yyvs;

        /* Each stack pointer address is followed by the size of the
           data in use in that stack, in bytes.  This used to be a
           conditional around just the two extra args, but that might
           be undefined if yyoverflow is a macro.  */
        yyoverflow (YY_("memory exhausted"),
                    &yyss1, yysize * YYSIZEOF (*yyssp),
                    &yyvs1, yysize * YYSIZEOF (*yyvsp),
                    &yystacksize);
        yyss = yyss1;
        yyvs = yyvs1;
      }
# else /* defined YYSTACK_RELOCATE */
      /* Extend the stack our own way.  */
      if (YYMAXDEPTH <= yystacksize)
        YYNOMEM;
      yystacksize *= 2;
      if (YYMAXDEPTH < yystacksize)
        yystacksize = YYMAXDEPTH;

      {
        yy_state_t *yyss1 = yyss;
        union yyalloc *yyptr =
          YY_CAST (union yyalloc *,
                   YYSTACK_ALLOC (YY_CAST (YYSIZE_T, YYSTACK_BYTES (yystacksize))));
        if (! yyptr)
          YYNOMEM;
        YYSTACK_RELOCATE (yyss_alloc, yyss);
        YYSTACK_RELOCATE (yyvs_alloc, yyvs);
#  undef YYSTACK_RELOCATE
        if (yyss1 != yyssa)
          YYSTACK_FREE (yyss1);
      }
# endif

      yyssp = yyss + yysize - 1;
      yyvsp = yyvs + yysize - 1;

      YY_IGNORE_USELESS_CAST_BEGIN
      YYDPRINTF ((stderr, "Stack size increased to %ld\n",
                  YY_CAST (long, yystacksize)));
      YY_IGNORE_USELESS_CAST_END

      if (yyss + yystacksize - 1 <= yyssp)
        YYABORT;
    }
#endif /* !defined yyoverflow && !defined YYSTACK_RELOCATE */


  if (yystate == YYFINAL)
    YYACCEPT;

  goto yybackup;


/*-----------.
| yybackup.  |
`-----------*/
yybackup:
  /* Do appropriate processing given the current state.  Read a
     lookahead token if we need one and don't already have one.  */

  /* First try to decide what to do without reference to lookahead token.  */
  yyn = yypact[yystate];
  if (yypact_value_is_default (yyn))
    goto yydefault;

  /* Not known => get a lookahead token if don't already have one.  */

  /* YYCHAR is either empty, or end-of-input, or a valid lookahead.  */
  if (yychar == YYEMPTY)
    {
      YYDPRINTF ((stderr, "Reading a token\n"));
      yychar = yylex ();
    }

  if (yychar <= YYEOF)
    {
      yychar = YYEOF;
      yytoken = YYSYMBOL_YYEOF;
      YYDPRINTF ((stderr, "Now at end of input.\n"));
    }
  else if (yychar == YYerror)
    {
      /* The scanner already issued an error message, process directly
         to error recovery.  But do not keep the error token as
         lookahead, it is too special and may lead us to an endless
         loop in error recovery. */
      yychar = YYUNDEF;
      yytoken = YYSYMBOL_YYerror;
      goto yyerrlab1;
    }
  else
    {
      yytoken = YYTRANSLATE (yychar);
      YY_SYMBOL_PRINT ("Next token is", yytoken, &yylval, &yylloc);
    }

  /* If the proper action on seeing token YYTOKEN is to reduce or to
     detect an error, take that action.  */
  yyn += yytoken;
  if (yyn < 0 || YYLAST < yyn || yycheck[yyn] != yytoken)
    goto yydefault;
  yyn = yytable[yyn];
  if (yyn <= 0)
    {
      if (yytable_value_is_error (yyn))
        goto yyerrlab;
      yyn = -yyn;
      goto yyreduce;
    }

  /* Count tokens shifted since error; after three, turn off error
     status.  */
  if (yyerrstatus)
    yyerrstatus--;

  /* Shift the lookahead token.  */
  YY_SYMBOL_PRINT ("Shifting", yytoken, &yylval, &yylloc);
  yystate = yyn;
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END

  /* Discard the shifted token.  */
  yychar = YYEMPTY;
  goto yynewstate;


/*-----------------------------------------------------------.
| yydefault -- do the default action for the current state.  |
`-----------------------------------------------------------*/
yydefault:
  yyn = yydefact[yystate];
  if (yyn == 0)
    goto yyerrlab;
  goto yyreduce;


/*-----------------------------.
| yyreduce -- do a reduction.  |
`-----------------------------*/
yyreduce:
  /* yyn is the number of a rule to reduce with.  */
  yylen = yyr2[yyn];

  /* If YYLEN is nonzero, implement the default value of the action:
     '$$ = $1'.

     Otherwise, the following line sets YYVAL to garbage.
     This behavior is undocumented and Bison
     users should not rely upon it.  Assigning to YYVAL
     unconditionally makes the parser a bit smaller, and it avoids a
     GCC warning that YYVAL may be used uninitialized.  */
  yyval = yyvsp[1-yylen];


  YY_REDUCE_PRINT (yyn);
  switch (yyn)
    {
  case 8: /* var_decl: TIPO VAR ID END_BLOCO  */
#line 89 "yacc/translate.y"
        { inserir_simbolo((yyvsp[-1].sval), (yyvsp[-3].sval), "variavel", yylineno); }
#line 1260 "yacc/translate.tab.c"
    break;

  case 9: /* var_decl: TIPO VAR ID END_BLOCO operando FIM_LINHA  */
#line 91 "yacc/translate.y"
        { inserir_simbolo((yyvsp[-3].sval), (yyvsp[-5].sval), "variavel", yylineno); }
#line 1266 "yacc/translate.tab.c"
    break;

  case 10: /* func_decl: TIPO FUNC ID param_list BLOCO_INI stmt_list END_BLOCO  */
#line 97 "yacc/translate.y"
        { inserir_simbolo((yyvsp[-4].sval), (yyvsp[-6].sval), "funcao", yylineno); }
#line 1272 "yacc/translate.tab.c"
    break;

  case 11: /* func_decl: TIPO FUNC ID BLOCO_INI stmt_list END_BLOCO  */
#line 99 "yacc/translate.y"
        { inserir_simbolo((yyvsp[-3].sval), (yyvsp[-5].sval), "funcao", yylineno); }
#line 1278 "yacc/translate.tab.c"
    break;

  case 14: /* param: TIPO ID  */
#line 109 "yacc/translate.y"
        { inserir_simbolo((yyvsp[0].sval), (yyvsp[-1].sval), "parametro", yylineno); }
#line 1284 "yacc/translate.tab.c"
    break;

  case 28: /* operando: ID  */
#line 134 "yacc/translate.y"
                   { strcpy((yyval.sval), (yyvsp[0].sval)); }
#line 1290 "yacc/translate.tab.c"
    break;

  case 29: /* operando: LIT_INT  */
#line 135 "yacc/translate.y"
                   { sprintf((yyval.sval), "%d", (yyvsp[0].ival)); }
#line 1296 "yacc/translate.tab.c"
    break;

  case 30: /* operando: LIT_FLOAT  */
#line 136 "yacc/translate.y"
                   { sprintf((yyval.sval), "%.2f", (yyvsp[0].fval)); }
#line 1302 "yacc/translate.tab.c"
    break;

  case 31: /* operando: LIT_CHAR  */
#line 137 "yacc/translate.y"
                   { strcpy((yyval.sval), (yyvsp[0].sval)); }
#line 1308 "yacc/translate.tab.c"
    break;

  case 32: /* operando: LIT_STRING  */
#line 138 "yacc/translate.y"
                   { strcpy((yyval.sval), (yyvsp[0].sval)); }
#line 1314 "yacc/translate.tab.c"
    break;

  case 33: /* operando: LIT_BOOL  */
#line 139 "yacc/translate.y"
                   { sprintf((yyval.sval), "%d", (yyvsp[0].ival)); }
#line 1320 "yacc/translate.tab.c"
    break;

  case 34: /* operando: ACORDE_LIVRE  */
#line 140 "yacc/translate.y"
                   { strcpy((yyval.sval), (yyvsp[0].sval)); }
#line 1326 "yacc/translate.tab.c"
    break;

  case 35: /* op_binario: OP_ADD ID operando operando FIM_LINHA  */
#line 145 "yacc/translate.y"
                                            { gci_emitir_operacao("ADD", (yyvsp[-3].sval), (yyvsp[-2].sval), (yyvsp[-1].sval)); }
#line 1332 "yacc/translate.tab.c"
    break;

  case 36: /* op_binario: OP_SUB ID operando operando FIM_LINHA  */
#line 146 "yacc/translate.y"
                                            { gci_emitir_operacao("SUB", (yyvsp[-3].sval), (yyvsp[-2].sval), (yyvsp[-1].sval)); }
#line 1338 "yacc/translate.tab.c"
    break;

  case 37: /* op_binario: OP_MUL ID operando operando FIM_LINHA  */
#line 147 "yacc/translate.y"
                                            { gci_emitir_operacao("MUL", (yyvsp[-3].sval), (yyvsp[-2].sval), (yyvsp[-1].sval)); }
#line 1344 "yacc/translate.tab.c"
    break;

  case 38: /* op_binario: OP_DIV ID operando operando FIM_LINHA  */
#line 148 "yacc/translate.y"
                                            { gci_emitir_operacao("DIV", (yyvsp[-3].sval), (yyvsp[-2].sval), (yyvsp[-1].sval)); }
#line 1350 "yacc/translate.tab.c"
    break;

  case 39: /* op_binario: OP_AND ID operando operando FIM_LINHA  */
#line 149 "yacc/translate.y"
                                            { gci_emitir_operacao("AND", (yyvsp[-3].sval), (yyvsp[-2].sval), (yyvsp[-1].sval)); }
#line 1356 "yacc/translate.tab.c"
    break;

  case 40: /* op_binario: OP_OR ID operando operando FIM_LINHA  */
#line 150 "yacc/translate.y"
                                            { gci_emitir_operacao("OR",  (yyvsp[-3].sval), (yyvsp[-2].sval), (yyvsp[-1].sval)); }
#line 1362 "yacc/translate.tab.c"
    break;

  case 41: /* op_binario: OP_EQ ID operando operando FIM_LINHA  */
#line 151 "yacc/translate.y"
                                            { gci_emitir_operacao("SEQ", (yyvsp[-3].sval), (yyvsp[-2].sval), (yyvsp[-1].sval)); }
#line 1368 "yacc/translate.tab.c"
    break;

  case 42: /* op_binario: OP_NEQ ID operando operando FIM_LINHA  */
#line 152 "yacc/translate.y"
                                            { gci_emitir_operacao("SNE", (yyvsp[-3].sval), (yyvsp[-2].sval), (yyvsp[-1].sval)); }
#line 1374 "yacc/translate.tab.c"
    break;

  case 43: /* op_binario: OP_GT ID operando operando FIM_LINHA  */
#line 153 "yacc/translate.y"
                                            { gci_emitir_operacao("SGT", (yyvsp[-3].sval), (yyvsp[-2].sval), (yyvsp[-1].sval)); }
#line 1380 "yacc/translate.tab.c"
    break;

  case 44: /* op_binario: OP_LT ID operando operando FIM_LINHA  */
#line 154 "yacc/translate.y"
                                            { gci_emitir_operacao("SLT", (yyvsp[-3].sval), (yyvsp[-2].sval), (yyvsp[-1].sval)); }
#line 1386 "yacc/translate.tab.c"
    break;

  case 45: /* op_binario: OP_GTE ID operando operando FIM_LINHA  */
#line 155 "yacc/translate.y"
                                            { gci_emitir_operacao("SGE", (yyvsp[-3].sval), (yyvsp[-2].sval), (yyvsp[-1].sval)); }
#line 1392 "yacc/translate.tab.c"
    break;

  case 46: /* op_binario: OP_LTE ID operando operando FIM_LINHA  */
#line 156 "yacc/translate.y"
                                            { gci_emitir_operacao("SLE", (yyvsp[-3].sval), (yyvsp[-2].sval), (yyvsp[-1].sval)); }
#line 1398 "yacc/translate.tab.c"
    break;

  case 47: /* op_unario: OP_NOT ID operando FIM_LINHA  */
#line 160 "yacc/translate.y"
                                   { gci_emitir_unario("NOT", (yyvsp[-2].sval), (yyvsp[-1].sval)); }
#line 1404 "yacc/translate.tab.c"
    break;

  case 48: /* if_prefix: IF BLOCO_INI ID FIM_LINHA  */
#line 166 "yacc/translate.y"
        {
            strcpy((yyval.sval), gci_nova_label());
            gci_emitir_jump_condicional((yyvsp[-1].sval), (yyval.sval));
        }
#line 1413 "yacc/translate.tab.c"
    break;

  case 49: /* if_stmt: if_prefix stmt_list END_BLOCO  */
#line 174 "yacc/translate.y"
        {
            gci_emitir_label((yyvsp[-2].sval)); 
        }
#line 1421 "yacc/translate.tab.c"
    break;

  case 50: /* @1: %empty  */
#line 178 "yacc/translate.y"
        {
            strcpy((yyval.sval), gci_nova_label()); 
            gci_emitir_jump((yyval.sval));   
            gci_emitir_label((yyvsp[-4].sval));  
        }
#line 1431 "yacc/translate.tab.c"
    break;

  case 51: /* if_stmt: if_prefix stmt_list END_BLOCO ELSE BLOCO_INI @1 stmt_list END_BLOCO  */
#line 184 "yacc/translate.y"
        {
            gci_emitir_label((yyvsp[-2].sval));
        }
#line 1439 "yacc/translate.tab.c"
    break;

  case 52: /* while_prefix: WHILE BLOCO_INI  */
#line 191 "yacc/translate.y"
        {
            char* inicio = gci_nova_label();
            char* fim = gci_nova_label();
            gci_push_while(inicio, fim);
            
            gci_emitir_label(inicio);
            strcpy((yyval.sval), fim);
        }
#line 1452 "yacc/translate.tab.c"
    break;

  case 53: /* $@2: %empty  */
#line 203 "yacc/translate.y"
        {
            gci_emitir_jump_condicional((yyvsp[-1].sval), (yyvsp[-2].sval));
        }
#line 1460 "yacc/translate.tab.c"
    break;

  case 54: /* while_stmt: while_prefix ID FIM_LINHA $@2 stmt_list END_BLOCO  */
#line 207 "yacc/translate.y"
        {
            gci_emitir_jump(gci_get_while_inicio());
            gci_emitir_label(gci_get_while_fim());
            gci_pop_while();
        }
#line 1470 "yacc/translate.tab.c"
    break;

  case 56: /* break_stmt: KW_BREAK FIM_LINHA  */
#line 220 "yacc/translate.y"
        { gci_emitir_jump(gci_get_while_fim()); }
#line 1476 "yacc/translate.tab.c"
    break;

  case 57: /* continue_stmt: KW_CONTINUE FIM_LINHA  */
#line 225 "yacc/translate.y"
        { gci_emitir_jump(gci_get_while_inicio()); }
#line 1482 "yacc/translate.tab.c"
    break;

  case 58: /* func_call_stmt: ID operando_list FIM_LINHA  */
#line 231 "yacc/translate.y"
        { gci_emitir_call("dest", (yyvsp[-2].sval)); }
#line 1488 "yacc/translate.tab.c"
    break;

  case 61: /* read_list_stmt: READ_LIST ID ID operando FIM_LINHA  */
#line 241 "yacc/translate.y"
        { gci_emitir_read_list((yyvsp[-3].sval), (yyvsp[-2].sval), (yyvsp[-1].sval)); }
#line 1494 "yacc/translate.tab.c"
    break;

  case 62: /* write_list_stmt: WRITE_LIST ID operando operando FIM_LINHA  */
#line 246 "yacc/translate.y"
        { gci_emitir_write_list((yyvsp[-3].sval), (yyvsp[-2].sval), (yyvsp[-1].sval)); }
#line 1500 "yacc/translate.tab.c"
    break;


#line 1504 "yacc/translate.tab.c"

      default: break;
    }
  /* User semantic actions sometimes alter yychar, and that requires
     that yytoken be updated with the new translation.  We take the
     approach of translating immediately before every use of yytoken.
     One alternative is translating here after every semantic action,
     but that translation would be missed if the semantic action invokes
     YYABORT, YYACCEPT, or YYERROR immediately after altering yychar or
     if it invokes YYBACKUP.  In the case of YYABORT or YYACCEPT, an
     incorrect destructor might then be invoked immediately.  In the
     case of YYERROR or YYBACKUP, subsequent parser actions might lead
     to an incorrect destructor call or verbose syntax error message
     before the lookahead is translated.  */
  YY_SYMBOL_PRINT ("-> $$ =", YY_CAST (yysymbol_kind_t, yyr1[yyn]), &yyval, &yyloc);

  YYPOPSTACK (yylen);
  yylen = 0;

  *++yyvsp = yyval;

  /* Now 'shift' the result of the reduction.  Determine what state
     that goes to, based on the state we popped back to and the rule
     number reduced by.  */
  {
    const int yylhs = yyr1[yyn] - YYNTOKENS;
    const int yyi = yypgoto[yylhs] + *yyssp;
    yystate = (0 <= yyi && yyi <= YYLAST && yycheck[yyi] == *yyssp
               ? yytable[yyi]
               : yydefgoto[yylhs]);
  }

  goto yynewstate;


/*--------------------------------------.
| yyerrlab -- here on detecting error.  |
`--------------------------------------*/
yyerrlab:
  /* Make sure we have latest lookahead translation.  See comments at
     user semantic actions for why this is necessary.  */
  yytoken = yychar == YYEMPTY ? YYSYMBOL_YYEMPTY : YYTRANSLATE (yychar);
  /* If not already recovering from an error, report this error.  */
  if (!yyerrstatus)
    {
      ++yynerrs;
      yyerror (YY_("syntax error"));
    }

  if (yyerrstatus == 3)
    {
      /* If just tried and failed to reuse lookahead token after an
         error, discard it.  */

      if (yychar <= YYEOF)
        {
          /* Return failure if at end of input.  */
          if (yychar == YYEOF)
            YYABORT;
        }
      else
        {
          yydestruct ("Error: discarding",
                      yytoken, &yylval);
          yychar = YYEMPTY;
        }
    }

  /* Else will try to reuse lookahead token after shifting the error
     token.  */
  goto yyerrlab1;


/*---------------------------------------------------.
| yyerrorlab -- error raised explicitly by YYERROR.  |
`---------------------------------------------------*/
yyerrorlab:
  /* Pacify compilers when the user code never invokes YYERROR and the
     label yyerrorlab therefore never appears in user code.  */
  if (0)
    YYERROR;
  ++yynerrs;

  /* Do not reclaim the symbols of the rule whose action triggered
     this YYERROR.  */
  YYPOPSTACK (yylen);
  yylen = 0;
  YY_STACK_PRINT (yyss, yyssp);
  yystate = *yyssp;
  goto yyerrlab1;


/*-------------------------------------------------------------.
| yyerrlab1 -- common code for both syntax error and YYERROR.  |
`-------------------------------------------------------------*/
yyerrlab1:
  yyerrstatus = 3;      /* Each real token shifted decrements this.  */

  /* Pop stack until we find a state that shifts the error token.  */
  for (;;)
    {
      yyn = yypact[yystate];
      if (!yypact_value_is_default (yyn))
        {
          yyn += YYSYMBOL_YYerror;
          if (0 <= yyn && yyn <= YYLAST && yycheck[yyn] == YYSYMBOL_YYerror)
            {
              yyn = yytable[yyn];
              if (0 < yyn)
                break;
            }
        }

      /* Pop the current state because it cannot handle the error token.  */
      if (yyssp == yyss)
        YYABORT;


      yydestruct ("Error: popping",
                  YY_ACCESSING_SYMBOL (yystate), yyvsp);
      YYPOPSTACK (1);
      yystate = *yyssp;
      YY_STACK_PRINT (yyss, yyssp);
    }

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END


  /* Shift the error token.  */
  YY_SYMBOL_PRINT ("Shifting", YY_ACCESSING_SYMBOL (yyn), yyvsp, yylsp);

  yystate = yyn;
  goto yynewstate;


/*-------------------------------------.
| yyacceptlab -- YYACCEPT comes here.  |
`-------------------------------------*/
yyacceptlab:
  yyresult = 0;
  goto yyreturnlab;


/*-----------------------------------.
| yyabortlab -- YYABORT comes here.  |
`-----------------------------------*/
yyabortlab:
  yyresult = 1;
  goto yyreturnlab;


/*-----------------------------------------------------------.
| yyexhaustedlab -- YYNOMEM (memory exhaustion) comes here.  |
`-----------------------------------------------------------*/
yyexhaustedlab:
  yyerror (YY_("memory exhausted"));
  yyresult = 2;
  goto yyreturnlab;


/*----------------------------------------------------------.
| yyreturnlab -- parsing is finished, clean up and return.  |
`----------------------------------------------------------*/
yyreturnlab:
  if (yychar != YYEMPTY)
    {
      /* Make sure we have latest lookahead translation.  See comments at
         user semantic actions for why this is necessary.  */
      yytoken = YYTRANSLATE (yychar);
      yydestruct ("Cleanup: discarding lookahead",
                  yytoken, &yylval);
    }
  /* Do not reclaim the symbols of the rule whose action triggered
     this YYABORT or YYACCEPT.  */
  YYPOPSTACK (yylen);
  YY_STACK_PRINT (yyss, yyssp);
  while (yyssp != yyss)
    {
      yydestruct ("Cleanup: popping",
                  YY_ACCESSING_SYMBOL (+*yyssp), yyvsp);
      YYPOPSTACK (1);
    }
#ifndef yyoverflow
  if (yyss != yyssa)
    YYSTACK_FREE (yyss);
#endif

  return yyresult;
}

#line 249 "yacc/translate.y"

/* --- Codigo C Auxiliar --- */

static Tipo tipo_de_texto(const char *tipo)
{
    if (strcmp(tipo, "int") == 0 || strcmp(tipo, "C/G") == 0) return TIPO_INT;
    if (strcmp(tipo, "float") == 0 || strcmp(tipo, "Am/E") == 0) return TIPO_FLOAT;
    if (strcmp(tipo, "bool") == 0 || strcmp(tipo, "Em/B") == 0) return TIPO_BOOL;
    if (strcmp(tipo, "char") == 0 || strcmp(tipo, "F/C") == 0) return TIPO_CHAR;
    if (strcmp(tipo, "null") == 0 || strcmp(tipo, "G/D") == 0) return TIPO_NULL;
    if (strcmp(tipo, "lista") == 0 || strcmp(tipo, "C7") == 0) return TIPO_LISTA;
    return TIPO_NULL;
}

static Categoria categoria_de_texto(const char *categoria)
{
    if (strcmp(categoria, "funcao") == 0) return CAT_FUNCAO;
    if (strcmp(categoria, "parametro") == 0) return CAT_PARAMETRO;
    return CAT_VARIAVEL;
}

static void inserir_simbolo(const char *nome, const char *tipo, const char *categoria, int linha)
{
    if (tabelaAtual == NULL)
    {
        return;
    }

    inserirSimbolo(
        tabelaAtual,
        criarSimbolo(
            (char *)nome,
            tipo_de_texto(tipo),
            categoria_de_texto(categoria),
            linha
        )
    );
}

void yyerror(const char *msg)
{
    (void)msg;
    printf("Erro próximo a linha %d - Programa sintaticamente incorreto\n", yylineno);
}
