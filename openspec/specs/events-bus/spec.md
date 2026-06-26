# Barramento de Eventos

## Purpose

Define o barramento de eventos: o defaultModularEventBus global padrão e os barramentos customizados que isolam streams de eventos.

## Requirements

### Requirement: defaultModularEventBus é o barramento global padrão

O sistema SHALL expor `defaultModularEventBus` como getter de uma única instância global de `EventBus`. Todos os pontos que omitem o parâmetro `eventBus` (`EventModule` sem barramento, `ModularEvent.fire`, `ModularEvent.instance.on`, `ModularEventMixin.on`) MUST usar essa mesma instância, de modo que disparos e escutas sem barramento explícito compartilhem o mesmo canal.

Arquivos de referência: `lib/src/events/modular_event.dart` (`defaultModularEventBus`).

#### Scenario: Disparo e escuta sem barramento se comunicam

- **WHEN** um ouvinte é registrado sem `eventBus` e um evento é disparado sem `eventBus`
- **THEN** o ouvinte recebe o evento

#### Scenario: defaultModularEventBus é estável entre acessos

- **WHEN** `defaultModularEventBus` é lido em momentos distintos
- **THEN** ambas as leituras retornam a mesma instância de `EventBus`

### Requirement: barramentos customizados isolam streams de eventos

O sistema SHALL permitir que cada `EventModule` use um `EventBus` próprio. Eventos disparados em um barramento MUST NOT acionar ouvintes registrados em outro barramento, mesmo para o mesmo tipo de evento. O estado por barramento MUST ser chaveado de forma a não colidir entre barramentos distintos.

Arquivos de referência: `lib/src/events/modular_event.dart`, `lib/src/events/event_state.dart`.

#### Scenario: Evento de um barramento não alcança outro barramento

- **WHEN** o módulo A escuta `MeuEvento` no barramento X e `MeuEvento` é disparado no barramento Y
- **THEN** o ouvinte do módulo A não é acionado

#### Scenario: Mesmo tipo em barramentos diferentes coexiste

- **WHEN** o módulo A escuta `MeuEvento` no barramento X e o módulo B escuta `MeuEvento` no barramento Y
- **THEN** disparar no barramento X aciona apenas A e disparar no barramento Y aciona apenas B

### Requirement: ModularEvent é o singleton de escuta e disparo global

O sistema SHALL expor `ModularEvent` como singleton acessível por `ModularEvent.instance`, com `on<T>(callback, {EventBus? eventBus, @Deprecated bool? broadcast, bool exclusive = false})` e `dispose<T>({EventBus? eventBus})`. O `on<T>` MUST usar `defaultModularEventBus` quando `eventBus` é omitido, cancelar a assinatura anterior do tipo no barramento e usar stream broadcast quando `exclusive` (ou `broadcast`) é verdadeiro. O `dispose<T>` MUST cancelar e remover a assinatura do tipo no barramento indicado.

Arquivos de referência: `lib/src/events/modular_event.dart` (`ModularEvent`).

#### Scenario: Escuta global recebe evento do tipo

- **WHEN** `ModularEvent.instance.on<MeuEvento>` é registrado e `MeuEvento` é disparado no barramento global
- **THEN** o callback é acionado

#### Scenario: dispose remove a escuta global do tipo

- **WHEN** `ModularEvent.instance.dispose<MeuEvento>()` é chamado e em seguida `MeuEvento` é disparado
- **THEN** o callback não é mais acionado

### Requirement: ModularEvent.fire dispara evento no barramento alvo

O sistema SHALL expor o método estático `ModularEvent.fire<T>(T event, {EventBus? eventBus})` que dispara o evento em `eventBus ?? defaultModularEventBus`. Quando `SetupModular.instance.debugLogEventBus` está habilitado, o disparo MUST registrar um log com o tipo do evento.

Arquivos de referência: `lib/src/events/modular_event.dart` (`fire`).

#### Scenario: Evento disparado alcança ouvintes do barramento padrão

- **WHEN** `ModularEvent.fire(MeuEvento())` é chamado sem `eventBus` e há um ouvinte global de `MeuEvento`
- **THEN** o ouvinte recebe o evento

#### Scenario: Evento disparado em barramento customizado alcança apenas esse barramento

- **WHEN** `ModularEvent.fire(MeuEvento(), eventBus: customEventBus)` é chamado
- **THEN** apenas ouvintes registrados em `customEventBus` recebem o evento

### Requirement: EventState centraliza o estado do sistema de eventos

O sistema SHALL concentrar todo o estado de eventos no singleton `EventState`, contendo: `subscriptions` (assinaturas ativas por módulo/tipo), `disposeSubscriptions` (flags de auto-descarte por módulo/tipo), `exclusiveStreams`, `exclusiveQueue` e `activeExclusiveListener` (infraestrutura dos ouvintes exclusivos por barramento/tipo). O sistema MUST expor `clearAll()` que cancela todas as assinaturas e limpa todos os mapas. As assinaturas e flags MUST ser chaveadas por `eventBusId` (`internalEventBus.hashCode + hashCode` do módulo) e as estruturas exclusivas por `internalEventBus.hashCode`.

Arquivos de referência: `lib/src/events/event_state.dart`, `lib/src/events/modular_event.dart` (`eventBusId`).

#### Scenario: clearAll cancela assinaturas e zera o estado

- **WHEN** há ouvintes ativos e `EventState.instance.clearAll()` é chamado
- **THEN** todas as assinaturas são canceladas e todos os mapas de estado ficam vazios

#### Scenario: Estado de módulos distintos não colide

- **WHEN** dois módulos no mesmo barramento registram ouvintes do mesmo tipo
- **THEN** cada um possui sua própria entrada em `subscriptions` chaveada pelo `eventBusId` do módulo
