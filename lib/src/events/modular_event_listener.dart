import 'package:flutter/material.dart';
import 'package:go_router_modular/src/events/event_module.dart';

/// Abstract listener for events attached to an [EventModule].
///
/// Extend and override [listen] to register handlers with [on].
/// Add instances in [EventModule.eventImports].
abstract class ModularEventListener {
  ModularEventListener(this._module);

  final EventModule _module;

  void listen();

  void on<T>(
    void Function(T event, BuildContext? context) callback, {
    bool? autoDispose,
    @Deprecated('Use exclusive parameter instead.') bool? broadcast,
    bool exclusive = false,
  }) {
    _module.on<T>(callback, autoDispose: autoDispose, broadcast: broadcast, exclusive: exclusive);
  }
}
