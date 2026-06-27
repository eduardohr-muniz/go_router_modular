## 1. Linha de base

- [x] 1.1 Rodar `flutter analyze` e `flutter test` e registrar a linha de base verde
- [x] 1.2 Capturar o conjunto de símbolos públicos exportados por `lib/go_router_modular.dart` e `lib/testing.dart` para comparação posterior

## 2. Fase DI — consolidar o motor em di/

- [x] 2.1 `git mv` de `core/bind/*`, `core/manager/*` e `core/dependency_analyzer/dependency_analyzer.dart` para `di/`
- [x] 2.2 Reescrever imports `src/core/bind/`, `src/core/manager/`, `src/core/dependency_analyzer/...` → `src/di/...` em todo o pacote
- [x] 2.3 Rodar `flutter analyze` sem erros

## 3. Fase module

- [x] 3.1 `git mv core/module/module.dart module/module.dart`
- [x] 3.2 Reescrever imports `src/core/module/` → `src/module/` (e converter relativos remanescentes para absolutos)
- [x] 3.3 Rodar `flutter analyze` sem erros

## 4. Fase routing-runtime

- [x] 4.1 `git mv` de `core/config/modular_router_runtime.dart`, `modular_router_params.dart`, `route_with_completer_service.dart` para `routing/`
- [x] 4.2 Reescrever os imports desses três arquivos (`src/core/config/...` → `src/routing/...`)
- [x] 4.3 Rodar `flutter analyze` sem erros

## 5. Fase bootstrap

- [x] 5.1 `git mv core/config/go_router_modular_configure.dart bootstrap/`; `internal/setup.dart` → `shared/setup.dart` (correção: setup é consumido pelo DI; em bootstrap criaria di → bootstrap)
- [x] 5.2 Reescrever imports `src/core/config/go_router_modular_configure.dart` → `src/bootstrap/...` e `src/internal/setup.dart` → `src/shared/setup.dart`
- [x] 5.3 Remover a pasta `core/` agora vazia; rodar `flutter analyze`

## 6. Fase ui

- [x] 6.1 `git mv widgets/* ui/` e `git mv extensions/* ui/`
- [x] 6.2 Reescrever imports `src/widgets/` e `src/extensions/` → `src/ui/`
- [x] 6.3 Rodar `flutter analyze` sem erros

## 7. Fase shared

- [x] 7.1 `git mv exceptions/exception.dart shared/`, `git mv internal/asserts/* shared/asserts/`, `git mv internal/internal_logs.dart shared/`
- [x] 7.2 Reescrever imports `src/exceptions/`, `src/internal/asserts/`, `src/internal/internal_logs.dart` → `src/shared/...`
- [x] 7.3 Remover a pasta `internal/` agora vazia; rodar `flutter analyze`

## 8. Barris públicos

- [x] 8.1 Atualizar os `export` de `lib/go_router_modular.dart` para os novos caminhos
- [x] 8.2 Atualizar os `export` de `lib/testing.dart` para os novos caminhos
- [x] 8.3 Rodar `flutter analyze` (lib) sem erros

## 9. Atualizar guardas de arquitetura

- [x] 9.1 Atualizar `test/package_layering_test.dart` com os novos caminhos (`module/module.dart`, `routing/route_builder.dart`, `bootstrap/go_router_modular_configure.dart`)
- [x] 9.2 Confirmar que a guarda de import de barril (`test/internal_import_discipline_test.dart`) continua válida (varre `lib/src/`, independe de estrutura)
- [x] 9.3 Validar teste-do-teste: a guarda de ciclos ainda falha ao reintroduzir um ciclo nos novos caminhos, depois reverter

## 10. Verificação de equivalência e fechamento

- [x] 10.1 Comparar símbolos exportados com a linha de base (tarefa 1.2) — deve ser idêntico
- [x] 10.2 Confirmar que a pasta `core/` não existe mais e que `di/`, `module/`, `routing/`, `bootstrap/`, `events/`, `ui/`, `shared/`, `testing/` estão presentes
- [x] 10.3 Confirmar que nenhum arquivo do motor de DI reside fora de `di/`, e que `di/` não importa `routing/`/`ui/`/`bootstrap/`
- [x] 10.4 Rodar `flutter analyze` (lib + test) sem warnings
- [x] 10.5 Rodar `flutter test` com a suíte passando (incluindo guardas) — comportamento preservado
- [x] 10.6 Revisar consistência entre proposal, specs, design e tasks
