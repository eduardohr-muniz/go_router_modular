# Superfície Pública da API

## Purpose

Define a superfície pública exportada pelo barril principal do pacote: as áreas exportadas e a re-exportação de pacotes externos ocultando os tipos substituídos.

## Requirements

### Requirement: O barril principal exporta a superfície pública por área

O sistema SHALL expor sua API pública pelo barril `lib/go_router_modular.dart`, agrupada por área. O barril MUST exportar, no mínimo: o core (`bind.dart`, `go_router_modular_configure.dart`, `module.dart`, `injection_manager.dart`), a DI (`injector.dart`), o roteamento (`route_model.dart`, `child_route.dart`, `i_modular_route.dart`, `module_route.dart`, `shell_modular_route.dart`, `stateful_shell_modular_route.dart`, `stateful_shell_branch_transitions.dart`) e as extensions (`context_extension.dart`, `route_extension.dart`), as exceções (`exception.dart`) e os widgets (`material_app_router.dart`, `modular_loader.dart`). Importar `package:go_router_modular/go_router_modular.dart` MUST ser suficiente para usar a API de produção do pacote sem imports internos de `src/`.

Arquivos de referência: `lib/go_router_modular.dart`.

#### Scenario: Import único dá acesso à API de produção

- **WHEN** um consumidor importa `package:go_router_modular/go_router_modular.dart`
- **THEN** tipos como `Module`, `Bind`, `Injector`, `ChildRoute`, `ModuleRoute`, `ShellModularRoute`, `ModularApp` e `ModularException` ficam disponíveis sem importar arquivos de `src/`

#### Scenario: Widgets internos não-públicos não são exportados

- **WHEN** o barril principal é inspecionado
- **THEN** widgets de uso interno (`once_builder.dart`, `parent_widget_observer.dart`) não constam entre os exports públicos

### Requirement: O barril principal re-exporta pacotes externos ocultando os tipos substituídos

O sistema SHALL re-exportar pacotes externos pelo barril principal aplicando ocultação seletiva para evitar colisão com os tipos modulares. O barril MUST exportar `package:go_router/go_router.dart` com `hide GoRouter, ShellRoute`, `package:go_transitions/go_transitions.dart` com `hide GoTransition` e `package:event_bus/event_bus.dart` por completo. Do sistema de eventos, MUST exportar apenas os símbolos públicos selecionados: de `modular_event.dart` `show ModularEvent, clearEventModuleState, defaultModularEventBus`; de `event_module.dart` `show EventModule`; de `modular_event_mixin.dart` `show ModularEventMixin`. O barril principal MUST NOT exportar `ModularEventListener` (tipo removido) nem `EventListenerMixin` (deixou de ser tipo público; sua lógica foi incorporada a `EventModule`).

Arquivos de referência: `lib/go_router_modular.dart`.

#### Scenario: Tipos do go_router substituídos ficam ocultos

- **WHEN** um consumidor importa o barril principal
- **THEN** `GoRouter` e `ShellRoute` do `go_router` não vazam pelo re-export
- **AND** os demais símbolos do `go_router` (ex.: `GoRouterState`) continuam acessíveis

#### Scenario: GoTransition original é ocultado

- **WHEN** o barril principal é inspecionado
- **THEN** `go_transitions` é re-exportado com `hide GoTransition`

#### Scenario: Apenas símbolos públicos de eventos são expostos

- **WHEN** o barril principal é inspecionado
- **THEN** o sistema de eventos é exportado com `show` limitado (ex.: `ModularEvent`, `EventModule`, `ModularEventMixin`)
- **AND** detalhes internos como `EventState` não são exportados

#### Scenario: Tipos de eventos removidos não constam na superfície pública

- **WHEN** os símbolos exportados por `lib/go_router_modular.dart` são inspecionados
- **THEN** `ModularEventListener` e `EventListenerMixin` não estão entre eles

### Requirement: Utilitários do go_router ficam acessíveis pela superfície pública

