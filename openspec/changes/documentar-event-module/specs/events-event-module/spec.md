## ADDED Requirements

### Requirement: EventModule é um Module com suporte a eventos via mixin

O sistema SHALL definir `EventModule` como classe abstrata que estende `Module` e aplica `EventListenerMixin`. O construtor MUST aceitar um `EventBus` opcional e atribuir `internalEventBus = eventBus ?? defaultModularEventBus`. Quando nenhum `EventBus` é fornecido, o módulo MUST usar o barramento global padrão; quando um `EventBus` é fornecido, o módulo MUST usar exatamente aquele barramento.

Arquivos de referência: `lib/src/events/event_module.dart`, `lib/src/events/modular_event.dart` (mixin `EventListenerMixin`), `lib/src/core/module/module.dart`.

#### Scenario: EventModule sem barramento usa o barramento global

- **WHEN** uma subclasse de `EventModule` é instanciada sem passar `eventBus`
- **THEN** `internalEventBus` é igual a `defaultModularEventBus`

#### Scenario: EventModule com barramento customizado usa o barramento fornecido

- **WHEN** uma subclasse de `EventModule` é instanciada com `EventModule(eventBus: customEventBus)`
- **THEN** `internalEventBus` é igual a `customEventBus`
- **AND** eventos disparados em `defaultModularEventBus` não acionam os ouvintes deste módulo

### Requirement: initState registra eventImports e dispara os hooks de escuta

O sistema SHALL, ao chamar `initState(InjectorReader)` em um `EventModule`, executar nesta ordem: para cada `ModularEventListener` retornado por `eventImports()` chamar `listener.listen()`, depois chamar o hook `listen()` do próprio módulo, depois `onAfterListen()`, e por fim `super.initState(i)` do `Module`. O hook `listen()` MUST ter implementação padrão vazia, permitindo que módulos sem ouvintes próprios não o sobrescrevam. `eventImports()` MUST ter implementação padrão retornando lista vazia.

Arquivos de referência: `lib/src/events/event_module.dart`, `lib/src/events/modular_event.dart`.

#### Scenario: Módulo registra ouvintes próprios e importados na inicialização

- **WHEN** um `EventModule` sobrescreve `listen()` registrando `on<T>` e `eventImports()` retorna um `ModularEventListener` que também registra `on<U>`
- **THEN** após `initState` ambos os ouvintes (`T` e `U`) estão ativos

#### Scenario: Módulo sem ouvintes inicializa sem erro

- **WHEN** um `EventModule` não sobrescreve `listen()` nem `eventImports()`
- **THEN** `initState` completa sem registrar nenhum ouvinte e sem lançar exceção

#### Scenario: eventImports vazio não registra ouvintes

- **WHEN** `eventImports()` retorna lista vazia
- **THEN** nenhum `ModularEventListener` é instanciado e nenhum ouvinte importado é registrado

### Requirement: ModularEventListener organiza ouvintes delegando ao módulo

O sistema SHALL definir `ModularEventListener` como classe abstrata que recebe o `EventModule` dono no construtor e expõe `listen()` (abstrato) e `on<T>`. A chamada `on<T>` do `ModularEventListener` MUST delegar para o `on<T>` do módulo dono, repassando `autoDispose`, `broadcast` e `exclusive`, de modo que o descarte do ouvinte importado seja governado pelo ciclo de vida do módulo.

Arquivos de referência: `lib/src/events/modular_event_listener.dart`, `lib/src/events/event_module.dart`.

#### Scenario: Ouvinte importado é descartado junto com o módulo

- **WHEN** um `ModularEventListener` registra `on<T>` com `autoDispose` verdadeiro e o módulo dono é descartado
- **THEN** a assinatura registrada pelo ouvinte importado é cancelada

#### Scenario: Ouvinte importado registra no barramento do módulo

- **WHEN** um `ModularEventListener` registra `on<T>` em um módulo cujo `internalEventBus` é customizado
- **THEN** o ouvinte recebe eventos do tipo `T` disparados nesse barramento customizado

### Requirement: dispose cancela apenas assinaturas marcadas para auto-descarte

O sistema SHALL, ao chamar `dispose()` no `EventModule`, percorrer as flags de auto-descarte do módulo (`disposeSubscriptions[eventBusId]`) e, para cada tipo cujo valor é verdadeiro, cancelar a assinatura, removê-la do estado e tratar o descarte de eventuais ouvintes exclusivos daquele tipo. Tipos marcados como `false` (auto-descarte desabilitado) MUST permanecer ativos após o `dispose`. Ao final, o mapa de flags do módulo MUST ser removido e `super.dispose()` chamado.

Arquivos de referência: `lib/src/events/modular_event.dart` (`dispose`, `_handleExclusiveListenerDisposal`).

#### Scenario: Ouvinte com auto-descarte é cancelado no dispose

- **WHEN** um ouvinte foi registrado com auto-descarte verdadeiro e o módulo é descartado
- **THEN** eventos do tipo disparados após o `dispose` não acionam mais o callback

#### Scenario: Ouvinte sem auto-descarte sobrevive ao dispose

- **WHEN** um ouvinte foi registrado com `autoDispose: false` e o módulo é descartado
- **THEN** eventos do tipo disparados após o `dispose` ainda acionam o callback
