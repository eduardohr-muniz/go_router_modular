## ADDED Requirements

### Requirement: Assert de configuração guia o desenvolvedor quando configure não foi chamado

O sistema SHALL fornecer `GoRouterModularConfigureAssert.goRouterModularConfigureAssert()`, que retorna uma mensagem-guia explicando como chamar `GoRouterModular.configure` no `main.dart` e usar `ModularApp.router` no widget de app. A mensagem MUST ser usada como texto de `assert` ao acessar o `routerConfig` e os `params` antes de a configuração ter sido feita, em `lib/src/core/config/go_router_modular_configure.dart`. Quando a configuração já ocorreu (router/params não nulos), o `assert` MUST NOT disparar.

Arquivos de referência: `lib/src/internal/asserts/go_router_modular_configure_assert.dart`, `lib/src/core/config/go_router_modular_configure.dart` (acessos a `_router` e `_params`).

#### Scenario: Acesso antes de configure dispara assert com a mensagem-guia

- **WHEN** `routerConfig` ou `params` é acessado em modo debug antes de `GoRouterModular.configure`
- **THEN** o `assert` falha exibindo a mensagem de `goRouterModularConfigureAssert()`

#### Scenario: Acesso após configure não dispara assert

- **WHEN** `GoRouterModular.configure` já foi chamado e `routerConfig` é acessado
- **THEN** nenhum `assert` é disparado

### Requirement: Log interno iLog é um helper dormente controlado por flag de compilação

O sistema SHALL definir o helper `iLog(String message, {String name = "INTERNAL_LOG"})` e a constante `kInternalLogs`, em que `iLog` só emite via `dart:developer log` quando `kInternalLogs` é verdadeiro. A spec MUST registrar que `iLog` está **dormente**: não é chamado por nenhum arquivo de `lib/`. A spec MUST marcá-lo como candidato a remoção ou a passar a ser usado, e MUST NOT removê-lo nesta mudança documental.

Arquivos de referência: `lib/src/internal/internal_logs.dart`.

#### Scenario: iLog respeita a flag de compilação

- **WHEN** `kInternalLogs` é verdadeiro e `iLog('msg')` é chamado
- **THEN** a mensagem é emitida via `log` com o `name` informado

#### Scenario: iLog não é referenciado pela base de código

- **WHEN** uma busca por `iLog(` é feita em `lib/`
- **THEN** nenhuma chamada é encontrada fora da própria definição

### Requirement: DependencyAnalyzer é infraestrutura de rastreamento majoritariamente dormente

O sistema SHALL fornecer `DependencyAnalyzer` como rastreador estático de buscas e dependências, com: histórico de tentativas por tipo limitado a uma janela fixa (`_historyWindow = 10`) via `recordSearchAttempt`, taxa de sucesso (`successRate`, padrão `1.0` quando vazio), conjunto de buscas ativas (`startSearch`/`endSearch`), grafo direcionado de dependências (`recordDependency`), e limpeza (`clearTypeHistory`, `clearAll`). A spec MUST registrar que, em produção (`lib/`), **apenas `clearAll()` é invocado** — em `lib/src/testing/modular_test_scope.dart` — e que as APIs de rastreamento são exercitadas somente pelos testes; a proteção efetiva contra ciclos é feita por `BindSearchProtection`, não por este analisador. A spec MUST marcar o rastreamento como dormente e candidato a ativação ou remoção, sem alterá-lo.

Arquivos de referência: `lib/src/core/dependency_analyzer/dependency_analyzer.dart`, `lib/src/testing/modular_test_scope.dart`, `lib/src/core/bind/bind_search_protection.dart`.

#### Scenario: Histórico respeita a janela máxima

- **WHEN** mais de 10 tentativas são registradas para um tipo via `recordSearchAttempt`
- **THEN** apenas as 10 últimas são mantidas no histórico

#### Scenario: Taxa de sucesso de tipo sem histórico é 1.0

- **WHEN** `successRate` é lido para um tipo sem tentativas registradas
- **THEN** o valor retornado é `1.0`

#### Scenario: clearAll zera todo o estado do analisador

- **WHEN** há histórico, buscas ativas e grafo registrados e `clearAll()` é chamado
- **THEN** histórico, buscas ativas e grafo de dependências ficam vazios

#### Scenario: Produção só usa clearAll

- **WHEN** `lib/` é inspecionado em busca de chamadas a `DependencyAnalyzer`
- **THEN** apenas `clearAll()` é chamado (em `modular_test_scope.dart`)
- **AND** `recordSearchAttempt`, `startSearch`, `endSearch`, `recordDependency` e `successRate` não são chamados por código de produção
