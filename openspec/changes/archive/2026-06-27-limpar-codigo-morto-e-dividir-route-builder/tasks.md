## 1. Linha de base

- [x] 1.1 Rodar `flutter analyze` e `flutter test` e registrar a linha de base verde
- [x] 1.2 Capturar o conjunto de símbolos públicos exportados por `lib/go_router_modular.dart` (para comparação, descontando `RouteModularModel`)

## 2. Remover internal_logs (morto, seguro)

- [x] 2.1 Deletar `lib/src/shared/internal_logs.dart`
- [x] 2.2 Confirmar que não havia importadores; `flutter analyze`

## 3. Remover RouteModularModel (morto, breaking de API)

- [x] 3.1 Remover o `export 'src/routing/route_model.dart';` de `lib/go_router_modular.dart`
- [x] 3.2 Deletar `lib/src/routing/route_model.dart`
- [x] 3.3 Confirmar zero referências em lib/test/example; `flutter analyze`

## 4. Remover DependencyAnalyzer (morto em produção)

- [x] 4.1 Deletar `lib/src/di/dependency_analyzer.dart` e `test/dependency_analyzer_test.dart`
- [x] 4.2 Remover as chamadas `DependencyAnalyzer.clearAll()` de `lib/src/testing/modular_test_scope.dart`
- [x] 4.3 Remover as chamadas/imports de `DependencyAnalyzer` dos testes que a invocam diretamente (validate_module_binds_regression, singleton_import_injection_manager_integration, simple_loop, infinite_loop_prevention)
- [x] 4.4 `flutter analyze` e `flutter test` — sem referências pendentes

## 5. Dedup de route_extension (AsyncNavigationHelper)

- [x] 5.1 Criar `AsyncNavigationHelper` com o padrão completer + navigate + onComplete
- [x] 5.2 Reescrever as 8 variantes async (`goAsync`, `goNamedAsync`, `pushAsync`, `pushNamedAsync`, `pushReplacementAsync`, `pushReplacementNamedAsync`, `replaceAsync`, `replaceNamedAsync`) como delegações ao helper
- [x] 5.3 `flutter analyze`; suíte de navegação verde

## 6. Dividir route_builder — utilitários puros primeiro

- [x] 6.1 Extrair `RoutePathNormalizer` (normalizePath/adjustRoute/parsePath) para `routing/path/route_path_normalizer.dart`; route_builder passa a usá-lo
- [x] 6.2 Extrair o helper de redirect+injeção de binds e a criação do `ParentWidgetObserver` (mata a duplicação 3–4×)
- [x] 6.3 `flutter analyze`; suíte verde

## 7. Dividir route_builder — builders por tipo de rota

- [x] 7.1 Extrair `ChildRouteBuilder` (`routing/builders/child_route_builder.dart`)
- [x] 7.2 Extrair `ModuleRouteBuilder` (`routing/builders/module_route_builder.dart`), quebrando o `_createModule` de 132 linhas em variantes shell/stateful/regular
- [x] 7.3 Extrair `ShellRouteBuilder` (`routing/builders/shell_route_builder.dart`) para shell + stateful shell
- [x] 7.4 Extrair `TransitionResolver` (`routing/transitions/transition_resolver.dart`)
- [x] 7.5 Reduzir `ModularRouteBuilder` a orquestrador que instancia e delega aos builders
- [x] 7.6 `flutter analyze`; suíte verde após cada extração

## 8. Verificação de equivalência e fechamento

- [x] 8.1 Comparar símbolos exportados com a baseline — idênticos exceto a remoção de `RouteModularModel`
- [x] 8.2 Confirmar que os novos builders são internos (não exportados pelo barril)
- [x] 8.3 Rodar `flutter analyze` (lib + test) sem warnings
- [x] 8.4 Rodar `flutter test` com a suíte passando (incluindo guardas de barril e de ciclos) — comportamento preservado
- [x] 8.5 Conferir o tamanho final de `route_builder.dart` (alvo ~120 linhas) e revisar consistência entre proposal, specs, design e tasks
