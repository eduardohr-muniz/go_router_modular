## 1. Preparação e linha de base

- [x] 1.1 Rodar `flutter analyze` e `flutter test` para registrar a linha de base verde antes de qualquer mudança
- [x] 1.2 Confirmar a superfície pública atual de `lib/go_router_modular.dart` (lista de exports) para comparação posterior

## 2. Trocar imports de barril por imports específicos (subsistema DI)

- [x] 2.1 `di/injector.dart`: trocar barril por `core/bind/bind.dart`
- [x] 2.2 `core/manager/bind_context_tracker.dart`: trocar barril por `core/module/module.dart` + `di/bind_identifier.dart`
- [x] 2.3 `core/manager/injection_manager.dart`: trocar barril por `core/bind/bind.dart` + `core/module/module.dart` + `di/bind_identifier.dart` + `di/injector.dart` + `internal/setup.dart`
- [x] 2.4 Rodar `flutter analyze` e validar resolução sem erros

## 3. Trocar imports de barril (events, extensions, widgets)

- [x] 3.1 `events/event_module.dart`: trocar barril por `core/module` + `di/injector` + `events/modular_event` + `events/modular_event_listener` + `event_bus`
- [x] 3.2 `events/modular_event.dart`: trocar barril por `core/module` + `core/config` (modularNavigatorKey) + `di/injector` + `event_bus`
- [x] 3.3 `extensions/context_extension.dart`: trocar barril por `core/bind/bind.dart`
- [x] 3.4 `extensions/route_extension.dart`: trocar barril por `core/config/go_router_modular_configure.dart` (RouteWithCompleterService)
- [x] 3.5 `widgets/material_app_router.dart`: trocar barril por `core/config` + `widgets/modular_loader.dart`
- [x] 3.6 `widgets/parent_widget_observer.dart`: trocar barril por `core/module/module.dart` (não usava Modular)
- [x] 3.7 Rodar `flutter analyze` e validar resolução sem erros

## 4. Trocar imports de barril (asserts e routing) e remover import morto

- [x] 4.1 `internal/asserts/go_router_modular_configure_assert.dart`: FALSO-POSITIVO — o "import de barril" está dentro da string de exemplo do assert (não é import real). Nenhuma alteração; a guarda deve olhar só imports reais
- [x] 4.2 `routing/route_builder.dart`: trocar barril por imports específicos (routing siblings + `core/config` + `core/manager/injection_manager` + `core/module` + `exceptions/exception` + `widgets/modular_loader`)
- [x] 4.3 `routing/shell_modular_route.dart`: trocar barril por `routing/i_modular_route.dart` + `go_router` (usa ModularRoute e GoRouterState — não era "remover")
- [x] 4.4 Rodar `flutter analyze` e validar resolução sem erros

## 5. Guarda automatizada contra regressão

- [x] 5.1 Adicionar teste de arquitetura em `test/internal_import_discipline_test.dart` que varre `lib/src/**/*.dart` (só diretivas reais de import) e falha apontando o arquivo infrator
- [x] 5.2 Verificar que a guarda passa no estado desacoplado
- [x] 5.3 Verificar que a guarda falha ao reintroduzir um import de barril (validado com once_builder.dart e revertido)

## 6. Verificação de equivalência e fechamento

- [x] 6.1 Confirmar que a superfície pública de `lib/go_router_modular.dart` permanece idêntica à linha de base (diff vazio)
- [x] 6.2 Rodar `flutter analyze` sem warnings (lib + test)
- [x] 6.3 Rodar `flutter test` com a suíte passando — 271 testes (270 baseline + guarda), comportamento preservado
- [x] 6.4 Registrar no design o grafo real revelado como insumo para o passo B (seção "Achados durante a implementação")
