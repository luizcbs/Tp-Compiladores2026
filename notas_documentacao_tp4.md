# Notas para documentação do TP4

- Documentar que o assembly gerado termina no rótulo interno `__applause` com a instrução `BRK`.
- Justificativa: no Easy6502, `BRK` encerra a execução e facilita verificar os valores finais na memória.
- Observação técnica: em um MOS6502 real, `BRK` representa uma interrupção de software; neste trabalho, ele é usado como mecanismo de parada no emulador.

## Otimizações implementadas no GCI/ASM

### 1. Desdobramento de constantes

- Quando uma operação aritmética ou lógica possui operandos literais, o compilador calcula o resultado em tempo de compilação.
- Exemplo conceitual:
  - Antes: `ADD A, 3, 4`
  - Depois: `COPY A, 7`
- Benefício: evita gerar instruções assembly para uma conta cujo resultado já é conhecido antes da execução.
- Observação: comparações relacionais foram preservadas como comparação, mesmo quando os operandos são constantes, para garantir que o resultado booleano seja gravado como `0` ou `1` na variável de destino.

### 2. Identidades algébricas

- Operações com elementos neutros ou absorventes são simplificadas.
- Exemplos:
  - `ADD A, B, 0` vira `COPY A, B`
  - `SUB A, B, 0` vira `COPY A, B`
  - `MUL A, B, 1` vira `COPY A, B`
  - `MUL A, B, 0` vira `COPY A, 0`
  - `DIV A, B, 1` vira `COPY A, B`
  - `AND A, B, 0` vira `COPY A, 0`
  - `OR A, B, 0` vira `COPY A, B`
- Benefício: reduz instruções desnecessárias e evita chamar sub-rotinas caras, como multiplicação/divisão, quando o resultado é trivial.

### 3. Redução de esforço

- Multiplicação por `2` é convertida em soma do operando com ele mesmo.
- Exemplo conceitual:
  - Antes: `MUL A, B, 2`
  - Depois: `ADD A, B, B`
- Justificativa: o MOS6502 não possui instrução nativa de multiplicação; multiplicar exige uma sub-rotina com laço. Somar é muito mais barato.

### 4. Propagação local de constantes

- Dentro de um bloco básico, quando uma variável recebe uma constante, usos seguintes dessa variável podem ser substituídos pelo valor literal.
- Exemplo conceitual:
  - Antes:
    - `COPY G, 3`
    - `COPY D, 4`
    - `ADD A, G, D`
  - Depois:
    - `COPY G, 3`
    - `COPY D, 4`
    - `COPY A, 7`
- Segurança: a tabela de constantes é limpa ao entrar em labels, desvios, chamadas de função e retornos, para evitar propagar valores entre caminhos diferentes de execução.

### 5. Remoção de cópias redundantes

- Se o assembly iria copiar uma variável para ela mesma, a cópia é removida.
- Exemplo conceitual:
  - Antes:
    - `LDA $00`
    - `STA $00`
  - Depois:
    - instruções removidas
- Benefício: evita trabalho que não altera o estado do programa.

### 6. Remoção de jumps desnecessários

- Quando um `JMP` aponta exatamente para o próximo label do código, ele é removido.
- Exemplo conceitual:
  - Antes:
    - `JMP L1`
    - `L1:`
  - Depois:
    - `L1:`
- Benefício: reduz bytes gerados e evita saltos que não mudam o fluxo real.

### 7. Tratamento conservador de `if` e `while`

- Foi analisada a possibilidade de otimizar `if` e `while` usando diretamente as flags do `CMP` do MOS6502.
- Porém, essa otimização deixaria de gravar o resultado booleano (`0` ou `1`) na variável usada como condição.
- Decisão adotada: manter a geração conservadora.
- Fluxo preservado:
  - comparar dois valores
  - gravar `0` ou `1` na variável booleana
  - carregar essa variável
  - desviar caso ela seja falsa
- Benefício: mantém a memória observável mais previsível no Easy6502 e evita problemas em laços, `continue`, reuso da condição ou inspeção manual dos endereços.
- Consequência: o assembly fica um pouco maior do que ficaria com branch direto, mas a correção semântica e a depuração ficam mais seguras.
