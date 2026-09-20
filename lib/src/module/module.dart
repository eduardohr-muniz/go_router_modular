import 'dart:async';

import 'package:go_router_modular/src/di/injector.dart';
import 'package:go_router_modular/src/routing/i_modular_route.dart';

typedef FutureBinds = FutureOr<void>;
typedef FutureModules = FutureOr<List<Module>>;

abstract class Module {
  FutureModules imports() => [];
  FutureBinds binds(Injector i) {}
  List<ModularRoute> get routes => const [];
  void initState(InjectorReader i) {}
  void dispose() {}

  /// Tracks modules currently transitioning to prevent premature disposal.
  @Deprecated('No longer consulted: module disposal is protected by reference counting. Will be removed in v6.0.0.')
  Set<Module> didChangeGoingReference = {};

  /// Called by RouteBuilder when didChangeDependencies fires.
  /// @internal - used by RouteBuilder for lifecycle management.
  @Deprecated('No longer called by the router: module disposal is protected by reference counting. Will be removed in v6.0.0.')
  void onDidChangeGoingReference(Module module) {
    didChangeGoingReference.add(module);
    Future.microtask(() {
      didChangeGoingReference.remove(module);
    });
  }
}
