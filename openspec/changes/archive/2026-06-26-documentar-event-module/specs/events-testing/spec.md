## ADDED Requirements

### Requirement: clearEventModuleState reinicia o estado global entre testes

O sistema SHALL expor `clearEventModuleState()` (anotado com `@visibleForTesting`) que delega para `EventState.instance.clearAll()`, cancelando todas as assinaturas e limpando todos os mapas de estado. Chamar a função entre testes MUST garantir que ouvintes registrados em um teste não vazem para o seguinte.

Arquivos de referência: `lib/src/events/modular_event.dart` (`clearEventModuleState`), `lib/src/events/event_state.dart` (`clearAll`).

#### Scenario: Estado limpo evita vazamento entre testes

- **WHEN** um teste registra ouvintes e o `setUp` do próximo teste chama `clearEventModuleState()`
- **THEN** nenhum ouvinte do teste anterior é acionado no teste seguinte

#### Scenario: Limpeza sem ouvintes não falha

- **WHEN** `clearEventModuleState()` é chamado sem nenhum ouvinte registrado
- **THEN** a chamada completa sem lançar exceção

### Requirement: EventRecorder grava eventos disparados durante testes

O sistema SHALL expor `EventRecorder` (criado por `EventRecorder.fresh()`) que grava eventos por tipo. `listenFor<E>({EventBus? eventBus})` MUST iniciar a gravação do tipo `E` no barramento informado (ou `defaultModularEventBus`), reiniciando o canal se chamado novamente para o mesmo tipo. `eventsOf<E>()` MUST retornar a lista gravada do tipo `E`, ou lista vazia se `listenFor` nunca foi chamado para `E`. `clear()` MUST apagar os eventos gravados sem cancelar os listeners; `dispose()` MUST cancelar todos os listeners e limpar o estado interno.

Arquivos de referência: `lib/src/testing/event_recorder.dart`, `lib/src/testing/recorded_event_list.dart`.

#### Scenario: Grava eventos do tipo escutado

- **WHEN** `listenFor<MeuEvento>()` é chamado e dois `MeuEvento` são disparados
- **THEN** `eventsOf<MeuEvento>()` retorna os dois eventos gravados

#### Scenario: Tipo não escutado retorna lista vazia

- **WHEN** `eventsOf<OutroEvento>()` é chamado sem `listenFor<OutroEvento>()` prévio
- **THEN** o retorno é uma lista vazia

#### Scenario: dispose cancela a gravação

- **WHEN** `dispose()` é chamado e em seguida um evento do tipo escutado é disparado
- **THEN** o evento não é gravado

### Requirement: ModularEventBus.fire é a fachada de disparo para testes

O sistema SHALL expor `ModularEventBus` como classe `abstract final` com o método estático `fire<T>(T event, {EventBus? eventBus})` que delega para `ModularEvent.fire<T>`. A fachada MUST permitir disparar eventos em testes sem importar o barrel principal do pacote.

Arquivos de referência: `lib/src/testing/modular_event_bus.dart`.

#### Scenario: fire da fachada aciona ouvintes do barramento padrão

- **WHEN** `ModularEventBus.fire(MeuEvento())` é chamado e há um ouvinte de `MeuEvento` no barramento padrão
- **THEN** o ouvinte recebe o evento

#### Scenario: fire da fachada respeita barramento customizado

- **WHEN** `ModularEventBus.fire(MeuEvento(), eventBus: customEventBus)` é chamado
- **THEN** apenas ouvintes registrados em `customEventBus` recebem o evento

### Requirement: debugLogEventBus emite logs de disparo e recebimento

O sistema SHALL registrar logs do sistema de eventos somente quando `SetupModular.instance.debugLogEventBus` está habilitado. Ao disparar, MUST emitir log `🔥 Event fired: <tipo>`; ao receber, MUST emitir log `📨 Event received: <tipo>`; ambos sob o nome `EVENT GO_ROUTER_MODULAR`. Com a flag desabilitada, nenhum log MUST ser emitido.

Arquivos de referência: `lib/src/events/modular_event.dart`, `lib/src/events/modular_event_mixin.dart`, `lib/src/internal/setup.dart`.

#### Scenario: Logs aparecem quando o debug está habilitado

- **WHEN** `debugLogEventBus` é verdadeiro e um evento é disparado e recebido
- **THEN** são emitidos os logs de disparo e de recebimento

#### Scenario: Sem logs quando o debug está desabilitado

- **WHEN** `debugLogEventBus` é falso e um evento é disparado e recebido
- **THEN** nenhum log do sistema de eventos é emitido
