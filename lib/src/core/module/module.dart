import 'dart:async';

import 'package:go_router/go_router.dart';

import '../../di/injector.dart';
import '../../routing/i_modular_route.dart';
import '../../routing/route_builder.dart';
import '../manager/injection_manager.dart';

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

  List<RouteBase> configureRoutes({String modulePath = '', bool topLevel = false}) {
    InjectionManager.instance.registerAppModule(this);
    return ModularRouteBuilder(this).buildRoutes(modulePath: modulePath, topLevel: topLevel);
  }
}
