# Dependências de Pacotes

## Purpose

Define as dependências externas do pacote e o papel de cada uma: event_bus como base de eventos, go_router como motor de roteamento encapsulado, e demais dependências.

## Requirements

### Requirement: event_bus é a base do sistema de eventos

O sistema SHALL declarar `event_bus` como dependência de runtime e usá-lo como mecanismo de publish-subscribe tipado do sistema de eventos. O pacote MUST consumir, no mínimo, a classe `EventBus`, o método de assinatura `bus.on<T>()`, o disparo `bus.fire(event)` e a conversão `asBroadcastStream()` para ouvintes exclusivos. Os consumos MUST ocorrer em `lib/src/events/modular_event.dart`, `lib/src/events/modular_event_mixin.dart` e nos utilitários de teste `lib/src/testing/modular_event_bus.dart`, `lib/src/testing/event_recorder.dart` e `lib/src/testing/modular_test_scope.dart`. Sem `event_bus`, o sistema de eventos (`EventModule`, `ModularEvent`, `ModularEventListener`) MUST NOT funcionar.

Arquivos de referência: `pubspec.yaml` (`event_bus: ^2.0.1`), `lib/src/events/*`, `lib/src/testing/*`.

#### Scenario: event_bus está declarado e é importado pelo código de eventos

- **WHEN** o `pubspec.yaml` e os arquivos de `lib/src/events/` são inspecionados
- **THEN** `event_bus` consta em `dependencies`
- **AND** ao menos um arquivo importa `package:event_bus/event_bus.dart` e usa `EventBus`, `on<T>()` e `fire`

#### Scenario: Remoção hipotética de event_bus quebra a compilação dos eventos

- **WHEN** se considera remover `event_bus`
- **THEN** os arquivos do sistema de eventos perdem `EventBus`/`on`/`fire` e não compilam

### Requirement: go_router é o motor de roteamento encapsulado

O sistema SHALL declarar `go_router` como dependência de runtime e usá-lo como motor de navegação sobre o qual a camada modular é construída. O pacote MUST consumir, no mínimo, `GoRouter`, `GoRoute`, `ShellRoute`, `StatefulShellRoute`, `StatefulShellBranch`, `StatefulNavigationShell`, `GoRouterState`, `RouteBase` e `NavigatorObserver`. Os consumos MUST ocorrer em `lib/src/core/config/go_router_modular_configure.dart`, `lib/src/routing/route_builder.dart`, `lib/src/routing/child_route.dart`, `lib/src/routing/stateful_shell_modular_route.dart`, `lib/src/routing/stateful_shell_branch_transitions.dart`, `lib/src/extensions/route_extension.dart` e `lib/src/core/module/module.dart`. Sem `go_router`, não MUST haver motor de navegação, sincronização de URL nem construção de rotas.

Arquivos de referência: `pubspec.yaml` (`go_router: ^17.3.0`), `lib/src/core/config/*`, `lib/src/routing/*`, `lib/src/extensions/route_extension.dart`, `lib/src/core/module/module.dart`.

#### Scenario: go_router está declarado e os tipos modulares mapeiam para tipos do go_router

- **WHEN** os arquivos de `lib/src/routing/` são inspecionados
- **THEN** `ChildRoute` mapeia para `GoRoute`, `ShellModularRoute` para `ShellRoute` e `StatefulShellModularRoute` para `StatefulShellRoute`/`StatefulShellBranch`

#### Scenario: configure instancia um GoRouter

- **WHEN** `lib/src/core/config/go_router_modular_configure.dart` é inspecionado
- **THEN** ele instancia/configura um `GoRouter` com as rotas modulares construídas pelo `ModularRouteBuilder`

### Requirement: go_transitions provê as transições de página e de branches

