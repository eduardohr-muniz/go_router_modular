# Escuta de Eventos

## Purpose

Define a escuta de eventos: o registro de ouvintes tipados via on com callback que recebe contexto opcional, e o controle de autoDispose por ouvinte sobre o padrão global.

## Requirements

### Requirement: on registra ouvinte tipado com callback que recebe contexto opcional

O sistema SHALL expor, via `EventModule`, o método `on<T>(void Function(T event, BuildContext? context) callback, {bool? autoDispose, @Deprecated bool? broadcast, bool exclusive = false})`. Cada evento recebido MUST invocar o callback com o evento e o `BuildContext` atual do navegador modular (`modularNavigatorKey.currentContext`), que MAY ser nulo. Registrar `on<T>` para um tipo `T` já registrado no mesmo escopo (mesmo `eventBusId`) MUST cancelar a assinatura anterior antes de criar a nova (apenas o último callback de cada tipo permanece ativo).

Arquivos de referência: `lib/src/events/event_module.dart` (`on`, `_registerRegularListener`).

#### Scenario: Callback recebe o evento disparado

- **WHEN** um módulo registra `on<MeuEvento>` e `MeuEvento` é disparado no barramento do módulo
- **THEN** o callback é invocado com a instância de `MeuEvento`

#### Scenario: Segundo registro do mesmo tipo substitui o anterior

- **WHEN** um módulo registra `on<MeuEvento>` duas vezes com callbacks diferentes
- **THEN** apenas o segundo callback é acionado quando `MeuEvento` é disparado

#### Scenario: Contexto pode ser nulo

- **WHEN** não há navegador modular montado e um evento é recebido
- **THEN** o callback é invocado com `context` nulo, sem lançar exceção

### Requirement: autoDispose por ouvinte sobrepõe o padrão global

O sistema SHALL determinar o auto-descarte de cada ouvinte por `autoDispose ?? SetupModular.instance.autoDisposeEvents` e armazenar o resultado em `disposeSubscriptions[eventBusId][T]`. Quando `autoDispose` é omitido, o ouvinte MUST seguir a configuração global; quando informado, o valor por ouvinte MUST prevalecer sobre a configuração global.

Arquivos de referência: `lib/src/events/event_module.dart` (`on`, atribuição de `disposeSubscriptions`), `lib/src/internal/setup.dart`.

#### Scenario: Ouvinte herda o padrão global quando autoDispose é omitido

- **WHEN** a configuração global `autoDisposeEvents` é verdadeira e um ouvinte é registrado sem `autoDispose`
- **THEN** o ouvinte é cancelado quando o módulo é descartado

#### Scenario: Ouvinte sobrescreve o padrão global

- **WHEN** a configuração global `autoDisposeEvents` é verdadeira e um ouvinte é registrado com `autoDispose: false`
- **THEN** o ouvinte permanece ativo após o módulo ser descartado

### Requirement: parâmetro broadcast depreciado mapeia para exclusive

O sistema SHALL manter o parâmetro `broadcast` marcado como `@Deprecated('Use exclusive parameter instead.')` em `on<T>` e resolver o modo do ouvinte por `exclusive = broadcast ?? exclusive`. Quando `broadcast` é informado, ele MUST sobrepor o valor de `exclusive`; quando omitido, o valor de `exclusive` MUST ser usado.

Arquivos de referência: `lib/src/events/event_module.dart` (`on`).

#### Scenario: broadcast verdadeiro ativa o modo exclusivo

- **WHEN** um ouvinte é registrado com `broadcast: true` e `exclusive` omitido
- **THEN** o ouvinte é tratado como exclusivo

#### Scenario: exclusive é usado quando broadcast é omitido

- **WHEN** um ouvinte é registrado com `exclusive: true` e `broadcast` omitido
- **THEN** o ouvinte é tratado como exclusivo

### Requirement: ouvintes regulares recebem todos os eventos do tipo

