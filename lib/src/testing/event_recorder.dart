import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:go_router_modular/src/events/modular_event.dart';
import 'package:go_router_modular/src/testing/recorded_event_list.dart';

/// Canal interno que mantém uma subscription e os eventos gravados.
///
/// Object Calisthenics:
///   - Duas variáveis de instância (Regra 8)
class _EventChannel<E> {
  final List<E> _events;
  StreamSubscription<E>? _subscription;

  _EventChannel() : _events = [];

  void startListening(EventBus bus) {
    _subscription?.cancel();
    _subscription = bus.on<E>().listen(_events.add);
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  void clear() => _events.clear();

  RecordedEventList<E> snapshot() => RecordedEventList(List.of(_events));
}

// ─────────────────────────────────────────────────────────────────────────────

/// Grava eventos disparados no EventBus durante testes.
///
/// Uso:
/// ```dart
/// final recorder = EventRecorder.fresh();
/// recorder.listenFor<MyEvent>();
///
/// MyEventBus.fire(MyEvent(...));
/// await Future.delayed(Duration(milliseconds: 50));
///
/// expect(recorder.eventsOf<MyEvent>().length, 1);
/// recorder.dispose();
/// ```
///
/// Object Calisthenics:
///   - Uma única variável de instância (Regra 8)
///   - Coleção de primeira classe via `_channels` (Regra 4)
class EventRecorder {
  // Stores `_EventChannel<E>` as dynamic; type safety enforced by listenFor<E>/eventsOf<E>.
  final Map<Type, dynamic> _channels;

  EventRecorder.fresh() : _channels = {};

  /// Inicia a gravação de eventos do tipo [E].
  ///
  /// Pode ser chamado múltiplas vezes para tipos diferentes.
  /// Chamar duas vezes para o mesmo tipo reinicia o listener.
  void listenFor<E>({EventBus? eventBus}) {
    final bus = eventBus ?? defaultModularEventBus;
    final channel = _EventChannel<E>();
    channel.startListening(bus);
    _channels[E] = channel;
  }

  /// Retorna os eventos gravados do tipo [E].
  ///
  /// Retorna lista vazia se [listenFor] nunca foi chamado para [E].
  RecordedEventList<E> eventsOf<E>() {
    final channel = _channels[E];
    if (channel == null) return RecordedEventList<E>.empty();
    return (channel as _EventChannel<E>).snapshot();
  }

  /// Apaga todos os eventos gravados sem cancelar os listeners.
  void clear() {
    for (final channel in _channels.values) {
      channel.clear();
    }
  }

  /// Cancela todos os listeners e limpa o estado interno.
  void dispose() {
    for (final channel in _channels.values) {
      channel.stop();
    }
    _channels.clear();
  }
}
