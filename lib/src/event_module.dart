import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:go_router_modular/go_router_modular.dart';

Map<int, Map<Type, StreamSubscription<dynamic>>> _eventSubscriptions = {};

// EventBus global para comunicação entre módulos
EventBus modularEvent = EventBus();

void disposeModularEvent<T>({EventBus? eventBus}) {
  eventBus ??= modularEvent;
  _eventSubscriptions[eventBus.hashCode]?[T.runtimeType]?.cancel();
  _eventSubscriptions[eventBus.hashCode]?.remove(T.runtimeType);
}

abstract class EventModule extends Module {
  static final Map<int, Map<Type, bool>> _disposeSubscriptions = {};

  late final EventBus _eventBus;

  EventModule({EventBus? eventBus}) {
    _eventBus = eventBus ?? modularEvent;
  }

  // Método opcional para configuração inicial
  void listen() {
    // Implementação opcional nas classes filhas
  }

  void on<T>(void Function(T event) callback, {bool autoDispose = true}) {
    final eventBusId = _eventBus.hashCode;

    // Inicializar maps se não existirem
    _eventSubscriptions[eventBusId] ??= {};
    _disposeSubscriptions[eventBusId] ??= {};

    // Cancelar subscription anterior se existir
    _eventSubscriptions[eventBusId]?[T.runtimeType]?.cancel();

    // Registrar novo subscription
    _eventSubscriptions[eventBusId]![T.runtimeType] = _eventBus.on<T>().listen(callback);

    // Configurar auto-dispose
    _disposeSubscriptions[eventBusId]![T.runtimeType] = autoDispose;
  }

  @override
  void dispose() {
    final eventBusId = _eventBus.hashCode;

    _disposeSubscriptions[eventBusId]?.forEach((key, value) {
      if (value) {
        _eventSubscriptions[eventBusId]?[key]?.cancel();
        _eventSubscriptions[eventBusId]?.remove(key);
      }
    });

    _disposeSubscriptions.remove(eventBusId);
    _eventSubscriptions.remove(eventBusId);

    super.dispose();
  }
}
