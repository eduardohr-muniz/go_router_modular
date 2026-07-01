# Superfície da API Pública

## MODIFIED Requirements

### Requirement: O barril principal exporta os tipos de guard

O sistema SHALL exportar `RouteGuard` e `GuardFn` pelo barril principal `lib/go_router_modular.dart`, na área de roteamento. Importar `package:go_router_modular/go_router_modular.dart` MUST ser suficiente para declarar guards (`class XGuard extends RouteGuard`) e usá-los em `guards: [...]` sem imports internos de `src/`.

Arquivos de referência: `lib/go_router_modular.dart`, `lib/src/routing/guards/`.

#### Scenario: Import único dá acesso aos tipos de guard

- **WHEN** um consumidor importa `package:go_router_modular/go_router_modular.dart`
- **THEN** `RouteGuard` e `GuardFn` ficam disponíveis sem importar arquivos de `src/`

#### Scenario: Subclasse de RouteGuard usável a partir do barril

- **WHEN** o consumidor declara `class AuthGuard extends RouteGuard` usando apenas o import do barril
- **THEN** a classe compila e pode ser passada em `guards: [AuthGuard()]`
