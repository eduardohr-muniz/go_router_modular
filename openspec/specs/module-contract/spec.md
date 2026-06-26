# Contrato do Module

## Purpose

Define o contrato público da classe Module: imports, binds, routes, initState, dispose, configureRoutes, os typedefs FutureBinds/FutureModules, a separação Injector vs InjectorReader e as asserções de validação de configuração.

## Requirements

### Requirement: Module como contrato abstrato extensível

O sistema SHALL definir `Module` como classe abstrata cujos membros têm implementações padrão neutras, permitindo que um módulo concreto sobrescreva apenas o que precisa. Os padrões MUST ser: `imports` retorna lista vazia, `binds` não registra nada, `routes` retorna lista vazia constante, `initState` não faz nada e `dispose` não faz nada.

Arquivos de referência: `lib/src/core/module/module.dart`.

#### Scenario: Módulo mínimo é válido

- **WHEN** um módulo concreto estende `Module` sem sobrescrever nenhum membro
- **THEN** ele tem `imports` vazio, nenhum bind, nenhuma rota e hooks de ciclo de vida inertes

### Requirement: Declaração de binds recebe um Injector de escrita

O sistema SHALL invocar `binds(Injector injector)` para que o módulo registre suas dependências usando o `Injector` recebido (`addSingleton`, `addLazySingleton`, `addFactory`/`add`). O retorno é `FutureBinds` (`FutureOr<void>`), permitindo que `binds` seja síncrono ou assíncrono. O `Injector` recebido em `binds` MUST ser de escrita (coleta binds), distinto do `InjectorReader` de leitura.

Arquivos de referência: `lib/src/core/module/module.dart`, `lib/src/di/injector.dart`.

#### Scenario: binds registra dependências do módulo

- **WHEN** um módulo implementa `binds` chamando `injector.addSingleton<MeuServico>(...)`
- **THEN** `MeuServico` torna-se resolvível após o registro do módulo

#### Scenario: binds assíncrono é suportado

- **WHEN** um módulo implementa `binds` como `Future<void>` e realiza trabalho assíncrono antes de registrar
- **THEN** o registro do módulo aguarda a conclusão de `binds` antes de prosseguir

### Requirement: Inicialização pós-registro recebe um InjectorReader somente leitura

O sistema SHALL invocar `initState(InjectorReader injector)` após todos os binds do módulo e de seus imports terem sido registrados e commitados. O parâmetro MUST ser um `InjectorReader` (apenas `get`), não um `Injector` de escrita, impedindo o registro de novos binds nesse hook (aplicação de Interface Segregation).

Arquivos de referência: `lib/src/core/module/module.dart`, `lib/src/di/injector.dart`, `lib/src/core/manager/injection_manager.dart`.

#### Scenario: initState pode ler binds já registrados

- **WHEN** um módulo implementa `initState` chamando `injector.get<MeuServico>()`
- **THEN** a dependência já registrada é resolvível dentro de `initState`

#### Scenario: initState não expõe API de registro

- **WHEN** um módulo implementa `initState`
- **THEN** o `InjectorReader` recebido não oferece métodos de registro (`addSingleton`, `addFactory`, etc.)

### Requirement: Definição de rotas do módulo

O sistema SHALL expor `routes` como a lista de `ModularRoute` que o módulo contribui, consumida pelo construtor de rotas. A lista MUST aceitar os tipos `ChildRoute`, `ModuleRoute`, `ShellModularRoute` e `StatefulShellModularRoute`.

Arquivos de referência: `lib/src/core/module/module.dart`, `lib/src/routing/route_builder.dart`.

#### Scenario: routes contribui rotas para a árvore de navegação

- **WHEN** um módulo declara `routes` com uma `ChildRoute` e uma `ModuleRoute`
- **THEN** ambas são convertidas e incorporadas à árvore do `go_router` ao construir as rotas do módulo

### Requirement: Imports declara módulos compostos

O sistema SHALL expor `imports()` retornando `FutureModules` (`FutureOr<List<Module>>`) com os módulos cujos binds devem estar disponíveis junto com os do módulo atual. O retorno MUST poder ser síncrono ou assíncrono.

Arquivos de referência: `lib/src/core/module/module.dart`, `lib/src/core/manager/injection_manager.dart`.

#### Scenario: imports declara módulos compartilhados

- **WHEN** um módulo retorna `[SharedModule()]` em `imports`
- **THEN** os binds de `SharedModule` ficam resolvíveis junto com os binds do módulo

### Requirement: configureRoutes registra o módulo raiz e constrói as rotas

O sistema SHALL expor `configureRoutes({String modulePath, bool topLevel})` que registra o módulo como `AppModule` (de forma idempotente) e retorna as rotas construídas (`List<RouteBase>`). O parâmetro `topLevel` MUST controlar a normalização de paths (top-level preserva a barra inicial; aninhado a remove) e `modulePath` MUST ser o prefixo das rotas aninhadas.

Arquivos de referência: `lib/src/core/module/module.dart`, `lib/src/routing/route_builder.dart`, `lib/src/core/manager/injection_manager.dart`.

#### Scenario: configureRoutes top-level registra e constrói rotas raiz

- **WHEN** `appModule.configureRoutes(topLevel: true)` é chamado
- **THEN** o módulo é registrado como `AppModule`
- **AND** as rotas top-level são retornadas com paths preservando a barra inicial

### Requirement: Asserções de validação de configuração do módulo

O sistema SHALL validar, em modo de desenvolvimento, a configuração de rotas de um módulo: um módulo sem shell que é montado por `ModuleRoute` MUST conter uma `ChildRoute` com path `/` como entrada; e um `ShellModularRoute` MUST NOT conter uma `ChildRoute` com path `/` diretamente. Violações MUST disparar asserção com mensagem orientativa.

Arquivos de referência: `lib/src/internal/asserts/module_assert.dart`, `lib/src/routing/route_builder.dart`.

#### Scenario: Módulo sem rota índice é rejeitado

- **WHEN** um módulo montado por `ModuleRoute`, sem shell, não declara `ChildRoute('/')`
- **THEN** uma asserção falha indicando a necessidade da rota índice

#### Scenario: Shell com rota índice direta é rejeitado

- **WHEN** um `ShellModularRoute` declara `ChildRoute('/')` como filha direta
- **THEN** uma asserção falha indicando que o shell é apenas um invólucro
