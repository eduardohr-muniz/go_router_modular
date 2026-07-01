## Why

Um code review do pacote (pós-refatorações C/B/A) identificou **código morto** e **arquivos com excesso de responsabilidade**. O código morto adiciona peso e confunde quem lê: `RouteModularModel` (exportado mas com zero usos), o motor de telemetria `DependencyAnalyzer` (testado, mas nunca conectado à resolução de binds em produção) e o helper `iLog`/`kInternalLogs` (nunca importado). Em paralelo, `route_builder.dart` (576 linhas) é um "God Object" que concentra 8 responsabilidades (construir cada tipo de rota, normalizar paths, resolver transições, injetar binds no redirect, gerenciar dispose), com um método de 132 linhas e duplicação 3–4×; e `route_extension.dart` (360 linhas) repete o mesmo boilerplate de completer em 8 métodos de navegação assíncrona.

Esta mudança remove o código morto e reduz a dívida de responsabilidade nos dois maiores ofensores (`route_builder` e `route_extension`), preservando comportamento e (salvo a remoção intencional de `RouteModularModel`) a superfície pública. Melhora legibilidade, testabilidade e prepara o terreno para evoluções de roteamento.

## What Changes

**Remoção de código morto:**
- Deletar `lib/src/shared/internal_logs.dart` (`iLog`, `kInternalLogs`) — nunca importado.
- Deletar `lib/src/routing/route_model.dart` (`RouteModularModel`) e remover seu `export` do barril — vestigial, zero usos. **BREAKING** (remoção de símbolo público; documentar na nota de versão).
- Deletar `lib/src/di/dependency_analyzer.dart` (`DependencyAnalyzer`) e seu teste `test/dependency_analyzer_test.dart`; remover as chamadas `DependencyAnalyzer.clearAll()` de `lib/src/testing/modular_test_scope.dart` e dos testes que a invocam — telemetria nunca consumida pela resolução de binds em produção.

**Divisão do `route_builder.dart` (SRP):**
- Extrair `RoutePathNormalizer` (utilitário puro de normalização de path).
- Extrair um builder coeso por tipo de rota: `ChildRouteBuilder`, `ModuleRouteBuilder`, `ShellRouteBuilder` (shell + stateful shell).
- Extrair `TransitionResolver` (resolução/aplicação de transição, incluindo a manipulação de `GoTransition.defaultDuration`).
- Extrair helpers que eliminam a duplicação 3–4×: construção do redirect com injeção de binds e criação do `ParentWidgetObserver`.
- `ModularRouteBuilder` permanece como orquestrador enxuto que delega aos builders.

**Dedup do `route_extension.dart`:**
- Extrair `AsyncNavigationHelper` (o padrão completer + navigate + onComplete), reduzindo os 8 métodos async a delegações de ~3 linhas.

- **Sem mudança de comportamento** observável (rotas, navegação, transições, ciclo de vida idênticos), exceto a remoção intencional do símbolo público `RouteModularModel`.

Justificativa SOLID/Clean Code: elimina código morto (DRY/Clean Code), separa responsabilidades (Single Responsibility) e remove duplicação extrema, mantendo o orquestrador como ponto de extensão (Open/Closed).

## Capabilities

### New Capabilities
- `code-maintainability`: Saúde estrutural do pacote — ausência de código morto conhecido, `route_builder` decomposto em builders coesos por responsabilidade, e navegação assíncrona sem boilerplate duplicado. Inclui guardas onde aplicável.

### Modified Capabilities
- `public-api-surface`: a superfície pública deixa de exportar `RouteModularModel` (símbolo vestigial removido).

## Impact

- **Código de produção**: deleção de 3 arquivos mortos; extração de ~6 novos arquivos a partir de `route_builder.dart` e 1 de `route_extension.dart`; `route_builder.dart` cai de 576 para ~120 linhas (orquestrador).
- **Barril público** `lib/go_router_modular.dart`: remove o export de `route_model.dart`; demais símbolos preservados; novos arquivos de builders são internos (não exportados).
- **Testes**: remove `dependency_analyzer_test.dart` e as chamadas `DependencyAnalyzer.clearAll()`; a suíte restante valida o comportamento preservado dos splits.
- **Comportamento**: preservado, exceto remoção de `RouteModularModel` (breaking de API). Verificado por `flutter analyze` + suíte + paridade de símbolos (descontando `RouteModularModel`).
- **Riscos**: a divisão de `route_builder` é a parte mais arriscada (lógica central de rotas); mitigada por fases verificáveis e pela suíte.

## Não-objetivos

- Não dividir `injection_manager.dart`, `stateful_shell_branch_transitions.dart` nem o façade `go_router_modular_configure.dart` — registrados como roadmap futuro no design, fora deste escopo.
- Não alterar comportamento de roteamento, navegação, DI ou eventos.
- Não introduzir nova dependência externa.
- Não criar barris internos por subsistema.
- Não manter compatibilidade de `RouteModularModel` (a remoção é intencional; quem porventura o use deve migrar).
