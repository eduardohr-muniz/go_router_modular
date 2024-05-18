import 'dart:async';
import 'package:go_router_modular/go_router_modular.dart';

abstract class Module {
  List<Module> get imports => const [];
  List<Bind<Object>> binds = const [];
  List<ChildRoute> get routes => const [];
  List<ModuleRoute> get moduleRoutes => const [];

  List<GoRoute> configureRoutes(Injector injector, {String modulePath = ''}) {
    List<GoRoute> result = [];

    result.addAll(routes.map((route) {
      return GoRoute(
        path: _buildPath(modulePath + route.path), // Remover / do final
        name: route.name,
        builder: (context, state) {
          RouteManager().registerBindsIfNeeded(this);
          RouteManager().registerRoute(state.uri.toString(), this);
          return route.builder(context, state, injector);
        },
        pageBuilder: route.pageBuilder != null ? (context, state) => route.pageBuilder!(context, state) : null,
        parentNavigatorKey: route.parentNavigatorKey,
        redirect: route.redirect != null ? (context, state) => route.redirect!(context, state) : null,
        onExit: route.onExit != null
            ? (context, state) {
                final completer = Completer();
                final onExit = route.onExit!(context, state);
                completer.complete(onExit);
                completer.future.then((value) {
                  if (value) {
                    RouteManager().unregisterRoute(state.uri.toString(), this);
                    RouteManager().unregisterBinds(this);
                  }
                });
                return onExit;
              }
            : (context, state) {
                RouteManager().unregisterRoute(state.uri.toString(), this);
                RouteManager().unregisterBinds(this);
                return true;
              },
        routes: route.routes,
      );
    }).toList());

    for (var module in moduleRoutes) {
      result.addAll(
        module.module.configureRoutes(injector, modulePath: _buildPath(modulePath + module.path)),
      );
    }

    return result;
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
