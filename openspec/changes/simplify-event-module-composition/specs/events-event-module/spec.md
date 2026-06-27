## MODIFIED Requirements

### Requirement: EventModule é um Module concreto com suporte a eventos

O sistema SHALL definir `EventModule` como classe abstrata que estende `Module` e incorpora diretamente a lógica de escuta de eventos (sem aplicar um mixin público). O construtor MUST aceitar um `EventBus` opcional e atribuir `internalEventBus = eventBus ?? defaultModularEventBus`. Quando nenhum `EventBus` é fornecido, o módulo MUST usar o barramento global padrão; quando um `EventBus` é fornecido, o módulo MUST usar exatamente aquele barramento. O sistema MUST NOT expor `EventListenerMixin` como tipo público.

Arquivos de referência: `lib/src/events/event_module.dart`, `lib/src/core/module/module.dart`.

#### Scenario: EventModule sem barramento usa o barramento global

- **WHEN** uma subclasse de `EventModule` é instanciada sem passar `eventBus`
- **THEN** `internalEventBus` é igual a `defaultModularEventBus`

#### Scenario: EventModule com barramento customizado usa o barramento fornecido

- **WHEN** uma subclasse de `EventModule` é instanciada com `EventModule(eventBus: customEventBus)`
- **THEN** `internalEventBus` é igual a `customEventBus`
- **AND** eventos disparados em `defaultModularEventBus` não acionam os ouvintes deste módulo

#### Scenario: EventModule é um Module sem mixin público de eventos

- **WHEN** o tipo `EventModule` é inspecionado
- **THEN** ele é subtipo de `Module`
- **AND** não há tipo público `EventListenerMixin` envolvido na sua definição

### Requirement: initState dispara os hooks de escuta do módulo

O sistema SHALL, ao chamar `initState(InjectorReader)` em um `EventModule`, executar nesta ordem: definir o módulo como escopo de host ativo, chamar o hook `listen()` do próprio módulo, depois `onAfterListen()`, restaurar o escopo de host anterior, e por fim `super.initState(i)` do `Module`. O hook `listen()` MUST ter implementação padrão vazia, permitindo que módulos sem ouvintes próprios não o sobrescrevam. O sistema MUST NOT expor mais o método `eventImports()`.

Arquivos de referência: `lib/src/events/event_module.dart`.

#### Scenario: Módulo registra ouvintes próprios na inicialização

- **WHEN** um `EventModule` sobrescreve `listen()` registrando `on<T>`
- **THEN** após `initState` o ouvinte de `T` está ativo

#### Scenario: Módulo sem ouvintes inicializa sem erro

- **WHEN** um `EventModule` não sobrescreve `listen()`
- **THEN** `initState` completa sem registrar nenhum ouvinte e sem lançar exceção

#### Scenario: onAfterListen é chamado após listen

- **WHEN** um `EventModule` sobrescreve `listen()` e `onAfterListen()`
- **THEN** `listen()` é executado antes de `onAfterListen()` durante `initState`

### Requirement: dispose cancela apenas assinaturas marcadas para auto-descarte

O sistema SHALL, ao chamar `dispose()` no `EventModule`, percorrer as flags de auto-descarte do módulo (`disposeSubscriptions[eventBusId]`) e, para cada tipo cujo valor é verdadeiro, cancelar a assinatura, removê-la do estado e tratar o descarte de eventuais ouvintes exclusivos daquele tipo. Tipos marcados como `false` (auto-descarte desabilitado) MUST permanecer ativos após o `dispose`. Ao final, o mapa de flags do módulo MUST ser removido e `super.dispose()` chamado.

Arquivos de referência: `lib/src/events/event_module.dart` (`dispose`, `_handleExclusiveListenerDisposal`).

#### Scenario: Ouvinte com auto-descarte é cancelado no dispose

- **WHEN** um ouvinte foi registrado com auto-descarte verdadeiro e o módulo é descartado
- **THEN** eventos do tipo disparados após o `dispose` não acionam mais o callback

#### Scenario: Ouvinte sem auto-descarte sobrevive ao dispose

- **WHEN** um ouvinte foi registrado com `autoDispose: false` e o módulo é descartado
- **THEN** eventos do tipo disparados após o `dispose` ainda acionam o callback

## ADDED Requirements

### Requirement: Composição de módulos via listen herda o escopo do host

O sistema SHALL permitir que um `EventModule` componha os ouvintes de outro `EventModule` chamando `OutroEventModule().listen()` de forma síncrona dentro do próprio `listen()`. Os ouvintes registrados pelo módulo composto MUST ser gravados sob o `eventBusId` e o `internalEventBus` do módulo host (o módulo de topo cujo `initState` definiu o escopo de host ativo), de modo que: (a) sejam cancelados quando o host for descartado conforme as flags de `autoDispose`; e (b) o re-registro seja idempotente por tipo — recriar o host cancela e re-registra os ouvintes do filho sem acúmulo nem duplicação. Quando não há host ativo (o `listen()` é chamado fora de uma inicialização de módulo), o `on<T>` MUST usar o escopo próprio da instância.

Arquivos de referência: `lib/src/events/event_module.dart`.

#### Scenario: Ouvinte composto é descartado junto com o host

- **WHEN** `EventModuleA.listen()` chama `EventModuleB().listen()` que registra `on<T>` com auto-descarte, e o host `A` é descartado
- **THEN** eventos de `T` disparados após o `dispose` de `A` não acionam mais o callback do filho

#### Scenario: Recriar o host não duplica ouvintes compostos

- **WHEN** um host que compõe `EventModuleB().listen()` é inicializado, descartado e inicializado novamente
- **THEN** um único callback de cada tipo registrado pelo filho permanece ativo (sem disparo duplicado)

#### Scenario: Ouvinte composto recebe eventos no barramento do host

- **WHEN** `EventModuleA` usa o barramento padrão e compõe `EventModuleB().listen()` registrando `on<T>`, e `T` é disparado no barramento padrão
- **THEN** o callback do filho é acionado

#### Scenario: listen sem host ativo usa o escopo próprio

- **WHEN** `EventModuleB().listen()` é chamado diretamente fora de qualquer `initState` de host
- **THEN** os ouvintes são registrados sob o `eventBusId` da própria instância de `B`

## REMOVED Requirements

### Requirement: ModularEventListener organiza ouvintes delegando ao módulo

**Reason**: Abstração não utilizada (código morto) — não havia consumidores em `lib/`, `example/` ou `test/`. A composição de ouvintes entre módulos passa a ser feita por chamada direta de `OutroEventModule().listen()` dentro de `listen()`, herdando o escopo do host.

**Migration**: Substituir cada subclasse de `ModularEventListener` por um `EventModule` cujo `listen()` registra os `on<T>`; no módulo que antes os adicionava em `eventImports()`, chamar `OutroEventModule().listen()` dentro do próprio `listen()`. Remover o uso de `eventImports()` e qualquer import de `ModularEventListener`.
