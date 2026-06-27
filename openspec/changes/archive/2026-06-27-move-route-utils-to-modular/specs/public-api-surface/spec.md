## ADDED Requirements

### Requirement: Utilitários do go_router ficam acessíveis pela superfície pública

O sistema SHALL garantir que os utilitários úteis do `go_router` permaneçam acessíveis ao consumidor por um único import do barril principal, para que ele possa usá-los diretamente caso prefira não passar pelos wrappers da fachada `GoRouterModular`. A re-exportação MUST manter `package:go_router/go_router.dart` com `hide GoRouter, ShellRoute`, de modo que tipos como `GoRouterState` e a extension `GoRouterHelper` (que provê `context.go`, `context.push`, etc.) continuem disponíveis, sem vazar os tipos substituídos (`GoRouter`, `ShellRoute`).

Arquivos de referência: `lib/go_router_modular.dart`.

#### Scenario: GoRouterState e helpers de navegação do go_router ficam acessíveis

- **WHEN** um consumidor importa `package:go_router_modular/go_router_modular.dart`
- **THEN** `GoRouterState` e os métodos da extension `GoRouterHelper` (`context.go`, `context.push`, `context.goNamed`, etc.) ficam disponíveis sem importar `package:go_router/go_router.dart`

#### Scenario: Tipos substituídos não vazam

- **WHEN** o barril principal é inspecionado
- **THEN** `GoRouter` e `ShellRoute` do `go_router` não constam entre os símbolos re-exportados
