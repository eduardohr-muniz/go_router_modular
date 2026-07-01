import 'dart:developer';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/src/di/injector.dart';
import 'package:go_router_modular/src/events/event_state.dart';
import 'package:go_router_modular/src/events/modular_event.dart';
import 'package:go_router_modular/src/module/module.dart';
import 'package:go_router_modular/src/routing/modular_router_runtime.dart';
import 'package:go_router_modular/src/shared/setup.dart';

bool get _debugLog => SetupModular.instance.debugLogEventBus;
bool get _autoDisposeEvents => SetupModular.instance.autoDisposeEvents;
BuildContext? get _navigatorContext => modularNavigatorKey.currentContext;

final EventState _state = EventState.instance;

/// Escopo de registro de ouvintes: identifica em qual `eventBusId` e em qual
/// barramento as assinaturas devem ser gravadas. Permite que módulos compostos
/// (registrados via `OutroEventModule().listen()`) herdem o escopo do host.
class _EventRegistrationScope {
  const _EventRegistrationScope(this.eventBusId, this.eventBus);

  final int eventBusId;
  final EventBus eventBus;
}

/// Módulo abstrato com suporte a eventos.
///
/// Estende [Module] e incorpora diretamente a lógica de escuta: sobrescreva
/// [listen] para registrar handlers com [on]. Para compor os ouvintes de outro
/// módulo, chame `OutroEventModule().listen()` de forma síncrona dentro do
/// próprio [listen] — os ouvintes do filho herdam o ciclo de vida deste host.
abstract class EventModule extends Module {
  EventModule({EventBus? eventBus}) {
    internalEventBus = eventBus ?? defaultModularEventBus;
  }

  late final EventBus internalEventBus;

  int get eventBusId => internalEventBus.hashCode + hashCode;

  /// Escopo de host ativo durante a execução síncrona de [listen]. Quando um
  /// módulo composto chama [on], as assinaturas são gravadas neste escopo.
  static _EventRegistrationScope? _activeHostScope;

  _EventRegistrationScope get _ownScope => _EventRegistrationScope(eventBusId, internalEventBus);

  _EventRegistrationScope get _registrationScope => _activeHostScope ?? _ownScope;

  /// Hook de escuta do módulo. Implementação padrão vazia.
  void listen() {}

  /// Hook executado logo após [listen] durante a inicialização.
  void onAfterListen() {}

  /// Registra um ouvinte tipado para o evento [T].
  void on<T>(
    void Function(T event, BuildContext? context) callback, {
    bool? autoDispose,
    @Deprecated('Use exclusive parameter instead.') bool? broadcast,
    bool exclusive = false,
  }) {
    exclusive = broadcast ?? exclusive;

    final scope = _registrationScope;
    final scopeEventBusId = scope.eventBusId;
    final eventBus = scope.eventBus;
    final eventBusHashCode = eventBus.hashCode;

    _state.subscriptions[scopeEventBusId] ??= {};
    _state.disposeSubscriptions[scopeEventBusId] ??= {};

    _state.subscriptions[scopeEventBusId]?[T]?.cancel();

    _state.exclusiveStreams[eventBusHashCode] ??= {};
    _state.exclusiveQueue[eventBusHashCode] ??= {};
    _state.activeExclusiveListener[eventBusHashCode] ??= {};

    if (exclusive) {
      _registerExclusiveListener<T>(callback, eventBusHashCode, scopeEventBusId, eventBus);
    } else {
      _registerRegularListener<T>(callback, eventBusHashCode, scopeEventBusId, eventBus);
    }

    _state.disposeSubscriptions[scopeEventBusId]![T] = autoDispose ?? _autoDisposeEvents;
  }

  void _registerExclusiveListener<T>(
    void Function(T event, BuildContext? context) callback,
    int eventBusHashCode,
    int scopeEventBusId,
    EventBus eventBus,
  ) {
    if (_state.exclusiveStreams[eventBusHashCode]![T] == null) {
      _state.exclusiveStreams[eventBusHashCode]![T] = eventBus.on<T>().asBroadcastStream();
    }

    _state.exclusiveQueue[eventBusHashCode]![T] ??= [];

    final exclusiveListener = ExclusiveListener(
      moduleId: scopeEventBusId,
      callback: callback,
      getContext: () => _navigatorContext,
    );

    _state.exclusiveQueue[eventBusHashCode]![T]!.removeWhere((listener) => listener.moduleId == scopeEventBusId);
    _state.exclusiveQueue[eventBusHashCode]![T]!.add(exclusiveListener);

    final currentActive = _state.activeExclusiveListener[eventBusHashCode]![T];
    if (currentActive?.moduleId == scopeEventBusId) {
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
    int scopeEventBusId,
    EventBus eventBus,
  ) {
    if (_state.exclusiveStreams[eventBusHashCode]?[T] != null) return;

    _state.subscriptions[scopeEventBusId]![T] = eventBus.on<T>().listen((event) {
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

    nextListener.subscription = _state.exclusiveStreams[eventBusHashCode]![eventType]!.listen((event) {
      if (_debugLog) log('📨 Event received: ${event.runtimeType}', name: 'EVENT GO_ROUTER_MODULAR');
      return nextListener.callback(event, nextListener.getContext());
    });

    _state.activeExclusiveListener[eventBusHashCode]![eventType] = nextListener;

    _state.subscriptions[nextListener.moduleId] ??= {};
    _state.subscriptions[nextListener.moduleId]![eventType] = nextListener.subscription!;
  }

  @override
  void initState(InjectorReader i) {
    final previousScope = _activeHostScope;
    _activeHostScope ??= _ownScope;
    try {
      listen();
      onAfterListen();
    } finally {
      _activeHostScope = previousScope;
    }
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
