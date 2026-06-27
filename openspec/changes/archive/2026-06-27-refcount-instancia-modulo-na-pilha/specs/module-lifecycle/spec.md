## ADDED Requirements

### Requirement: Contagem de referências por instância de módulo na pilha

O sistema SHALL contar quantas entradas de rota ativas referenciam cada instância de módulo. O registro dos binds de um módulo MUST ocorrer apenas na primeira referência (transição de 0 para 1); referências subsequentes da mesma instância MUST apenas incrementar a contagem, sem re-registrar. O descarte do módulo (dispose e remoção de binds) MUST ocorrer apenas quando a última referência sai (transição de 1 para 0).

Arquivos de referência: `lib/src/di/injection_manager.dart`, `lib/src/di/bind_context_tracker.dart`.

#### Scenario: Mesma instância empilhada não é descartada no pop intermediário

- **WHEN** a pilha é `A → B → A` (a mesma instância de `A` referenciada duas vezes) e a entrada de cima de `A` sai (pop)
- **THEN** os binds de `A` permanecem registrados e resolvíveis
- **AND** a entrada de baixo de `A` continua funcionando

#### Scenario: Descarte só na última referência

- **WHEN** todas as entradas que referenciam a instância de `A` saem da pilha
- **THEN** `A.dispose()` é chamado e os binds de `A` são descartados
- **AND** o descarte ocorre uma única vez

#### Scenario: Registro efetivo uma única vez para entradas repetidas

- **WHEN** a mesma instância de módulo é referenciada por múltiplas entradas em sequência
- **THEN** a coleta de binds, o commit e o `initState` ocorrem uma única vez (na primeira referência)
- **AND** as referências seguintes apenas incrementam a contagem

### Requirement: Registro e descarte balanceados

O sistema SHALL manter o registro e o descarte de uma instância de módulo balanceados: N referências de entrada correspondem a N decrementos na saída, com o trabalho efetivo de registro e de descarte ocorrendo uma única vez em cada extremo. O contador MUST ser reiniciado pelo reset de testes, e o `AppModule` MUST permanecer nunca descartado independentemente da contagem.

Arquivos de referência: `lib/src/di/injection_manager.dart`.

#### Scenario: Contador não dessincroniza com a proteção de transição

- **WHEN** ocorre uma transição rápida que aciona a proteção `didChangeGoingReference` durante o ciclo de uma instância repetida
- **THEN** a contagem de referências permanece consistente
- **AND** o módulo não é descartado enquanto houver referência ativa

#### Scenario: Reset de testes limpa a contagem

- **WHEN** o reset de testes é executado
- **THEN** as contagens de referência de todos os módulos são zeradas
