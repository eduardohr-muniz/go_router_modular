## Why

O `EventModule` hoje carrega um mecanismo de composição de ouvintes — `eventImports()` + a classe `ModularEventListener` — que é **código morto**: está definido e exportado na API pública, mas não é usado em `lib/`, `example/` nem `test/`. Além disso, o `EventModule` depende do mixin `EventListenerMixin` (definido em `modular_event.dart`), o que espalha a responsabilidade do módulo de eventos por dois arquivos e força `event_module.dart` a importar artefatos de eventos que deixaram de fazer sentido.

A intenção é simplificar a composição entre módulos de eventos para um modelo direto e óbvio — um `EventModule` chama o `listen()` de outro `EventModule` dentro do próprio `listen()` — eliminando a abstração intermediária, reduzindo a superfície pública e respeitando Single Responsibility e Clean Code (remover abstração não utilizada).

```dart
class EventModuleA extends EventModule {
  @override
  void listen() {
    on<EventoDoA>((event, context) { /* ... */ });
    EventModuleB().listen(); // composição direta, sem ModularEventListener
  }
}
```

## What Changes

- **BREAKING** — Remover a classe `ModularEventListener` e o arquivo `lib/src/events/modular_event_listener.dart`. A composição passa a ser feita chamando `OutroEventModule().listen()` diretamente dentro de `listen()`.
- **BREAKING** — Remover o método `eventImports()` de `EventModule` e o passo de registro de `eventImports` em `initState`.
- **BREAKING** — Deixar de expor `EventListenerMixin` como mixin público: a lógica de `on`/`listen`/`onAfterListen`/`dispose` e o gerenciamento de assinaturas (regular e exclusivo) passa a viver diretamente em `EventModule`, que estende `Module`. O único mixin público remanescente do subsistema de eventos passa a ser `ModularEventMixin` (para `State<StatefulWidget>`).
- Composição de módulos respeita o ciclo de vida do host: ouvintes registrados por um módulo composto via `OutroEventModule().listen()` herdam o escopo de descarte do módulo host (mesmo `eventBusId`), sendo cancelados quando o host é descartado e re-registrados de forma idempotente por tipo, sem acúmulo/duplicação ao recriar o host.
- Remover o import de eventos que se torna desnecessário em `event_module.dart` (`modular_event_listener.dart`), e consolidar a definição do módulo de eventos.
- Atualizar as exportações em `lib/go_router_modular.dart` (remover `ModularEventListener` e `EventListenerMixin`).

## Não-objetivos

- Não alterar a semântica de ouvintes regulares vs. exclusivos (fila FIFO, um ativo por tipo), nem o comportamento de `autoDispose`, `broadcast` (depreciado) e `exclusive`.
- Não alterar `ModularEvent` (API estática global) nem `ModularEventMixin` (mixin de `State`).
- Não mudar o `EventBus` padrão, o `defaultModularEventBus` ou o contrato de `clearEventModuleState`.
- Não introduzir um novo mecanismo declarativo de imports — a composição é imperativa via chamada de `listen()`.

## Capabilities

### New Capabilities

(nenhuma)

### Modified Capabilities

- `events-event-module`: remover os requisitos de `eventImports()` e de `ModularEventListener`; redefinir `EventModule` como `Module` concreto (sem `EventListenerMixin` público) e definir a composição entre módulos via chamada direta de `listen()` herdando o escopo de descarte do host.
- `events-listening`: atualizar as referências de arquivo/origem de `on<T>` e dos parâmetros (`autoDispose`, `broadcast`, `exclusive`) para `EventModule` em vez do mixin `EventListenerMixin`; remover a menção a `modular_event_listener.dart`.
- `public-api-surface`: remover `ModularEventListener` e `EventListenerMixin` da superfície pública exportada por `go_router_modular.dart`.

## Impact

- **Código**: `lib/src/events/event_module.dart` (consolidação + remoção de import e de `eventImports`), `lib/src/events/modular_event.dart` (mover lógica do mixin para `EventModule`), remoção de `lib/src/events/modular_event_listener.dart`, `lib/go_router_modular.dart` (exports).
- **API pública (BREAKING)**: consumidores que importam `ModularEventListener`, sobrescrevem `eventImports()` ou usam `EventListenerMixin` diretamente precisarão migrar para composição via `listen()`. Não há usos internos no repositório (apenas definições e exports).
- **Testes**: `test/event_module_test.dart` referencia `EventListenerMixin` (via import aliasado para `clearEventModuleState`) e precisa de ajuste; adicionar testes de composição host→filho (descarte herdado, idempotência, ausência de duplicação).
- **Dependências**: nenhuma alteração em `event_bus` ou em outras dependências.
