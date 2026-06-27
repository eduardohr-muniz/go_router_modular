import 'dart:developer';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/src/routing/modular_router_runtime.dart';
import 'package:go_router_modular/src/events/event_state.dart';
import 'package:go_router_modular/src/shared/setup.dart';

/// Default global EventBus used by the modular event system.
final EventBus _eventBus = EventBus();

/// Exposes the default EventBus for use by EventModule.
EventBus get defaultModularEventBus => _eventBus;

/// Gets the current Navigator context from the modular navigator key.
BuildContext? get _navigatorContext => modularNavigatorKey.currentContext;

bool get _debugLog => SetupModular.instance.debugLogEventBus;

final EventState _state = EventState.instance;

/// Clears all global event state - useful for testing.
@visibleForTesting
void clearEventModuleState() {
  _state.clearAll();
}

// ==================== ModularEvent ====================

/// Singleton class to manage global events in the application.
class ModularEvent {
  static ModularEvent? _instance;
  ModularEvent._();
  static ModularEvent get instance => _instance ??= ModularEvent._();

  int _getBusId(EventBus eventBus) => eventBus.hashCode;

  void dispose<T>({EventBus? eventBus}) {
    eventBus ??= _eventBus;
    final busId = _getBusId(eventBus);
    _state.subscriptions[busId]?[T]?.cancel();
    _state.subscriptions[busId]?.remove(T);
  }

  void on<T>(
    void Function(T event, BuildContext? context) callback, {
    EventBus? eventBus,
    @Deprecated('Use exclusive parameter instead.') bool? broadcast,
    bool exclusive = false,
  }) {
    exclusive = broadcast ?? exclusive;
    eventBus ??= _eventBus;
    final busId = _getBusId(eventBus);

    _state.subscriptions[busId] ??= {};
    _state.subscriptions[busId]?[T]?.cancel();

    if (exclusive) {
      _state.subscriptions[busId]![T] = eventBus.on<T>().asBroadcastStream().listen((event) {
        if (_debugLog) log('📨 Event received: ${event.runtimeType}', name: 'EVENT GO_ROUTER_MODULAR');
        return callback(event, _navigatorContext);
      });
    } else {
      _state.subscriptions[busId]![T] = eventBus.on<T>().listen((event) {
        if (_debugLog) log('📨 Event received: ${event.runtimeType}', name: 'EVENT GO_ROUTER_MODULAR');
        return callback(event, _navigatorContext);
      });
    }
  }

  static void fire<T>(T event, {EventBus? eventBus}) {
    eventBus ??= _eventBus;
    if (_debugLog) log('🔥 Event fired: ${event.runtimeType}', name: 'EVENT GO_ROUTER_MODULAR');
    eventBus.fire(event);
  }
}
