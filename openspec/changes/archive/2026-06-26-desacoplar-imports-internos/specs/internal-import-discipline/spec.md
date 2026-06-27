## ADDED Requirements

### Requirement: Arquivos internos não importam o barril público

O sistema SHALL garantir que nenhum arquivo sob `lib/src/` importe o barril público `package:go_router_modular/go_router_modular.dart`. Cada arquivo interno MUST declarar dependências apenas dos arquivos de origem específicos que utiliza, mantendo dependências explícitas e mínimas.

Arquivos de referência: `lib/go_router_modular.dart`, `lib/src/`.

#### Scenario: Nenhum import de barril em lib/src

- **WHEN** o conteúdo de qualquer arquivo `.dart` sob `lib/src/` é inspecionado
- **THEN** não há linha que importe `package:go_router_modular/go_router_modular.dart`

#### Scenario: Import supérfluo é removido

- **WHEN** um arquivo interno não referencia nenhum símbolo do pacote (por exemplo, `routing/shell_modular_route.dart`)
- **THEN** ele não declara import de barril nem de outro arquivo interno desnecessário

### Requirement: Dependências internas explícitas e mínimas

O sistema SHALL fazer cada arquivo interno importar exatamente os arquivos que fornecem os símbolos que ele usa, sem ampliar a superfície visível além do necessário. A troca do barril por imports específicos MUST preservar a superfície pública exportada por `lib/go_router_modular.dart` e o comportamento de runtime.

Arquivos de referência: `lib/src/di/injector.dart`, `lib/src/core/manager/injection_manager.dart`, `lib/src/routing/route_builder.dart`, `lib/go_router_modular.dart`.

#### Scenario: Subsistema de DI mantém dependências mínimas

- **WHEN** as dependências de `lib/src/di/injector.dart` são inspecionadas
- **THEN** ele depende apenas do necessário do subsistema de bind (`core/bind`), sem depender de roteamento, widgets ou eventos

#### Scenario: Superfície pública preservada após a troca

- **WHEN** os imports internos são trocados do barril para imports específicos
- **THEN** os símbolos exportados por `lib/go_router_modular.dart` permanecem idênticos
- **AND** a análise estática e a suíte de testes continuam passando sem mudança de comportamento

### Requirement: Guarda automatizada contra regressão de import de barril

O sistema SHALL fornecer um teste automatizado que varre `lib/src/` e falha se qualquer arquivo importar o barril público. A guarda MUST cobrir todos os arquivos `.dart` sob `lib/src/` e MUST falhar com uma mensagem que identifique o arquivo infrator.

Arquivos de referência: `test/`, `lib/src/`.

#### Scenario: Guarda falha quando um import de barril é reintroduzido

- **WHEN** um arquivo sob `lib/src/` passa a importar `package:go_router_modular/go_router_modular.dart`
- **THEN** o teste de guarda falha
- **AND** a mensagem de falha identifica o arquivo infrator

#### Scenario: Guarda passa no estado desacoplado

- **WHEN** nenhum arquivo sob `lib/src/` importa o barril público
- **THEN** o teste de guarda passa
