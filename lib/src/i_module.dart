import 'dart:async';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/injector.dart';
import 'package:go_router_modular/src/transition.dart';

abstract class Module {
  List<Module> get imports => const [];
  List<Bind<Object>> get binds => const [];
  List<ModularRoute> get routes => const [];

  List<GoRoute> configureRoutes(Injector injector, {String modulePath = ''}) {
    List<GoRoute> result = [];
    RouteManager().registerBindsAppModule(this);

    result.addAll(routes.whereType<ChildRoute>().map((route) {
      return GoRoute(
        path: _buildPath(modulePath + route.path),
        name: route.name,
        builder: (context, state) {
          _register(state.uri.toString());
          return route.child(context, state, injector);
        },
        pageBuilder: route.pageBuilder != null
            ? (context, state) => route.pageBuilder!(context, state)
            : (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: route.child(context, state, injector),
                  transitionsBuilder: Transition.builder(
                      configRouteManager: () {
                        _register(state.uri.toString());
                      },
                      pageTransition: route.pageTransition),
                ),
        parentNavigatorKey: route.parentNavigatorKey,
        redirect: route.redirect != null ? (context, state) => route.redirect!(context, state) : null,
        onExit: route.onExit != null
            ? (context, state) {
                final completer = Completer();
                final onExit = route.onExit!(context, state);
                completer.complete(onExit);
                completer.future.then((value) {
                  if (value) _unregister(state.uri.toString());
                });
                return onExit;
              }
            : (context, state) {
                _unregister(state.uri.toString());
                return true;
              },
      );
    }).toList());

    for (var module in routes.whereType<ModuleRoute>()) {
      result.addAll(
        module.module.configureRoutes(injector, modulePath: _buildPath(modulePath + module.path)),
      );
    }

    return result;
  }

  void _register(String path) {
    RouteManager().registerBindsIfNeeded(this);
    RouteManager().registerRoute(path, this);
  }

  void _unregister(String path) {
    RouteManager().unregisterRoute(path, this);
    RouteManager().unregisterBinds(this);
  }

  String _buildPath(String path) {
    if (!path.startsWith('/')) {
      path = '/$path';
    }
    if (!path.endsWith('/')) {
      path = '$path/';
    }
    path = path.replaceAll(RegExp(r'/+'), '/');
    if (path == '/') return path;
    return path.substring(0, path.length - 1);
  }
}
