import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/injector.dart';
import 'package:go_router_modular/src/transition.dart';

abstract class Module {
  List<Module> get imports => const [];
  List<Bind<Object>> get binds => const [];
  List<ModularRoute> get routes => const [];

  List<RouteBase> configureRoutes(Injector injector, {String modulePath = '', bool topLevel = false}) {
    List<RouteBase> result = [];
    RouteManager().registerBindsAppModule(this);

    result.addAll(_createChildRoutes(injector, topLevel));
    result.addAll(_createModuleRoutes(injector, modulePath, topLevel));

    return result;
  }

  List<GoRoute> _createChildRoutes(Injector injector, bool topLevel) {
    return routes.whereType<ChildRoute>().where((route) => route.path != '/').map((route) {
      return GoRoute(
        path: _normalizePath(route.path, topLevel),
        name: route.name,
        builder: (context, state) => _buildRouteChild(context, state, route, injector),
        pageBuilder: route.pageBuilder != null
            ? (context, state) => route.pageBuilder!(context, state)
            : (context, state) => _buildCustomTransitionPage(context, state, route, injector),
        parentNavigatorKey: route.parentNavigatorKey,
        redirect: route.redirect,
        onExit: (context, state) => _handleRouteExit(context, state, route, this),
      );
    }).toList();
  }

  List<GoRoute> _createModuleRoutes(Injector injector, String modulePath, bool topLevel) {
    return routes.whereType<ModuleRoute>().map((module) {
      final childRoute = module.module.routes.whereType<ChildRoute>().where((route) => route.path == '/').firstOrNull;
      return GoRoute(
        path: _normalizePath(module.path, topLevel),
        name: childRoute?.name ?? module.name,
        builder: (context, state) => _buildModuleChild(context, state, module, childRoute, injector),
        routes: module.module.configureRoutes(injector, modulePath: module.path),
        parentNavigatorKey: childRoute?.parentNavigatorKey,
        redirect: childRoute?.redirect,
        onExit: (context, state) => _handleRouteExit(context, state, childRoute!, module.module),
      );
    }).toList();
  }

  String _normalizePath(String path, bool topLevel) {
    if (path.startsWith("/") && !topLevel) {
      path = path.substring(1);
    }
    return _buildPath(path);
  }

  Widget _buildRouteChild(BuildContext context, GoRouterState state, ChildRoute route, Injector injector) {
    _register(state.uri.toString());
    return route.child(context, state, injector);
  }

  Page<void> _buildCustomTransitionPage(BuildContext context, GoRouterState state, ChildRoute route, Injector injector) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: route.child(context, state, injector),
      transitionsBuilder: Transition.builder(
        configRouteManager: () {
          _register(state.uri.toString());
        },
        pageTransition: route.pageTransition,
      ),
    );
  }

  Widget _buildModuleChild(BuildContext context, GoRouterState state, ModuleRoute module, ChildRoute? route, Injector injector) {
    _register(state.uri.toString(), module.module);
    return route?.child(context, state, injector) ?? Container();
  }

  FutureOr<bool> _handleRouteExit(BuildContext context, GoRouterState state, ChildRoute route, Module module) {
    final completer = Completer<bool>();
    final onExit = route.onExit?.call(context, state) ?? Future.value(true);
    completer.complete(onExit);
    return completer.future.then((exit) {
      if (exit) _unregister(state.uri.toString(), module);
      return exit;
    });
  }

  void _register(String path, [Module? module]) {
    RouteManager().registerBindsIfNeeded(module ?? this);
    RouteManager().registerRoute(path, module ?? this);
  }

  void _unregister(String path, [Module? module]) {
    Future.delayed(const Duration(milliseconds: 500), () {
      RouteManager().unregisterRoute(path, module ?? this);
    });
  }

  String _buildPath(String path) {
    if (!path.endsWith('/')) {
      path = '$path/';
    }
    path = path.replaceAll(RegExp(r'/+'), '/');
    if (path == '/') return path;
    return path.substring(0, path.length - 1);
  }
}



