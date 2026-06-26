# Ordem do Ciclo de Vida do Module

## Purpose

Define a ordem determinística do ciclo de vida de um módulo: sequência de registro (binds → imports recursivos → commit → initState), sequência de descarte (dispose → remoção de binds) e a proteção contra descarte prematuro em transição.

## Requirements

### Requirement: Ordem determinística do registro de um módulo

O sistema SHALL registrar um módulo seguindo uma ordem fixa: (1) coletar os binds do próprio módulo via `binds`; (2) coletar recursivamente os binds dos `imports`; (3) registrar e commitar todos os binds em batch; (4) mapear os binds ao módulo para rastreamento; (5) invocar `initState`; (6) agendar a validação dos binds. `initState` MUST ser invocado somente após o commit dos binds.

Arquivos de referência: `lib/src/core/manager/injection_manager.dart`, `lib/src/core/module/module.dart`.

#### Scenario: initState ocorre após o commit dos binds

- **WHEN** um módulo é registrado
- **THEN** `binds` é coletado e commitado antes de `initState`
- **AND** dentro de `initState` os binds do módulo já são resolvíveis

### Requirement: Coleta recursiva de imports com proteção contra ciclos

O sistema SHALL coletar os binds dos `imports` de forma recursiva, registrando os binds de cada módulo importado e descendo nos imports dos imports. Um conjunto de módulos já visitados MUST impedir laços infinitos quando houver ciclo de importação entre módulos.

Arquivos de referência: `lib/src/core/manager/injection_manager.dart`, `lib/src/core/module/module.dart`.

#### Scenario: Imports aninhados são coletados recursivamente

- **WHEN** o módulo A importa B, e B importa C
- **THEN** os binds de A, B e C ficam resolvíveis após o registro de A

#### Scenario: Ciclo de imports não causa laço infinito

- **WHEN** o módulo A importa B e B importa A
- **THEN** a coleta termina sem laço infinito, visitando cada módulo uma única vez

### Requirement: Ordem determinística do descarte de um módulo

O sistema SHALL descartar um módulo invocando `dispose` antes de remover seus binds. Após `dispose`, os binds exclusivos do módulo MUST ser removidos e o rastreamento do módulo MUST ser limpo. Um erro em validações pendentes durante o descarte MUST NOT interromper o descarte.

Arquivos de referência: `lib/src/core/manager/injection_manager.dart`, `lib/src/core/module/module.dart`.

#### Scenario: dispose do módulo ocorre antes da remoção dos binds

- **WHEN** um módulo é descartado
- **THEN** `dispose` do módulo é invocado primeiro
- **AND** em seguida seus binds exclusivos são removidos e o rastreamento é limpo

### Requirement: Proteção contra descarte prematuro durante transição

O sistema SHALL marcar um módulo como em transição quando `onDidChangeGoingReference` é chamado (a partir de `didChangeDependencies` do observer de rota), adicionando-o a `didChangeGoingReference` e agendando sua remoção em um microtask. Enquanto o módulo estiver marcado, um descarte concorrente MUST ser ignorado para aquele módulo.

Arquivos de referência: `lib/src/core/module/module.dart`, `lib/src/routing/route_builder.dart`, `lib/src/widgets/parent_widget_observer.dart`.

#### Scenario: Módulo marcado em transição não é descartado

- **WHEN** `onDidChangeGoingReference` marca um módulo e um descarte concorrente é disparado antes do microtask expirar
- **THEN** o descarte é ignorado para esse módulo
- **AND** após o microtask a marca é removida e o módulo volta a ser descartável

### Requirement: Validação agendada de singletons do módulo

O sistema SHALL agendar uma validação dos singletons do módulo após o registro, executando-a posteriormente sem interromper a fila de operações. Uma falha na validação MUST ser registrada/ignorada, nunca propagada de forma a abortar o ciclo de vida.

Arquivos de referência: `lib/src/core/manager/injection_manager.dart`.

#### Scenario: Falha de validação não interrompe o ciclo de vida

- **WHEN** a validação agendada de um singleton lança um erro
- **THEN** o erro não interrompe o registro nem o descarte de módulos
