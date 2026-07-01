## 1. Linha de base

- [x] 1.1 Rodar `flutter analyze` e `flutter test` e registrar a linha de base verde
- [x] 1.2 Capturar o conjunto de símbolos públicos exportados por `lib/go_router_modular.dart` (símbolos do god-config: Modular, Modular, modularNavigatorKey, ModularRouterConfigCopyWith, RouteWithCompleterService)
- [x] 1.3 `RouteWithCompleterService` é exportado (via config) mas não usado fora do pacote → permanece exportado do novo arquivo. Decisões: arquivos novos em `core/config/`; guarda em nível de arquivo; Fase 4 (relocar marcador) dispensada (spec só exige module sem route_builder/injection_manager)

## 2. Fase 1 — Extrair responsabilidades do god-config

- [x] 2.1 Criar `modular_router_runtime.dart` com o estado neutro: `defaultTransition` (get/set) e `modularNavigatorKey`
- [x] 2.2 Criar `route_with_completer_service.dart` movendo `RouteWithCompleterService` do god-config
- [x] 2.3 Criar `modular_router_params.dart` movendo `_ModularRouterParams` (renomeado `ModularRouterParams`, interno). A extension `ModularRouterConfigCopyWith` ficou no façade (delega a `copyRouterConfig` — evita ciclo params⇄façade)
- [x] 2.4 Ajustar `go_router_modular_configure.dart` para usar os novos arquivos; `configure` escreve no runtime holder
- [x] 2.5 Rodar `flutter analyze` sem erros

## 3. Fase 2 — Cortar dependência de routing ao façade

- [x] 3.1 `route_builder` passa a ler `getDefaultTransition` do runtime holder (não de `Modular`)
- [x] 3.2 `route_builder` e `extensions/route_extension.dart` importam `RouteWithCompleterService` do novo arquivo
- [x] 3.3 `events/modular_event.dart` lê `modularNavigatorKey` do runtime holder
- [x] 3.4 Confirmar que `route_builder` não importa mais o arquivo do façade; `flutter analyze`

## 4. Fase 3 — Module como contrato puro

- [x] 4.1 Remover `configureRoutes` de `core/module/module.dart` e seus imports de `routing`/`manager`
- [x] 4.2 Mover a orquestração para `Modular.configure` (`registerAppModule(appModule)` + `ModularRouteBuilder(appModule).buildRoutes(topLevel: true)`)
- [x] 4.3 Substituir os 3 sites em `route_builder` (`submodulo.configureRoutes(...)`) por `ModularRouteBuilder(submodulo).buildRoutes(...)`
- [x] 4.4 Confirmar que `module.dart` não importa `routing/route_builder` nem `core/manager/injection_manager`; `flutter analyze`

## 5. Fase 4 — Relocar o marcador ModularRoute (DISPENSADA)

> Dispensada: a guarda opera em nível de arquivo; `module.dart → i_modular_route.dart` (folha) não cria ciclo real, e a spec só exige que `module` não importe `route_builder`/`injection_manager`. Mantido em `routing/`.

- [~] 5.1 Mover `i_modular_route.dart` (marcador `ModularRoute`) para local neutro de contrato
- [~] 5.2 Atualizar todos os imports de `ModularRoute` (routing, module, etc.)
- [~] 5.3 Confirmar fronteira de pasta limpa (`module` não depende de `routing/`); `flutter analyze`

## 6. Fase 5 — Barril público e guarda de ciclos

- [x] 6.1 Atualizar `lib/go_router_modular.dart` com os novos caminhos de `export`, preservando o conjunto de símbolos exportados
- [x] 6.2 Adicionar teste de guarda em `test/` que detecta ciclos entre áreas centrais (ao menos `module ⇄ routing` e `config ⇄ route_builder`) e falha identificando o ciclo
- [x] 6.3 Verificar que a guarda passa no estado desacoplado e falha ao reintroduzir um ciclo (teste do teste), depois reverter

## 7. Verificação de equivalência e fechamento

- [x] 7.1 Comparar o conjunto de símbolos exportados com a linha de base (tarefa 1.2) — deve ser idêntico
- [x] 7.2 Rodar `flutter analyze` (lib + test) sem warnings
- [x] 7.3 Rodar `flutter test` com a suíte passando (incluindo guardas de barril e de ciclos) — comportamento preservado
- [x] 7.4 Atualizar a guarda do passo C se necessário (novos caminhos) e revisar consistência entre proposal, specs, design e tasks
