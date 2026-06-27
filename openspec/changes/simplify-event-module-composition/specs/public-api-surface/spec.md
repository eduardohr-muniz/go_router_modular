## MODIFIED Requirements

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