O sistema SHALL declarar `go_transitions` como dependência de runtime e usá-lo para animar transições de rota e de branches de shell stateful. O pacote MUST consumir, no mínimo, `GoTransition`, as propriedades estáticas globais `GoTransition.defaultDuration` e `GoTransition.defaultReverseDuration`, presets `GoTransitions.*` e os métodos `build`/`copyWith` de transição. Os consumos MUST ocorrer em `lib/src/core/config/go_router_modular_configure.dart`, `lib/src/routing/child_route.dart`, `lib/src/routing/route_model.dart`, `lib/src/routing/stateful_shell_modular_route.dart`, `lib/src/routing/route_builder.dart` e `lib/src/routing/stateful_shell_branch_transitions.dart`. A transição padrão global e sua duração MUST ser configuráveis via `configure`. Sem `go_transitions`, as navegações MUST ser instantâneas (sem animação).

Arquivos de referência: `pubspec.yaml` (`go_transitions: ^0.8.2`), `lib/src/core/config/*`, `lib/src/routing/*`.

#### Scenario: go_transitions está declarado e é usado nas rotas

- **WHEN** os arquivos de `lib/src/routing/` são inspecionados
- **THEN** `ChildRoute` aceita um campo de transição tipado por `GoTransition`
- **AND** o construtor de rotas aplica a transição via `build`/`copyWith`

#### Scenario: Transição padrão global é definível na configuração

- **WHEN** `configure` recebe transição/duração padrão
- **THEN** o valor é refletido em `GoTransition.defaultDuration`/`defaultReverseDuration` e usado quando a rota não define transição própria

### Requirement: flutter, flutter_test e flutter_lints sustentam framework e qualidade

O sistema SHALL declarar `flutter` como dependência de runtime (SDK) e `flutter_test` e `flutter_lints` como dependências de desenvolvimento. `flutter` MUST fornecer o framework de UI e tipos como `BuildContext`/`Widget` usados em toda a `lib/`. `flutter_test` MUST sustentar a suíte de testes em `test/`. `flutter_lints` MUST fornecer as regras de análise estática aplicadas por `flutter analyze`.

Arquivos de referência: `pubspec.yaml` (`flutter`, `flutter_test`, `flutter_lints: ^3.0.0`), `analysis_options.yaml`.

#### Scenario: Dependências de framework e ferramentas estão declaradas

- **WHEN** o `pubspec.yaml` é inspecionado
- **THEN** `flutter` consta em `dependencies` e `flutter_test`/`flutter_lints` constam em `dev_dependencies`

#### Scenario: Regras de lint vêm de flutter_lints

- **WHEN** `analysis_options.yaml` é inspecionado
- **THEN** ele inclui/estende o conjunto de regras de `flutter_lints`

### Requirement: web e flutter_web_plugins são dependências órfãs sem uso atual

O sistema SHALL registrar que `web` e `flutter_web_plugins` estão declaradas em `dependencies` mas NÃO possuem nenhum import em `lib/`. A spec MUST documentar que essas dependências foram introduzidas para o recurso `web_channel.dart`/`BrowserReplaceObserver` (commit `2dec3f5`) e ficaram sem uso após a remoção desse recurso (commit `d6626c6`). A spec MUST marcá-las como candidatas a remoção do `pubspec.yaml`, a ser decidida em mudança separada, e MUST NOT removê-las nesta mudança documental.

Arquivos de referência: `pubspec.yaml` (`web: ^1.0.0`, `flutter_web_plugins: sdk: flutter`), histórico Git (commits `2dec3f5`, `d6626c6`).

#### Scenario: Nenhum arquivo de lib importa web ou flutter_web_plugins

- **WHEN** uma busca por `package:web` e `package:flutter_web_plugins` é feita em `lib/`
- **THEN** nenhum resultado de import é encontrado

#### Scenario: Dependências órfãs continuam declaradas até decisão futura

- **WHEN** esta mudança documental é aplicada
- **THEN** `web` e `flutter_web_plugins` permanecem no `pubspec.yaml`
- **AND** a spec as registra explicitamente como candidatas a remoção
