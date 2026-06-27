## Context

O subsistema de eventos está hoje dividido em:

- `event_module.dart` — `EventModule` (abstrata) estende `Module` `with EventListenerMixin`, expõe `eventImports()` e registra esses imports em `initState`.
- `modular_event.dart` — define `ModularEvent` (API estática), o mixin `EventListenerMixin` (toda a lógica de `on`/`listen`/`dispose` e o gerenciamento de assinaturas regulares e exclusivas) e helpers globais (`defaultModularEventBus`, `clearEventModuleState`).
- `modular_event_listener.dart` — `ModularEventListener`, abstração para organizar ouvintes delegando ao módulo dono. **Não utilizada** fora da própria definição e do export.
- `modular_event_mixin.dart` — `ModularEventMixin<T extends StatefulWidget>`, mixin de `State` (permanece intocado).

O estado das assinaturas é centralizado em `EventState` (singleton), chaveado por `eventBusId`. Hoje `eventBusId = internalEventBus.hashCode + hashCode` (inclui o `hashCode` da instância do módulo), o que dá a cada instância um escopo de descarte próprio — e é também o `moduleId` usado na fila de ouvintes exclusivos.

A composição entre módulos passa a ser imperativa: `EventModuleA.listen()` chama `EventModuleB().listen()`. Como `EventModuleB()` é uma instância descartável que o framework nunca inicializa nem descarta, é preciso garantir que os ouvintes do `B` herdem o ciclo de vida do host `A`.

## Goals / Non-Goals

**Goals:**

- Consolidar o `EventModule` em uma única classe concreta sobre `Module`, sem mixin público (`EventListenerMixin` deixa de ser exportado).
- Remover `eventImports()` e `ModularEventListener` (código morto).
- Habilitar composição `OutroEventModule().listen()` cujos ouvintes herdam o escopo de descarte do host (mesmo `eventBusId`/barramento), com re-registro idempotente por tipo.
- Manter inalterada toda a semântica de escuta (regular/exclusivo, `autoDispose`, `broadcast` depreciado) e o `ModularEventMixin`.

**Non-Goals:**

- Reescrever o gerenciamento de fila exclusiva ou o `EventState`.
- Suportar composição com barramento próprio do módulo filho diferente do host (a composição usa o escopo/barramento do host).
- Criar um mecanismo declarativo substituto para `eventImports`.

## Decisions

### Decisão 1: `EventModule` absorve a lógica do `EventListenerMixin`

A lógica hoje no mixin `EventListenerMixin` (`on`, `listen`, `onAfterListen`, `dispose`, registro regular/exclusivo) migra para dentro de `EventModule`, que passa a ser `abstract class EventModule extends Module` (sem `with`). `event_module.dart` deixa de importar `modular_event_listener.dart`.

- **Por que (SRP)**: a responsabilidade "módulo que escuta eventos" fica em uma única unidade, em vez de espalhada entre `EventModule` e um mixin em `modular_event.dart`. Menos pontos de mudança, melhor coesão.
- **Alternativa considerada**: manter `EventListenerMixin` interno (não exportado) e só remover do export público. Rejeitada — manter um mixin de um único consumidor é abstração sem ganho (Clean Code: remover indireção desnecessária). `ModularEvent` e os helpers globais continuam em `modular_event.dart`.

### Decisão 2: Composição via escopo de host ambiente (ambient host scope)

Introduzir um escopo de registro ativo durante a execução síncrona de `listen()` do módulo de topo. Quando o framework chama `EventModule.initState`, o módulo define a si mesmo como host ativo antes de invocar `listen()`/`onAfterListen()` e restaura o escopo anterior ao final (try/finally). O método `on<T>` resolve o escopo de registro como `escopoHostAtivo ?? escopoPróprio`.

Assim, quando `A.listen()` chama `B().listen()` de forma síncrona, o `on<T>` de `B` enxerga `A` como host ativo e registra a assinatura sob o `eventBusId` e o `internalEventBus` de `A`.

