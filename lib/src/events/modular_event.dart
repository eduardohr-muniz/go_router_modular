import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/events/event_state.dart';
import 'package:go_router_modular/src/internal/setup.dart';

/// Default global EventBus used by the modular event system.
final EventBus _eventBus = EventBus();

/// Exposes the default EventBus for use by EventModule.
EventBus get defaultModularEventBus => _eventBus;

/// Gets the current Navigator context from the modular navigator key.
BuildContext? get _navigatorContext => modularNavigatorKey.currentContext;

bool get _debugLog => SetupModular.instance.debugLogEventBus;
bool get _autoDisposeEvents => SetupModular.instance.autoDisposeEvents;

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

// ==================== EventListenerMixin ====================

/// Mixin for Module that provides event listener auto-lifecycle management.
mixin EventListenerMixin on Module {
  late final EventBus internalEventBus;

  int get eventBusId => internalEventBus.hashCode + hashCode;

  void listen() {}

  void on<T>(
    void Function(T event, BuildContext? context) callback, {
    bool? autoDispose,
    @Deprecated('Use exclusive parameter instead.') bool? broadcast,
    bool exclusive = false,
  }) {
    exclusive = broadcast ?? exclusive;

    _state.subscriptions[eventBusId] ??= {};
    _state.disposeSubscriptions[eventBusId] ??= {};

    _state.subscriptions[eventBusId]?[T]?.cancel();

    final eventBusHashCode = internalEventBus.hashCode;
    _state.exclusiveStreams[eventBusHashCode] ??= {};
    _state.exclusiveQueue[eventBusHashCode] ??= {};
    _state.activeExclusiveListener[eventBusHashCode] ??= {};

    if (exclusive) {
      _registerExclusiveListener<T>(callback, eventBusHashCode);
    } else {
      _registerRegularListener<T>(callback, eventBusHashCode);
    }

    _state.disposeSubscriptions[eventBusId]![T] = autoDispose ?? _autoDisposeEvents;
  }

  void _registerExclusiveListener<T>(
    void Function(T event, BuildContext? context) callback,
    int eventBusHashCode,
  ) {
    if (_state.exclusiveStreams[eventBusHashCode]![T] == null) {
      _state.exclusiveStreams[eventBusHashCode]![T] = internalEventBus.on<T>().asBroadcastStream();
    }

    _state.exclusiveQueue[eventBusHashCode]![T] ??= [];

    final exclusiveListener = ExclusiveListener(
      moduleId: eventBusId,
      callback: callback,
      getContext: () => _navigatorContext,
    );

    _state.exclusiveQueue[eventBusHashCode]![T]!.removeWhere((listener) => listener.moduleId == eventBusId);
    _state.exclusiveQueue[eventBusHashCode]![T]!.add(exclusiveListener);

    final currentActive = _state.activeExclusiveListener[eventBusHashCode]![T];
    if (currentActive?.moduleId == eventBusId) {
      currentActive?.subscription?.cancel();
      _state.activeExclusiveListener[eventBusHashCode]![T] = null;
    }

    if (_state.activeExclusiveListener[eventBusHashCode]![T] == null) {
      _activateNextExclusiveListener<T>(T, eventBusHashCode);
    }
  }

  void _registerRegularListener<T>(
    void Function(T event, BuildContext? context) callback,
    int eventBusHashCode,
  ) {
    if (_state.exclusiveStreams[eventBusHashCode]?[T] != null) return;

    _state.subscriptions[eventBusId]![T] = internalEventBus.on<T>().listen((event) {
      if (_debugLog) log('📨 Event received: ${event.runtimeType}', name: 'EVENT GO_ROUTER_MODULAR');
      return callback(event, _navigatorContext);
    });
  }

  void _activateNextExclusiveListener<T>(Type eventType, int eventBusHashCode) {
    final queue = _state.exclusiveQueue[eventBusHashCode]?[eventType];
    if (queue == null || queue.isEmpty) {
      _state.activeExclusiveListener[eventBusHashCode]![eventType] = null;
      return;
    }

    final nextListener = queue.first;

    final currentActive = _state.activeExclusiveListener[eventBusHashCode]![eventType];
    currentActive?.subscription?.cancel();

    nextListener.subscription = _state.exclusiveStreams[eventBusHashCode]![eventType]!.listen((event) {
      if (_debugLog) log('📨 Event received: ${event.runtimeType}', name: 'EVENT GO_ROUTER_MODULAR');
      return nextListener.callback(event, nextListener.getContext());
    });

    _state.activeExclusiveListener[eventBusHashCode]![eventType] = nextListener;

    _state.subscriptions[nextListener.moduleId] ??= {};
    _state.subscriptions[nextListener.moduleId]![eventType] = nextListener.subscription!;
  }

  void onAfterListen() {}

  @override
  void initState(InjectorReader i) {
    listen();
    onAfterListen();
    super.initState(i);
  }

  @override
  void dispose() {
    final eventBusHashCode = internalEventBus.hashCode;

    _state.disposeSubscriptions[eventBusId]?.forEach((key, value) {
      if (value) {
        _state.subscriptions[eventBusId]?[key]?.cancel();
        _state.subscriptions[eventBusId]?.remove(key);
        _handleExclusiveListenerDisposal(key, eventBusHashCode);
      }
    });

    _state.disposeSubscriptions.remove(eventBusId);
    super.dispose();
  }

  void _handleExclusiveListenerDisposal(Type eventType, int eventBusHashCode) {
    final queue = _state.exclusiveQueue[eventBusHashCode]?[eventType];
    if (queue != null) {
      queue.removeWhere((listener) => listener.moduleId == eventBusId);

      final activeListener = _state.activeExclusiveListener[eventBusHashCode]?[eventType];
      if (activeListener?.moduleId == eventBusId) {
        activeListener?.subscription?.cancel();
        _state.activeExclusiveListener[eventBusHashCode]![eventType] = null;
        _activateNextExclusiveListener(eventType, eventBusHashCode);
      }
    }

    final remainingQueue = _state.exclusiveQueue[eventBusHashCode]?[eventType];
    if (remainingQueue == null || remainingQueue.isEmpty) {
      _state.exclusiveStreams[eventBusHashCode]?.remove(eventType);
      _state.exclusiveQueue[eventBusHashCode]?.remove(eventType);
      _state.activeExclusiveListener[eventBusHashCode]?.remove(eventType);
    }
  }
}
