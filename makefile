CC      = gcc
CFLAGS  = -I yacc -I tabela_simbolos -I gci
TARGET  = soundy

YACC_SRC = yacc/translate.y
YACC_C   = yacc/translate.tab.c
YACC_H   = yacc/translate.tab.h

LEX_SRC  = lex/soundy.l
LEX_C    = lex/lex.yy.c

TABELA_C = tabela_simbolos/TabelaSimbolo.c
MAIN_C   = tabela_simbolos/main.c

GCI_C = gci/gci.c

TESTES   = testes/teste_funcao_musical.sndy \
           testes/teste_if_else_musical.sndy \
           testes/teste_lista_musical.sndy \
           testes/teste_while_musical.sndy \
           testes/teste_incorreto_musical.sndy \
           testes/teste_semantico.sndy

# -------------------------------------------------------------------

all: $(TARGET)

$(TARGET): $(YACC_C) $(LEX_C)
	$(CC) $(CFLAGS) $(YACC_C) $(LEX_C) $(TABELA_C) $(GCI_C) $(MAIN_C) -o $(TARGET)

$(YACC_C) $(YACC_H): $(YACC_SRC)
	bison -d -o $(YACC_C) $(YACC_SRC)

$(LEX_C): $(LEX_SRC) $(YACC_H)
	flex -o $(LEX_C) $(LEX_SRC)

# -------------------------------------------------------------------

test: $(TARGET)
	@echo "========================================"
	@for f in $(TESTES); do \
		echo ">> Testando: $$f"; \
		./$(TARGET) $$f && echo "[OK]" || echo "[ERRO]"; \
		echo "----------------------------------------"; \
	done

# -------------------------------------------------------------------

clean:
	rm -f $(YACC_C) $(YACC_H) $(LEX_C) $(TARGET)

.PHONY: all test clean
