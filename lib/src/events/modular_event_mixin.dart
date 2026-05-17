import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router_modular/src/events/modular_event.dart';
import 'package:go_router_modular/src/internal/setup.dart';
import 'package:event_bus/event_bus.dart';

bool get _debugLog => SetupModular.instance.debugLogEventBus;

/// Mixin para `State<T>` que expõe o método [on] para registrar
/// listeners de eventos e cancela automaticamente todas as subscriptions
/// no [dispose] do widget.
///
/// Uso:
/// ```dart
/// class _MyWidgetState extends State<MyWidget>
///     with StatefulEventListenerMixin {
///
///   @override
///   void initState() {
///     super.initState();
///     on<MyEvent>((event, context) {
///       setState(() { /* ... */ });
///     });
///   }
/// }
/// ```
mixin ModularEventMixin<T extends StatefulWidget> on State<T> {
  final Map<Type, StreamSubscription<dynamic>> _subscriptions = {};

  /// Registra um listener para o tipo de evento [E].
  ///
  /// - Se [eventBus] for omitido, usa o bus global do módulo.
  /// - Se [exclusive] for `true`, o stream é convertido para broadcast,
  ///   permitindo múltiplos ouvintes simultâneos no mesmo bus para o mesmo tipo.
  /// - Chamar [on] com o mesmo tipo [E] cancela o listener anterior.
  /// - Todas as subscriptions são canceladas automaticamente no [dispose].
  void on<E>(
    void Function(E event, BuildContext? context) callback, {
    EventBus? eventBus,
    bool exclusive = false,
  }) {
    final bus = eventBus ?? defaultModularEventBus;

    _subscriptions[E]?.cancel();

    final stream = exclusive ? bus.on<E>().asBroadcastStream() : bus.on<E>();

    _subscriptions[E] = stream.listen((event) {
      if (_debugLog) {
        log('📨 Event received: ${event.runtimeType}', name: 'EVENT GO_ROUTER_MODULAR');
      }
      callback(event, mounted ? context : null);
    });
  }

  @override
  void dispose() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }
}
