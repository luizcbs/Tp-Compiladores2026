# Pendências e Decisões da Análise Semântica

Este documento resume por que a análise semântica atual ainda é considerada parcial no contexto do projeto, o que já está coberto e quais decisões de linguagem ainda precisam ser tomadas para que a implementação fique mais completa e consistente.

## O que já está sendo verificado

Atualmente, o compilador já realiza diversas validações semânticas importantes, entre elas:

- verificação de que variáveis usadas como destino foram declaradas;
- exigência de que notas-guia de `if` e `while` sejam booleanas;
- verificação de compatibilidade entre o `return` e o tipo declarado da função;
- validação de chamadas de função quanto à existência, número de argumentos e compatibilidade do tipo de retorno com a variável de destino;
- verificações básicas em operações com listas, como uso de identificador declarado, tipo lista e índice inteiro;
- verificação de compatibilidade básica em operadores aritméticos, relacionais e lógicos.

Essas regras já caracterizam uma análise semântica funcional, mas ainda não cobrem toda a profundidade possível da linguagem.

## Por que a semântica ainda é parcial

A implementação ainda é parcial porque existem áreas em que o comportamento da linguagem não está totalmente definido ou não foi completamente implementado no compilador.

### 1. Regras completas de tipagem

Ainda faltam decisões claras sobre combinações de tipos, por exemplo:

- `int + float` deve ser permitido?
- se for permitido, o resultado deve ser `float`?
- `int == float` é válido?
- `null` pode ser atribuído a quais tipos?
- `bool` pode aparecer em operações numéricas em algum contexto?
- acordes livres devem ter tipo próprio ou devem ser rejeitados semanticamente?

Essas decisões precisam ser formalizadas para que as checagens de tipo fiquem consistentes em toda a linguagem.

### 2. Escopo e visibilidade

O projeto já possui estrutura de escopos, mas ainda faltam definições mais refinadas sobre:

- uso de variável antes da declaração;
- shadowing de variáveis entre escopo interno e externo;
- parâmetros com nomes repetidos;
- conflito entre nome de função e nome de variável;
- possibilidade de chamar uma função antes de sua declaração.

Esses pontos dependem da política que o grupo decidir adotar para a linguagem.

### 3. Tipagem de argumentos em chamadas de função

Atualmente, a chamada de função já verifica:

- se a função existe;
- se a quantidade de argumentos está correta;
- se o tipo de retorno é compatível com a variável de destino.

No entanto, ainda falta verificar o tipo de cada argumento passado em relação ao tipo esperado pelos parâmetros da função. Por exemplo, uma função que espera `(int, bool)` ainda precisaria rejeitar uma chamada com `(int, int)`.

### 4. Semântica de listas mais completa

O compilador já verifica alguns aspectos de listas, mas ainda faltam definições como:

- qual é o tipo dos elementos armazenados na lista;
- se a lista é homogênea ou não;
- se `write_list` deve verificar compatibilidade entre o valor inserido e o tipo dos elementos;
- se `read_list` deve validar o tipo do destino com base no tipo do elemento;
- se listas podem receber `null`;
- se o tamanho da lista é fixo após a declaração.

Esses pontos definem o comportamento semântico real do tipo `lista`.

### 5. Controle de fluxo mais profundo

Ainda seria possível aprofundar a análise de fluxo em questões como:

- toda função precisa obrigatoriamente retornar um valor?
- uma função `int` pode terminar sem `return`?
- todos os caminhos de um `if/else` precisam garantir retorno?
- `break` e `continue` devem sempre falhar se usados fora de `while`?

Esse tipo de verificação vai além de checagens locais e exige uma análise mais estrutural do programa.

### 6. Propagação e consistência de tipos de resultado

Também falta definir com mais precisão:

- qual é o tipo resultante de cada operação;
- como esse tipo deve ser reutilizado em usos futuros da variável destino.

Por exemplo:

- `SLT x, a, b` deve sempre produzir `bool`;
- `ADD x, a, b` deve produzir `int` ou `float` dependendo dos operandos;
- o uso posterior de `x` precisa ser coerente com esse resultado.

### 7. Uso de identificadores

Ainda faltam decisões sobre o comportamento de identificadores em casos como:

- uso de identificador inexistente em expressões;
- identificadores musicais malformados;
- possível papel de acordes livres dentro da linguagem;
- distinção entre erro léxico e erro semântico em alguns usos inválidos.

### 8. Dependência das escolhas de projeto da linguagem

Parte da semântica depende diretamente do que o grupo decidir fixar como regra oficial da linguagem. Alguns exemplos:

- a declaração de lista precisa obrigatoriamente de tamanho?
- a forma atual de declaração de lista será a sintaxe oficial?
- chamada de função com `CALL` é obrigatória ou existe chamada implícita?
- atribuição via `ADD destino 0 valor` é apenas uma convenção interna ou faz parte da sintaxe oficial da linguagem?

Sem essas definições, parte da análise semântica fica sujeita a interpretação.

## O que ainda faltaria implementar

Para a semântica ficar mais completa, ainda seria necessário:

- fechar formalmente as regras de tipos da linguagem;
- validar tipos de argumentos de função por posição;
- refinar as regras de escopo e redeclaração;
- decidir e implementar a semântica completa de listas;
- aprofundar a análise de retorno e fluxo de controle;
- definir com clareza o comportamento de `null`;
- padronizar o tratamento de identificadores e acordes livres.

## Quais decisões o grupo ainda precisa tomar

As decisões mais importantes para o grupo são:

- quais combinações de tipos são permitidas nas operações;
- qual é o tipo resultante de cada operador;
- como `null` deve se comportar;
- se listas têm tipo de elemento;
- se chamadas de função devem validar tipo de argumento por posição;
- se a linguagem permite shadowing e redeclaração;
- se toda função precisa ter `return`;
- se usar variável antes da declaração é erro;
- se a sintaxe musical atual é a forma definitiva de cada construção.

## Resumo final

O parser responde se uma construção existe na linguagem. A análise semântica responde se essa construção faz sentido dentro das regras da linguagem. O que ainda falta no projeto é justamente tornar essas regras de sentido mais completas, explícitas e uniformes.
