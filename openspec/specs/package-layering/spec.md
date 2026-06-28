# Camadas do Pacote

## Purpose

Define a disciplina de camadas do pacote: ausência dos ciclos entre áreas centrais (`module ⇄ routing`, `config ⇄ route_builder`), `Module` como contrato puro independente de roteamento/manager, o composition root como único ponto que conhece todos os subsistemas, e o god-config fatiado por responsabilidade (façade, params, runtime, serviço de completer). Inclui a guarda automatizada contra os ciclos corrigidos.

## Requirements

### Requirement: Ausência de ciclos entre áreas centrais

O sistema SHALL manter o grafo de dependências entre as áreas centrais (`module`, `routing`, configuração/bootstrap) livre de ciclos. Em particular, NÃO MUST existir o ciclo `module ⇄ routing` nem `config ⇄ routing/route_builder`. A direção de dependência MUST fluir das abstrações e subsistemas para o composition root, nunca o inverso.

Arquivos de referência: `lib/src/core/module/module.dart`, `lib/src/routing/route_builder.dart`, `lib/src/core/config/`.

#### Scenario: Module não depende de routing nem de manager

- **WHEN** os imports de `lib/src/core/module/module.dart` são inspecionados
- **THEN** ele não importa `routing/route_builder.dart` nem `core/manager/injection_manager.dart`

#### Scenario: route_builder não depende do façade de configuração

- **WHEN** os imports de `lib/src/routing/route_builder.dart` são inspecionados
- **THEN** ele não importa o arquivo do façade `Modular`/`Modular`

### Requirement: Module é um contrato puro

O sistema SHALL definir `Module` sem o método `configureRoutes`. O `Module` MUST expor apenas o contrato de composição (`imports`, `binds`, `routes`, `initState`, `dispose`) e a proteção de transição (`didChangeGoingReference`/`onDidChangeGoingReference`), sem orquestrar registro de binds nem construção de rotas.

Arquivos de referência: `lib/src/core/module/module.dart`.

#### Scenario: Module não orquestra registro nem construção de rotas

- **WHEN** a superfície de `Module` é inspecionada
- **THEN** não há método `configureRoutes`
- **AND** `Module` não referencia `InjectionManager` nem `ModularRouteBuilder`

### Requirement: Composition root orquestra registro e construção

O sistema SHALL concentrar no composition root (`Modular.configure`) a orquestração que antes vivia em `Module.configureRoutes`: registrar o `AppModule` no container e construir as rotas top-level. O comportamento observável de `configure` MUST permanecer idêntico (mesma assinatura, mesmo resultado de roteamento e registro).

Arquivos de referência: `lib/src/core/config/` (composition root), `lib/src/core/manager/injection_manager.dart`, `lib/src/routing/route_builder.dart`.

#### Scenario: configure registra o AppModule e constrói as rotas

- **WHEN** `Modular.configure(appModule: ..., initialRoute: ...)` é chamado
- **THEN** o `AppModule` é registrado no container
- **AND** as rotas top-level são construídas a partir do `AppModule`
- **AND** o resultado e o comportamento são idênticos aos anteriores à refatoração

#### Scenario: Submódulos são construídos sem passar por Module

- **WHEN** `route_builder` constrói as rotas de um submódulo
- **THEN** ele usa `ModularRouteBuilder(submodulo).buildRoutes(...)` diretamente, sem chamar um método de `Module`

### Requirement: God-config fatiado por responsabilidade

O sistema SHALL separar o antigo `go_router_modular_configure.dart` em arquivos coesos por responsabilidade: (a) o façade/composition root `Modular`/`Modular`; (b) o snapshot imutável de parâmetros de router e sua extension `copyWith`; (c) o serviço de completers de navegação `RouteWithCompleterService`; (d) o holder de runtime com a transição padrão e o `modularNavigatorKey`. Cada arquivo MUST ter uma única responsabilidade.

Arquivos de referência: `lib/src/core/config/` (ou área de bootstrap resultante), `lib/src/routing/`.

#### Scenario: RouteWithCompleterService vive em arquivo próprio

- **WHEN** a localização de `RouteWithCompleterService` é inspecionada
- **THEN** ela está em um arquivo dedicado, separado do façade
- **AND** seus consumidores (`route_extension`, `route_builder`) o importam desse arquivo

#### Scenario: Estado de runtime é lido sem importar o façade

- **WHEN** `route_builder` obtém a transição padrão e `events` obtém o `modularNavigatorKey`
- **THEN** ambos leem de um holder de runtime neutro, sem importar o arquivo do façade

### Requirement: Superfície pública preservada após o fatiamento

O sistema SHALL preservar o conjunto de símbolos públicos exportados por `lib/go_router_modular.dart` após mover/fatiar os arquivos. Os caminhos dos `export` MUST ser atualizados para os novos arquivos, mas o conjunto de símbolos exportados MUST permanecer idêntico, e o comportamento de runtime MUST ser preservado (análise estática e suíte de testes passando).

Arquivos de referência: `lib/go_router_modular.dart`.

#### Scenario: Símbolos exportados idênticos após a refatoração

- **WHEN** o conjunto de símbolos exportados pelo barril público é comparado antes e depois da refatoração
- **THEN** os conjuntos são idênticos
- **AND** a análise estática e a suíte de testes continuam passando

### Requirement: Guarda automatizada contra ciclos entre áreas centrais

O sistema SHALL fornecer um teste automatizado que detecta ciclos de dependência entre as áreas centrais e falha identificando o ciclo. A guarda MUST cobrir ao menos os pares `module ⇄ routing` e `config ⇄ route_builder`.

Arquivos de referência: `test/`, `lib/src/`.

#### Scenario: Guarda falha quando um ciclo é reintroduzido

- **WHEN** um import que reintroduz o ciclo `module ⇄ routing` é adicionado
- **THEN** o teste de guarda falha
- **AND** a mensagem identifica o ciclo detectado

#### Scenario: Guarda passa no estado desacoplado

- **WHEN** nenhum ciclo entre as áreas centrais existe
- **THEN** o teste de guarda passa

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