// import 'dart:async';
// import 'package:go_router_modular/go_router_modular.dart';
// import 'package:go_router_modular/src/injector.dart';
// import 'package:go_router_modular/src/transition.dart';

// abstract class Module {
//   List<Module> get imports => const [];
//   List<Bind<Object>> get binds => const [];
//   List<ModularRoute> get routes => const [];

//   List<RouteBase> configureRoutes(Injector injector, {List<ModularRoute>? modularRoutes, String modulePath = '', bool topLevel = false}) {
//     if (topLevel) _register("");

//     return _configureRoutes(injector, modularRoutes: modularRoutes ?? routes, modulePath: modulePath);
//   }

//   List<RouteBase> _configureRoutes(Injector injector, {required List<ModularRoute> modularRoutes, String modulePath = '', bool topLevel = false}) {
//     List<RouteBase> result = [];

//     RouteManager().registerBindsAppModule(this);

//     result.addAll(modularRoutes.whereType<ChildRoute>().map((route) {
//       return GoRoute(
//         path: _buildPath(modulePath + route.path),
//         name: route.name,
//         builder: (context, state) {
//           if (!topLevel) _register(state.uri.toString());
//           return route.child(context, state, injector);
//         },
//         pageBuilder: route.pageBuilder != null
//             ? (context, state) => route.pageBuilder!(context, state)
//             : (context, state) => CustomTransitionPage(
//                   key: state.pageKey,
//                   child: route.child(context, state, injector),
//                   transitionsBuilder: Transition.builder(
//                       configRouteManager: () {
//                         if (!topLevel) _register(state.uri.toString());
//                       },
//                       pageTransition: route.pageTransition),
//                 ),
//         parentNavigatorKey: route.parentNavigatorKey,
//         redirect: route.redirect != null ? (context, state) => route.redirect!(context, state) : null,
//         onExit: route.onExit != null
//             ? (context, state) {
//                 final completer = Completer();
//                 final onExit = route.onExit!(context, state);
//                 completer.complete(onExit);
//                 completer.future.then((value) {
//                   if (value) _unregister(state.uri.toString());
//                 });
//                 return onExit;
//               }
//             : (context, state) {
//                 _unregister(state.uri.toString());
//                 return true;
//               },
//       );
//     }).toList());

//     for (var module in modularRoutes.whereType<ModuleRoute>()) {
//       result.addAll(
//         module.module.configureRoutes(injector, modularRoutes: module.module.routes, modulePath: _buildPath(modulePath + module.path)),
//       );
//     }

//     for (var shell in modularRoutes.whereType<ShellModularRoute>()) {
//       result.add(ShellRoute(
//         routes: configureRoutes(injector, modularRoutes: shell.routes, modulePath: _buildPath(modulePath)),
//         builder: (context, state, child) => shell.builder!(context, state, child),
//         navigatorKey: shell.navigatorKey,
//         observers: shell.observers,
//         redirect: shell.redirect,
//         pageBuilder: shell.pageBuilder,
//         parentNavigatorKey: shell.parentNavigatorKey,
//         restorationScopeId: shell.restorationScopeId,
//       ));
//     }

//     return result;
//   }

//   void _register(String path) {
//     RouteManager().registerBindsIfNeeded(this);
//     RouteManager().registerRoute(path, this);
//   }

//   void _unregister(String path) {
//     Future.delayed(const Duration(milliseconds: 500), () {
//       RouteManager().unregisterRoute(path, this);
//     });
//     // RouteManager().unregisterBinds(this);
//   }

//   String _buildPath(String path) {
//     if (!path.startsWith('/')) {
//       path = '/$path';
//     }
//     if (!path.endsWith('/')) {
//       path = '$path/';
//     }
//     path = path.replaceAll(RegExp(r'/+'), '/');
//     if (path == '/') return path;
//     return path.substring(0, path.length - 1);
//   }
// }
