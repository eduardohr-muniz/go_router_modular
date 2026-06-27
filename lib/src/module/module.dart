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
  Set<Module> didChangeGoingReference = {};

  /// Called by RouteBuilder when didChangeDependencies fires.
  /// @internal - used by RouteBuilder for lifecycle management.
  void onDidChangeGoingReference(Module module) {
    didChangeGoingReference.add(module);
    Future.microtask(() {
      didChangeGoingReference.remove(module);
    });
  }
}
