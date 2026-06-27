## ADDED Requirements

### Requirement: Organização de lib/src por subsistema

O sistema SHALL organizar `lib/src/` por subsistema coeso, sem a pasta agregadora `core/`. A estrutura MUST conter as áreas: `di/` (motor de injeção de dependências), `module/` (contrato de módulo), `routing/` (rotas, construção e runtime de roteamento), `bootstrap/` (composition root e configuração global), `events/` (barramento de eventos), `ui/` (widgets e extensions de apresentação), `shared/` (utilitários transversais) e `testing/` (utilidades de teste). A reorganização MUST preservar o comportamento e o conjunto de símbolos públicos exportados.

Arquivos de referência: `lib/src/`, `lib/go_router_modular.dart`, `lib/testing.dart`.

#### Scenario: Pasta core deixou de existir

- **WHEN** a estrutura de `lib/src/` é inspecionada
- **THEN** não existe a pasta `core/`
- **AND** as áreas `di/`, `module/`, `routing/`, `bootstrap/`, `events/`, `ui/`, `shared/` estão presentes

#### Scenario: Símbolos públicos preservados após a reorganização

- **WHEN** o conjunto de símbolos exportados por `lib/go_router_modular.dart` é comparado antes e depois da reorganização
- **THEN** os conjuntos são idênticos
- **AND** a análise estática e a suíte de testes continuam passando

### Requirement: Motor de DI consolidado em uma única área

O sistema SHALL concentrar todo o motor de injeção de dependências em `lib/src/di/`, incluindo definição de bind, armazenamento, registro, resolução, proteção, descarte, identificadores, gerenciamento de ciclo de vida de módulos e telemetria. Nenhum arquivo do motor de DI MUST residir fora de `lib/src/di/`.

Arquivos de referência: `lib/src/di/`.

#### Scenario: Componentes de DI vivem todos em di/

- **WHEN** a localização dos componentes de DI (bind, locator, registry, storage, protection, disposer, injector, identifiers, manager, tracker, queue, analyzer) é inspecionada
- **THEN** todos estão sob `lib/src/di/`
- **AND** não há componentes de DI sob uma pasta `core/`

#### Scenario: Fronteira de DI pronta para extração

- **WHEN** as dependências dos arquivos de `lib/src/di/` são inspecionadas
- **THEN** elas não apontam para `routing/`, `ui/` nem `bootstrap/` (a área de DI não depende de camadas superiores)

### Requirement: Guardas de arquitetura acompanham os novos caminhos

O sistema SHALL manter as guardas automatizadas válidas após a reorganização: a guarda de import de barril (`lib/src/` não importa o barril público) e a guarda de ausência de ciclos entre áreas centrais MUST referenciar os novos caminhos de arquivo e continuar passando.

Arquivos de referência: `test/`, `lib/src/`.

#### Scenario: Guardas passam com os novos caminhos

- **WHEN** as guardas de import de barril e de ausência de ciclos são executadas após a reorganização
- **THEN** ambas passam
- **AND** referenciam os caminhos atualizados (`module/module.dart`, `routing/route_builder.dart`, `bootstrap/go_router_modular_configure.dart`)