O sistema SHALL garantir que os utilitários úteis do `go_router` permaneçam acessíveis ao consumidor por um único import do barril principal, para que ele possa usá-los diretamente caso prefira não passar pelos wrappers da fachada `Modular`. A re-exportação MUST manter `package:go_router/go_router.dart` com `hide GoRouter, ShellRoute`, de modo que tipos como `GoRouterState` e a extension `GoRouterHelper` (que provê `context.go`, `context.push`, etc.) continuem disponíveis, sem vazar os tipos substituídos (`GoRouter`, `ShellRoute`).

Arquivos de referência: `lib/go_router_modular.dart`.

#### Scenario: GoRouterState e helpers de navegação do go_router ficam acessíveis

- **WHEN** um consumidor importa `package:go_router_modular/go_router_modular.dart`
- **THEN** `GoRouterState` e os métodos da extension `GoRouterHelper` (`context.go`, `context.push`, `context.goNamed`, etc.) ficam disponíveis sem importar `package:go_router/go_router.dart`

#### Scenario: Tipos substituídos não vazam

- **WHEN** o barril principal é inspecionado
- **THEN** `GoRouter` e `ShellRoute` do `go_router` não constam entre os símbolos re-exportados

### Requirement: O barril de testes expõe a infraestrutura de testes

O sistema SHALL expor a infraestrutura de testes pelo barril `lib/testing.dart`, importável por `package:go_router_modular/testing.dart`. O barril MUST exportar `ModularTestScope`, `EventRecorder`, `RecordedEventList`, `FakeInjector` e `ModularEventBus`, e MUST re-exportar por conveniência `clearEventModuleState` e `defaultModularEventBus` de `modular_event.dart`, evitando dois imports nos testes.

Arquivos de referência: `lib/testing.dart`, `lib/src/testing/*`.

#### Scenario: Import de testes dá acesso aos utilitários

- **WHEN** um teste importa `package:go_router_modular/testing.dart`
- **THEN** `ModularTestScope`, `EventRecorder`, `RecordedEventList`, `FakeInjector` e `ModularEventBus` ficam disponíveis

#### Scenario: Re-exports de conveniência evitam segundo import

- **WHEN** um teste importa apenas o barril de testes
- **THEN** `clearEventModuleState` e `defaultModularEventBus` ficam acessíveis sem importar o barril principal

### Requirement: Superfície pública não exporta símbolos vestigiais

O sistema SHALL não exportar pelo barril público símbolos vestigiais sem utilidade. Em particular, `RouteModularModel` MUST NOT ser exportado por `lib/go_router_modular.dart`, por ser um modelo legado sem consumidores.

Arquivos de referência: `lib/go_router_modular.dart`.

#### Scenario: RouteModularModel não está na superfície pública

- **WHEN** os símbolos exportados por `lib/go_router_modular.dart` são inspecionados
- **THEN** `RouteModularModel` não está entre eles

### Requirement: O barril principal exporta os tipos de guard

O sistema SHALL exportar `ModularGuard` e `GuardFn` pelo barril principal `lib/go_router_modular.dart`, na área de roteamento. Importar `package:go_router_modular/go_router_modular.dart` MUST ser suficiente para declarar guards (`class XGuard extends ModularGuard`) e usá-los em `guards: [...]` sem imports internos de `src/`.

Arquivos de referência: `lib/go_router_modular.dart`, `lib/src/routing/guards/`.

#### Scenario: Import único dá acesso aos tipos de guard

- **WHEN** um consumidor importa `package:go_router_modular/go_router_modular.dart`
- **THEN** `ModularGuard` e `GuardFn` ficam disponíveis sem importar arquivos de `src/`

#### Scenario: Subclasse de ModularGuard usável a partir do barril

- **WHEN** o consumidor declara `class AuthGuard extends ModularGuard` usando apenas o import do barril
- **THEN** a classe compila e pode ser passada em `guards: [AuthGuard()]`
