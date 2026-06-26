## Why

O `EventModule` é a camada de comunicação por eventos do `go_router_modular`: um `Module` que escuta eventos tipados e entrelaça o registro/descarte desses ouvintes ao ciclo de vida do próprio módulo. O comportamento é rico e cheio de detalhes não óbvios — ouvintes exclusivos em fila (apenas um ativo por vez, reativação automática ao descartar), descarte automático configurável (`autoDispose` global vs. por ouvinte), múltiplos barramentos (`EventBus`) isolados, parâmetro `broadcast` depreciado em favor de `exclusive`, `BuildContext` potencialmente nulo no callback, e ouvintes organizados via `eventImports()` (`ModularEventListener`) ou via `ModularEventMixin` em `StatefulWidget`. Sem documentação executável, esse comportamento é fácil de quebrar e difícil de auditar. Esta mudança documenta o sistema de eventos atual como especificação, sem alterar comportamento. Complementa as specs `documentar-sistema-di` e `documentar-sistema-roteamento`.

## What Changes

- Documentar o `EventModule` como subclasse de `Module` com `EventListenerMixin`: construtor com `EventBus` opcional, override de `initState` que registra `eventImports()` e dispara os hooks `listen()`/`onAfterListen()`, e relação com o ciclo de vida do `Module` (`initState` → `dispose`).
- Documentar a API de escuta `on<T>(callback, {autoDispose, broadcast (depreciado), exclusive})`: assinatura do callback `(T event, BuildContext? context)`, semântica de `autoDispose` (default global `SetupModular.autoDisposeEvents` vs. override por ouvinte) e o mapeamento `exclusive = broadcast ?? exclusive`.
- Documentar ouvintes **regulares** vs. **exclusivos**: regulares recebem todos os eventos do tipo; exclusivos formam fila por (barramento, tipo) com apenas um ativo, reativando o próximo da fila ao descartar o ativo, e a incompatibilidade de misturar exclusivo e regular para o mesmo tipo no mesmo barramento.
- Documentar as formas de organizar ouvintes: `ModularEventListener` (classe abstrata instanciada por `eventImports()` com seu próprio `listen()`), o hook `listen()` do próprio `EventModule`, e `ModularEventMixin` para `State<StatefulWidget>` (com `context` resolvido por `mounted ? context : null` e descarte automático no `dispose`).
- Documentar o barramento de eventos: `defaultModularEventBus` global, barramentos customizados por módulo (isolamento de streams), `ModularEvent` singleton (`instance.on<T>`, `dispose<T>`) e o disparo `ModularEvent.fire<T>(event, {eventBus})`.
- Documentar o estado centralizado `EventState` (chaveado por `eventBusId`): mapas de assinaturas, flags de auto-descarte, streams/fila/ouvinte-ativo dos exclusivos, e `clearAll()`.
- Documentar utilitários de teste e diagnóstico: `clearEventModuleState()`, `EventRecorder`, a fachada `ModularEventBus.fire`, e o log de eventos via `SetupModular.debugLogEventBus`.
- Mapear onde os princípios SOLID aparecem (inversão por callbacks/abstração `ModularEventListener`, responsabilidade isolada do `EventState`) e onde são fracos (estado global mutável compartilhado, parâmetro depreciado mantido por compatibilidade).
- **Sem mudança de comportamento**: nenhuma API é alterada, adicionada ou removida. Mudança puramente documental.

## Capabilities

### New Capabilities
- `events-event-module`: O `EventModule` como `Module` com eventos — construtor com `EventBus` opcional, ciclo de vida (`initState` registra `eventImports()` e chama `listen()`/`onAfterListen()`, `dispose` cancela assinaturas auto-descartáveis) e relação com o `Module` base.
- `events-listening`: A API de escuta — `on<T>` com callback `(event, context)`, semântica de `autoDispose`, ouvintes regulares vs. exclusivos (fila, reativação, incompatibilidade), `ModularEventListener` e `ModularEventMixin`.
- `events-bus`: O barramento e o disparo — `defaultModularEventBus`, barramentos customizados isolados, o singleton `ModularEvent` (`on`, `dispose`, `fire`) e o estado centralizado `EventState` chaveado por `eventBusId`.
- `events-testing`: Suporte a testes e diagnóstico — `clearEventModuleState()`, `EventRecorder`, a fachada `ModularEventBus.fire` e o log de eventos via `SetupModular.debugLogEventBus`.

### Modified Capabilities
<!-- Nenhuma capability existente tem requisitos alterados — esta mudança é puramente documental e não altera as specs de DI nem de roteamento já propostas. -->

## Impact

- **Código de produção**: nenhum. Nenhum arquivo em `lib/` é modificado.
- **Artefatos OpenSpec**: novos arquivos de spec em `openspec/specs/events-event-module/`, `openspec/specs/events-listening/`, `openspec/specs/events-bus/` e `openspec/specs/events-testing/`.
- **Arquivos de referência documentados** (sem alteração, apenas descritos): `lib/src/events/event_module.dart`, `lib/src/events/modular_event.dart`, `lib/src/events/modular_event_listener.dart`, `lib/src/events/event_state.dart`, `lib/src/events/modular_event_mixin.dart`, `lib/src/testing/event_recorder.dart`, `lib/src/testing/modular_event_bus.dart`, `lib/src/core/module/module.dart` e a configuração `SetupModular`/`SetupModel`.
- **Relação com DI e roteamento**: referencia, mas não duplica, as specs `documentar-sistema-di` e `documentar-sistema-roteamento`; o ciclo de vida de eventos é descrito do ponto de vista do barramento de eventos.
- **Riscos**: baixos — risco principal é divergência entre a spec e o código se o comportamento evoluir sem atualizar a spec.

## Não-objetivos

- Não alterar, refatorar ou corrigir qualquer comportamento do sistema de eventos, do barramento ou do descarte.
- Não remover os pontos fracos identificados (estado global mutável em `EventState`, parâmetro `broadcast` depreciado, acoplamento ao `event_bus`). Eles são apenas registrados como contexto para decisões futuras.
- Não redocumentar o container de DI nem o roteamento — isso é escopo das specs `documentar-sistema-di` e `documentar-sistema-roteamento`; aqui descreve-se apenas como o ciclo de vida do `Module` dispara o registro/descarte de ouvintes.
- Não criar API nova de eventos nem alterar assinaturas existentes.
- Não documentar o gerador de código ou integrações externas que apenas consomem eventos.