O sistema SHALL registrar ouvintes não exclusivos (`exclusive = false`) como assinaturas diretas de `internalEventBus.on<T>()`. Múltiplos módulos distintos com ouvintes regulares para o mesmo tipo no mesmo barramento MUST cada um receber o evento. Um ouvinte regular MUST NOT ser registrado para um tipo que já possui stream exclusivo ativo no mesmo barramento (a tentativa é silenciosamente ignorada).

Arquivos de referência: `lib/src/events/event_module.dart` (`_registerRegularListener`).

#### Scenario: Vários módulos regulares recebem o mesmo evento

- **WHEN** dois módulos diferentes registram `on<MeuEvento>` regular no mesmo barramento e `MeuEvento` é disparado
- **THEN** ambos os callbacks são acionados

#### Scenario: Ouvinte regular é ignorado quando já existe exclusivo do mesmo tipo

- **WHEN** já existe um stream exclusivo para `MeuEvento` no barramento e um módulo tenta registrar `on<MeuEvento>` regular
- **THEN** nenhuma assinatura regular é criada para esse tipo

### Requirement: ouvintes exclusivos formam fila com apenas um ativo por tipo

O sistema SHALL gerenciar ouvintes exclusivos (`exclusive = true`) como uma fila FIFO por par (barramento, tipo), com um único ouvinte ativo recebendo eventos. Ao registrar um ouvinte exclusivo o sistema MUST criar (se necessário) um stream broadcast para o tipo, remover qualquer entrada anterior do mesmo módulo na fila, adicionar o novo ouvinte ao fim e ativar o próximo da fila quando não houver ativo. Quando o ouvinte ativo é descartado, o sistema MUST cancelar sua assinatura e ativar o próximo da fila; quando a fila esvazia, MUST remover o stream, a fila e o registro de ativo daquele tipo.

Arquivos de referência: `lib/src/events/event_module.dart` (`_registerExclusiveListener`, `_activateNextExclusiveListener`, `_handleExclusiveListenerDisposal`), `lib/src/events/event_state.dart` (`ExclusiveListener`).

#### Scenario: Apenas o ouvinte ativo recebe o evento exclusivo

- **WHEN** dois módulos registram `on<MeuEvento>` exclusivo no mesmo barramento e `MeuEvento` é disparado
- **THEN** apenas um ouvinte (o ativo) recebe o evento

#### Scenario: Descarte do ativo reativa o próximo da fila

- **WHEN** o módulo cujo ouvinte exclusivo está ativo é descartado e ainda há outro ouvinte na fila
- **THEN** o próximo ouvinte da fila passa a receber os eventos do tipo

#### Scenario: Fila vazia limpa o estado do tipo exclusivo

- **WHEN** o último ouvinte exclusivo de um tipo é descartado
- **THEN** o stream exclusivo, a fila e o registro de ativo daquele tipo são removidos

### Requirement: ModularEventMixin escuta eventos no ciclo de vida de um StatefulWidget

O sistema SHALL expor `ModularEventMixin<T extends StatefulWidget> on State<T>` com `on<E>(callback, {EventBus? eventBus, bool exclusive = false})`. O mixin MUST usar `defaultModularEventBus` quando `eventBus` é omitido, cancelar a assinatura anterior do mesmo tipo `E`, usar stream broadcast quando `exclusive` é verdadeiro e invocar o callback com `mounted ? context : null`. No `dispose` do `State`, o mixin MUST cancelar todas as assinaturas e limpar o mapa interno.

Arquivos de referência: `lib/src/events/modular_event_mixin.dart`.

#### Scenario: Widget recebe evento enquanto montado

- **WHEN** um `State` com `ModularEventMixin` registra `on<MeuEvento>` em `initState` e `MeuEvento` é disparado com o widget montado
- **THEN** o callback é invocado com um `context` não nulo

#### Scenario: Assinaturas são canceladas no dispose do widget

- **WHEN** o `State` que usa o mixin é descartado e em seguida um evento do tipo escutado é disparado
- **THEN** o callback não é mais invocado

#### Scenario: Novo registro do mesmo tipo cancela o anterior

- **WHEN** o `State` registra `on<MeuEvento>` duas vezes
- **THEN** apenas a última assinatura permanece ativa