- **Por que (Dependency Inversion / Tell, Don't Ask)**: o filho não precisa conhecer o host nem receber referência explícita; ele apenas registra "no escopo ativo". O acoplamento fica no contrato (escopo ativo), não na implementação concreta do host.
- **Open/Closed**: novos módulos compostos não exigem mudança no mecanismo — basta chamar `listen()`. O ponto de extensão é o próprio `listen()` (já sobrescrevível).
- **Idempotência**: como `on<T>` já cancela a assinatura anterior do par `(eventBusId, T)`, recriar o host `A` cancela e re-registra os ouvintes do filho sob o mesmo `eventBusId`, sem acúmulo/duplicação.
- **Descarte**: no `dispose` de `A`, as assinaturas do filho — gravadas sob `eventBusId` de `A` — são canceladas conforme as flags de `autoDispose`, idêntico aos ouvintes próprios de `A`.

### Decisão 3: `eventBusId` permanece por instância

Mantemos `eventBusId = internalEventBus.hashCode + hashCode`. O compartilhamento de escopo entre host e filho acontece via escopo ambiente (Decisão 2), não alterando a fórmula.

- **Alternativa considerada**: tornar `eventBusId` dependente apenas do barramento (`internalEventBus.hashCode`). Rejeitada — `eventBusId` é usado como `moduleId` na fila de ouvintes exclusivos; torná-lo por-barramento faria módulos distintos colidirem na identidade da fila exclusiva, quebrando a semântica FIFO de "um ativo por tipo".

## Risks / Trade-offs

- **[BREAKING para a API pública]** Remoção de `ModularEventListener`, `eventImports()` e `EventListenerMixin` quebra consumidores que os usavam. → Mitigação: não há uso interno no repositório; documentar a migração para `listen()` no proposal e no changelog; a substituição é mecânica.
- **[Composição assíncrona não captura o host]** Se `listen()` registrar ouvintes dentro de callback assíncrono (`await`/`Future`), o escopo ambiente já terá sido restaurado e o `on<T>` cairá no escopo próprio do filho (descartável). → Mitigação: documentar que a composição e o registro de ouvintes devem ocorrer de forma síncrona dentro de `listen()` (já é o padrão atual do exemplo); cobrir com teste o caminho síncrono.
- **[Barramento do filho ignorado na composição]** Um filho construído com `EventBus` customizado registrará no barramento do host quando composto. → Mitigação: tratado como Non-Goal e documentado; o padrão de composição assume barramento compartilhado (default).
- **[Reentrância/aninhamento]** `A` → `B` → `C` em cadeia. → Mitigação: o escopo ativo é definido apenas pelo módulo de topo (não sobrescrito por filhos); o `finally` restaura o valor anterior, mantendo o host único durante toda a cadeia síncrona.

## Migration Plan

1. Mover a lógica de `EventListenerMixin` para `EventModule`; introduzir o escopo de host ambiente em `on<T>`/`initState`.
2. Remover `eventImports()` e o arquivo `modular_event_listener.dart`.
3. Atualizar exports em `lib/go_router_modular.dart` (remover `ModularEventListener` e `EventListenerMixin`).
4. Ajustar `test/event_module_test.dart` (import aliasado de `EventListenerMixin`) e adicionar testes de composição.
5. Rodar `flutter analyze` e `flutter test --coverage`, conferindo 100% de cobertura.

**Rollback**: a mudança é isolada ao subsistema de eventos e aos exports; reverter o commit restaura o estado anterior sem migração de dados.

## Open Questions

- Vale expor um helper explícito (ex.: `compose(EventModule)`) como açúcar sobre `OutroEventModule().listen()` para tornar a intenção mais legível? Proposta atual: não, manter a chamada direta `listen()` conforme pedido; reavaliar se a leitura ficar ambígua.
