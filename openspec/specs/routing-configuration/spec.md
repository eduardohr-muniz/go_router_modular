# Configuração do Roteamento

## Purpose

Define a configuração global do router: configure, montagem do GoRouter, snapshot imutável de parâmetros com copyWith/copyRouterConfig, transições padrão e ModularApp.router.

## Requirements

### Requirement: Configuração e construção do GoRouter

O sistema SHALL expor `GoRouterModular.configure` como ponto único de inicialização do roteamento, recebendo o `appModule` e a `initialRoute` obrigatórios, além de parâmetros opcionais repassados ao `GoRouter` (`guards`, `errorBuilder`, `observers`, `navigatorKey`, `debugLogDiagnostics`, entre outros). O `configure` MUST aceitar `guards` (lista de `ModularGuard`, default `const []`) como forma de proteção global, e MUST aceitar `redirect` (`@Deprecated`, mantido por compatibilidade). A função efetiva de redirecionamento global entregue ao `GoRouter` MUST ser a composição `[...guards, GuardFn(redirect)]` resolvida em curto-circuito (ver capability `routing-guards`). A configuração MUST construir as rotas a partir do `appModule` no nível top-level e MUST retornar uma instância única de `GoRouter` (chamadas subsequentes retornam a mesma instância).

Arquivos de referência: `lib/src/bootstrap/go_router_modular_configure.dart`, `lib/src/routing/guards/guard_resolver.dart`, `lib/src/module/module.dart`.

#### Scenario: configure constrói o router a partir do appModule

- **WHEN** `configure(appModule: AppModule(), initialRoute: '/')` é chamado
- **THEN** as rotas top-level são construídas a partir do `AppModule`
- **AND** um `GoRouter` é criado com a `initialLocation` igual à `initialRoute`

#### Scenario: configure é idempotente

- **WHEN** `configure` é chamado uma segunda vez após o router já existir
- **THEN** a mesma instância de `GoRouter` é retornada sem reconstruir as rotas

#### Scenario: guards globais protegem toda navegação

- **WHEN** `configure(..., guards: [AuthGuard()])` é chamado e `AuthGuard` retorna uma rota para a localização atual
- **THEN** o `GoRouter` recebe um `redirect` global que avalia os guards em curto-circuito
- **AND** a navegação para qualquer rota não isenta é desviada para a rota retornada pelo guard

#### Scenario: guards globais e redirect legado coexistem na ordem correta

- **WHEN** `configure` recebe `guards` e também o `redirect` legado, e todos os guards liberam (`null`)
- **THEN** o `redirect` legado é avaliado por último e decide o destino

### Requirement: Snapshot imutável de parâmetros com copy

O sistema SHALL manter um snapshot imutável dos parâmetros usados para construir o `GoRouter`, permitindo derivar um novo router com sobrescritas pontuais via `copyRouterConfig` (e a extension `GoRouter.copyWith`). Os campos não sobrescritos MUST ser preservados do snapshot original, e o router derivado MUST ser memorizado (reutilizado entre chamadas).

Arquivos de referência: `lib/src/core/config/go_router_modular_configure.dart`.

#### Scenario: copyWith preserva campos não sobrescritos

- **WHEN** `copyRouterConfig(observers: [meuObserver])` é chamado após `configure`
- **THEN** o router derivado usa os novos observers
- **AND** mantém as demais configurações do snapshot original (rotas, initialLocation, etc.)

#### Scenario: Router derivado é memorizado

- **WHEN** `copyRouterConfig` é chamado mais de uma vez
- **THEN** a mesma instância de router derivado é retornada

### Requirement: Transição padrão global

O sistema SHALL permitir configurar, em `configure`, uma transição padrão (`defaultTransition`) e uma duração padrão (`defaultTransitionDuration`) aplicadas às rotas que não declaram transição própria. Quando nenhuma transição padrão nem por rota é definida, o sistema MUST usar o comportamento padrão do `go_router` para a página.

Arquivos de referência: `lib/src/core/config/go_router_modular_configure.dart`, `lib/src/routing/route_builder.dart`.

#### Scenario: Rota sem transição usa a transição padrão configurada

- **WHEN** `configure` define `defaultTransition` e uma `ChildRoute` não declara `transition`
- **THEN** a rota usa a transição padrão configurada

#### Scenario: Transição por rota tem precedência sobre a padrão

- **WHEN** uma `ChildRoute` declara sua própria `transition`
- **THEN** a transição da rota é usada em vez da padrão global

### Requirement: Transição entre branches do shell stateful

O sistema SHALL resolver o container de navegação de um `StatefulShellModularRoute` por precedência: primeiro um `navigatorContainerBuilder` explícito; senão, uma transição (da rota ou padrão global) com durações efetivas, animando a troca entre branches; e, na ausência de qualquer transição, um container `indexedStack` sem animação.

Arquivos de referência: `lib/src/routing/stateful_shell_branch_transitions.dart`, `lib/src/routing/route_builder.dart`.

#### Scenario: Sem transição usa indexedStack sem animação

- **WHEN** um `StatefulShellModularRoute` não define `navigatorContainerBuilder`, `transition`, durações nem transição padrão global
- **THEN** a troca entre branches usa `indexedStack` sem animação

#### Scenario: Com transição anima a troca entre branches

- **WHEN** um `StatefulShellModularRoute` define uma transição (própria ou padrão global)
- **THEN** a troca entre branches é animada com essa transição e suas durações efetivas

#### Scenario: navigatorContainerBuilder explícito tem prioridade máxima

- **WHEN** um `StatefulShellModularRoute` define `navigatorContainerBuilder`
- **THEN** esse container é usado, ignorando transição e `indexedStack`

### Requirement: ModularApp injeta o router e o overlay do loader

O sistema SHALL oferecer `ModularApp.router` como wrapper de `MaterialApp.router` que injeta o `GoRouter` modular como `routerConfig` e sobrepõe o overlay do `ModularLoader` à árvore do app, preservando um `builder` customizado do usuário quando fornecido.

Arquivos de referência: `lib/src/widgets/material_app_router.dart`, `lib/src/widgets/modular_loader.dart`.

#### Scenario: ModularApp usa o router modular e adiciona o overlay

- **WHEN** `ModularApp.router(...)` é usado como app
- **THEN** o `routerConfig` é o `GoRouter` modular
- **AND** o overlay do `ModularLoader` é sobreposto sobre o conteúdo do app
