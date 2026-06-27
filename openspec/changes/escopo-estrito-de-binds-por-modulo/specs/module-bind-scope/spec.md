## ADDED Requirements

### Requirement: Conjunto visível de um módulo

O sistema SHALL definir o conjunto de binds visível a um módulo M como a união dos binds que M injetou, dos binds que M importou e dos binds do `AppModule` (incluindo os imports do `AppModule`). O `AppModule` MUST ser o único escopo global, acessível por todos os módulos.

Arquivos de referência: `lib/src/di/bind_context_tracker.dart`, `lib/src/di/injection_manager.dart`.

#### Scenario: Módulo vê seus próprios binds e os do AppModule

- **WHEN** um módulo de feature M declara o bind `X` e o `AppModule` declara o bind `G`
- **THEN** M pode resolver `X` e `G`

#### Scenario: Módulo vê binds que importou

- **WHEN** o módulo M importa o módulo A, que declara o bind `Y`
- **THEN** M pode resolver `Y`

### Requirement: Resolução fora do escopo lança exceção

O sistema SHALL lançar `GoRouterModularException` quando um módulo resolve (via `get`) um bind que não está no seu conjunto visível, mesmo que o bind exista e esteja vivo no container por pertencer a outro módulo. A mensagem MUST identificar o módulo solicitante, o bind e a correção sugerida (importar o módulo dono ou injetar o bind). `tryGet` MUST retornar `null` nesse caso, em vez de lançar.

Arquivos de referência: `lib/src/di/bind_locator.dart`, `lib/src/shared/exception.dart`.

#### Scenario: Módulo resolve bind de outro módulo que não importou

- **WHEN** `ModuleA` injeta `ServiceA` e `ServiceB`, e `ModuleB` (que não importa `ModuleA` nem injeta `ServiceB`) tenta resolver `ServiceB` — mesmo com `ModuleA` ainda vivo na pilha após um `push`
- **THEN** o sistema lança `GoRouterModularException`
- **AND** a mensagem indica resolver via import de `ModuleA` ou injeção de `ServiceB` em `ModuleB`

#### Scenario: tryGet fora do escopo retorna null

- **WHEN** `ModuleB` chama `tryGet<ServiceB>()` para um bind fora do seu escopo
- **THEN** o sistema retorna `null`, sem lançar

### Requirement: Escopo na resolução por factory

O sistema SHALL escopar o `Injector` recebido em `binds(Injector injector)` e usado na execução de factories ao módulo dono daquele bind. Quando a factory de um bind do módulo M resolve `injector.get<U>()`, a verificação de escopo MUST usar o conjunto visível de M.

Arquivos de referência: `lib/src/di/injector.dart`, `lib/src/di/bind_locator.dart`, `lib/src/di/bind.dart`.

#### Scenario: Factory resolve dependência fora do escopo do módulo

- **WHEN** a factory de um bind do módulo M faz `injector.get<U>()`, mas `U` não está no conjunto visível de M
- **THEN** o sistema lança `GoRouterModularException`

### Requirement: Escopo na resolução por contexto de widget

O sistema SHALL resolver `context.read<T>()` no escopo do módulo cuja subárvore contém o widget, usando o módulo exposto pelo `ParentWidgetObserver` via `InheritedWidget`. Quando não há módulo no contexto, a resolução MUST usar o escopo do `AppModule`.

Arquivos de referência: `lib/src/ui/context_extension.dart`, `lib/src/ui/parent_widget_observer.dart`.

#### Scenario: context.read resolve no escopo do módulo da subárvore

- **WHEN** um widget na subárvore do módulo M chama `context.read<T>()` para `T` no conjunto visível de M
- **THEN** o sistema retorna a instância
- **AND** para `T` fora do conjunto visível de M, lança `GoRouterModularException`

### Requirement: Resolução estática usa o escopo do AppModule

O sistema SHALL resolver `Modular.get<T>()` / `Bind.get<T>()` estáticos no escopo do `AppModule` (o global), por não haver contexto de módulo. Tipos pertencentes apenas a módulos de feature MUST exigir resolução por `context.read` ou por `injector` escopado.

Arquivos de referência: `lib/src/bootstrap/go_router_modular_configure.dart`, `lib/src/di/bind.dart`.

#### Scenario: Modular.get resolve bind global

- **WHEN** `Modular.get<G>()` é chamado para um bind `G` do `AppModule`
- **THEN** o sistema retorna a instância

#### Scenario: Modular.get de bind de feature lança

- **WHEN** `Modular.get<X>()` é chamado para um bind `X` que pertence apenas a um módulo de feature
- **THEN** o sistema lança `GoRouterModularException`, orientando a usar `context.read` ou injeção
