## 1. Consolidar EventModule e o escopo de host

- [x] 1.1 Mover a lógica de escuta do mixin `EventListenerMixin` (`on`, `listen`, `onAfterListen`, `dispose`, `_registerRegularListener`, `_registerExclusiveListener`, `_activateNextExclusiveListener`, `_handleExclusiveListenerDisposal`, `internalEventBus`, `eventBusId`) de `lib/src/events/modular_event.dart` para dentro de `EventModule` em `lib/src/events/event_module.dart`, transformando-o em `abstract class EventModule extends Module` (sem `with`).
- [x] 1.2 Garantir acesso às dependências necessárias em `event_module.dart` (`EventState.instance`, `defaultModularEventBus`, `modularNavigatorKey`, `SetupModular.instance.debugLogEventBus`, `SetupModular.instance.autoDisposeEvents`) sem reintroduzir o import de `modular_event_listener.dart`.
- [x] 1.3 Implementar o escopo de host ativo: campo estático que guarda o escopo de registro (`eventBusId` e `internalEventBus`), definido em `initState` antes de `listen()`/`onAfterListen()` e restaurado em `finally`; ajustar `on<T>` para resolver `escopoHostAtivo ?? escopoPróprio`.
- [x] 1.4 Remover o método `eventImports()` de `EventModule` e o passo de registro de imports em `initState`.

## 2. Remover artefatos obsoletos

- [x] 2.1 Excluir o arquivo `lib/src/events/modular_event_listener.dart` (classe `ModularEventListener`).
- [x] 2.2 Remover do `modular_event.dart` o mixin `EventListenerMixin` (mantendo `ModularEvent`, `defaultModularEventBus`, `clearEventModuleState` e demais helpers globais).
- [x] 2.3 Atualizar `lib/go_router_modular.dart`: remover os exports de `ModularEventListener` e `EventListenerMixin`, mantendo `ModularEvent`, `clearEventModuleState`, `defaultModularEventBus`, `EventModule` e `ModularEventMixin`.

## 3. Ajustar exemplo e consumidores

- [x] 3.1 Verificar `example/lib/src/modules/example_event_module/example_event_module.dart` e demais arquivos do `example/`; ajustar caso usem `eventImports`/`ModularEventListener` (atualmente não usam).
- [x] 3.2 Atualizar `test/event_module_test.dart` para não depender de `EventListenerMixin` (substituir o import aliasado de `clearEventModuleState`).

## 4. Testes

- [x] 4.1 Testar `EventModule` consolidado: barramento padrão vs. customizado, `initState` dispara `listen()` e `onAfterListen()` na ordem correta, módulo sem `listen()` inicializa sem erro.
- [x] 4.2 Testar composição host→filho: ouvinte composto (`A.listen()` chama `B().listen()`) é descartado junto com o host; recriar o host não duplica ouvintes; ouvinte composto recebe eventos no barramento do host; `listen()` sem host ativo usa o escopo próprio.
- [x] 4.3 Testar regressão da escuta: `autoDispose` por ouvinte vs. global, `broadcast` depreciado mapeando para `exclusive`, ouvintes regulares múltiplos, fila exclusiva FIFO (ativo único, reativação no descarte, limpeza ao esvaziar), `context` nulo.
- [x] 4.4 Testar a superfície pública: `ModularEventListener` e `EventListenerMixin` não exportados por `go_router_modular.dart`; `ModularEvent`, `EventModule`, `ModularEventMixin`, `clearEventModuleState`, `defaultModularEventBus` ainda exportados.

## 5. Verificação

- [x] 5.1 Rodar `flutter analyze` (e `dart analyze`) sem erros nem avisos novos.
- [x] 5.2 Rodar `flutter test --coverage` e conferir 100% de cobertura (linhas e branches) em `coverage/lcov.info` para os arquivos de eventos alterados.
- [x] 5.3 Atualizar o `CHANGELOG.md` documentando a mudança BREAKING (remoção de `ModularEventListener`, `eventImports()` e `EventListenerMixin`) e a migração para composição via `listen()`.
