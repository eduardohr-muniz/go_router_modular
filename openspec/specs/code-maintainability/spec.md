# Manutenibilidade do Código

## Purpose

Saúde estrutural do pacote: ausência de código morto conhecido, decomposição do construtor de rotas em componentes coesos por responsabilidade, e navegação assíncrona sem boilerplate de completer duplicado.

## Requirements

### Requirement: Ausência de código morto conhecido

O sistema SHALL não conter os componentes mortos identificados no review: o helper de log interno (`iLog`/`kInternalLogs`), o modelo vestigial `RouteModularModel` e o motor de telemetria `DependencyAnalyzer` (nunca consumido pela resolução de binds em produção). Esses arquivos MUST ser removidos, junto com seus testes e referências.

Arquivos de referência: `lib/src/shared/internal_logs.dart`, `lib/src/routing/route_model.dart`, `lib/src/di/dependency_analyzer.dart`, `lib/src/testing/modular_test_scope.dart`.

#### Scenario: Arquivos mortos não existem mais

- **WHEN** a árvore `lib/src/` é inspecionada
- **THEN** não existem `shared/internal_logs.dart`, `routing/route_model.dart` nem `di/dependency_analyzer.dart`

#### Scenario: Remoção não quebra a suíte

- **WHEN** a suíte de testes é executada após a remoção
- **THEN** ela passa, sem referências pendentes aos componentes removidos

### Requirement: route_builder decomposto por responsabilidade

O sistema SHALL decompor a construção de rotas em componentes coesos: um normalizador de path puro, um builder por tipo de rota (child, module, shell/stateful) e um resolvedor de transições. O `ModularRouteBuilder` MUST permanecer como orquestrador que delega a esses componentes, sem concentrar a lógica de todos os tipos de rota num único arquivo. O comportamento de construção de rotas MUST ser idêntico ao anterior.

Arquivos de referência: `lib/src/routing/route_builder.dart` e os novos componentes extraídos.

#### Scenario: Orquestrador delega a builders coesos

- **WHEN** `ModularRouteBuilder.buildRoutes` é chamado
- **THEN** ele delega a construção de cada tipo de rota ao builder correspondente
- **AND** o conjunto de rotas resultante é idêntico ao produzido antes da decomposição

#### Scenario: Normalização de path isolada e reutilizável

- **WHEN** um path precisa ser normalizado (top-level vs aninhado, barras duplicadas)
- **THEN** a normalização é feita por um componente dedicado e puro
- **AND** produz os mesmos resultados de antes

### Requirement: Navegação assíncrona sem boilerplate duplicado

O sistema SHALL centralizar o padrão de navegação assíncrona (registrar completer, navegar, completar e invocar `onComplete`) em um único helper, eliminando a repetição entre as variantes (`goAsync`, `pushAsync`, `replaceAsync` e suas formas nomeadas). O comportamento observável de cada variante MUST permanecer idêntico.

Arquivos de referência: `lib/src/ui/route_extension.dart` e o helper extraído.

#### Scenario: Variantes async delegam a um helper comum

- **WHEN** qualquer variante de navegação assíncrona é chamada
- **THEN** ela usa o helper comum de completer
- **AND** conclui com o mesmo comportamento (aguardar a navegação e invocar `onComplete`) de antes
