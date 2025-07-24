import 'dart:async';
import 'package:event_bus/event_bus.dart';
import 'package:go_router_modular/go_router_modular.dart';

Map<int, Map<Type, StreamSubscription<dynamic>>> _eventSubscriptions = {};

final EventBus _eventBus = EventBus();
EventBus get modularEvent => _eventBus;

class ModularEvent {
  static ModularEvent? _instance;

  ModularEvent._();
  static ModularEvent get instance => _instance ??= ModularEvent._();

  void dispose<T>({EventBus? eventBus}) {
    eventBus ??= _eventBus;
    _eventSubscriptions[eventBus.hashCode]?[T.runtimeType]?.cancel();
    _eventSubscriptions[eventBus.hashCode]?.remove(T.runtimeType);
  }

  void on<T>(void Function(T event) callback, {EventBus? eventBus}) {
    eventBus ??= modularEvent;
    _eventSubscriptions[eventBus.hashCode]?[T.runtimeType]?.cancel();
    _eventSubscriptions[eventBus.hashCode]![T.runtimeType] = eventBus.on<T>().listen((event) => Future.microtask(() => callback(event)));
  }
}

abstract class EventModule extends Module {
  static final Map<int, Map<Type, bool>> _disposeSubscriptions = {};

  late final EventBus _eventBus;

  EventModule({EventBus? eventBus}) {
    _eventBus = eventBus ?? modularEvent;
  }

  void listen();

  void on<T>(void Function(T event) callback, {bool autoDispose = true}) {
    final eventBusId = _eventBus.hashCode;

    _eventSubscriptions[eventBusId] ??= {};
    _disposeSubscriptions[eventBusId] ??= {};

    _eventSubscriptions[eventBusId]?[T.runtimeType]?.cancel();

    _eventSubscriptions[eventBusId]![T.runtimeType] = _eventBus.on<T>().listen((event) => Future.microtask(() => callback(event)));

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
