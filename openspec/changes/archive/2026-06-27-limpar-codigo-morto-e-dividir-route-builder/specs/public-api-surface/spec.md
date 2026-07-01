## ADDED Requirements

### Requirement: Superfície pública não exporta símbolos vestigiais

O sistema SHALL não exportar pelo barril público símbolos vestigiais sem utilidade. Em particular, `RouteModularModel` MUST NOT ser exportado por `lib/go_router_modular.dart`, por ser um modelo legado sem consumidores.

Arquivos de referência: `lib/go_router_modular.dart`.

#### Scenario: RouteModularModel não está na superfície pública

- **WHEN** os símbolos exportados por `lib/go_router_modular.dart` são inspecionados
- **THEN** `RouteModularModel` não está entre eles
