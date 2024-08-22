import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/src/bind.dart';
import 'package:go_router_modular/src/go_router_modular_configure.dart';
import 'package:go_router_modular/src/injector.dart';
import 'package:go_router_modular/src/route_manager.dart';
import 'package:go_router_modular/src/routes/child_route.dart';
import 'package:go_router_modular/src/routes/i_modular_route.dart';
import 'package:go_router_modular/src/routes/module_route.dart';
import 'package:go_router_modular/src/routes/shell_modular_route.dart';
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
    result.addAll(_createShellRoutes(injector, topLevel));

    return result;
  }

  GoRoute _createChild(Injector injector, ChildRoute childRoute, bool topLevel) {
    return GoRoute(
      path: _normalizePath(childRoute.path, topLevel),
      name: childRoute.name,
      builder: (context, state) => _buildRouteChild(context, state, childRoute, injector),
      pageBuilder: childRoute.pageBuilder != null
          ? (context, state) => childRoute.pageBuilder!(context, state)
          : (context, state) => _buildCustomTransitionPage(context, state, childRoute, injector),
      parentNavigatorKey: childRoute.parentNavigatorKey,
      redirect: childRoute.redirect,
      onExit: (context, state) => _handleRouteExit(context, state, childRoute, this),
    );
  }

  List<GoRoute> _createChildRoutes(Injector injector, bool topLevel) {
    return routes.whereType<ChildRoute>().where((route) => adjustRoute(route.path) != '/').map((route) {
      return _createChild(injector, route, topLevel);
    }).toList();
  }

  GoRoute _createModule(Injector injector, ModuleRoute module, String modulePath, bool topLevel) {
    final childRoute = module.module.routes.whereType<ChildRoute>().where((route) => adjustRoute(route.path) == '/').firstOrNull;

    return GoRoute(
      path: _normalizePath(module.path + (childRoute?.path ?? ""), topLevel),
      name: childRoute?.name ?? module.name,
      builder: (context, state) => _buildModuleChild(context, state, module, childRoute, injector),
      routes: module.module.configureRoutes(injector, modulePath: module.path, topLevel: false),
      parentNavigatorKey: childRoute?.parentNavigatorKey,
      redirect: childRoute?.redirect,
      onExit: (context, state) => childRoute == null ? Future.value(true) : _handleRouteExit(context, state, childRoute, module.module),
    );
  }

  List<GoRoute> _createModuleRoutes(Injector injector, String modulePath, bool topLevel) {
    return routes.whereType<ModuleRoute>().map((module) {
      return _createModule(injector, module, modulePath, topLevel);
    }).toList();
  }

  List<RouteBase> _createShellRoutes(Injector injector, bool topLevel) {
    return routes.whereType<ShellModularRoute>().map((shellRoute) {
      // if (shellRoute.routes.whereType<ChildRoute>().where((element) => element.path == '/').isNotEmpty) {
      //   throw Exception('ShellModularRoute cannot contain ChildRoute with path "/"');
      // }
      return ShellRoute(
        builder: (context, state, child) => shellRoute.builder!(context, state, child),
        pageBuilder: shellRoute.pageBuilder != null ? (context, state, child) => shellRoute.pageBuilder!(context, state, child) : null,
        redirect: shellRoute.redirect,
        navigatorKey: shellRoute.navigatorKey,
        observers: shellRoute.observers,
        parentNavigatorKey: shellRoute.parentNavigatorKey,
        restorationScopeId: shellRoute.restorationScopeId,
        routes: shellRoute.routes
            .map((route) {
              if (route is ChildRoute) {
                return _createChild(injector, route, topLevel);
              } else if (route is ModuleRoute) {
                return _createModule(injector, route, route.path, topLevel);
              }
              return null;
            })
            .whereType<RouteBase>()
            .toList(),
      );
    }).toList();
  }

  String adjustRoute(String route) {
    if (route == "/") {
      return "/";
    } else if (route.startsWith("/:")) {
      return "/";
    } else {
      return route;
    }
  }

  String _normalizePath(String path, bool topLevel) {
    if (path.startsWith("/") && !topLevel && !path.startsWith("/:")) {
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
        pageTransition: route.pageTransition ?? Modular.getDefaultPageTransition,
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
      try {
        if (exit) _unregister(state.uri.toString(), module);
        return exit;
      } catch (_) {
        return false;
      }
    });
  }

  void _register(String path, [Module? module]) {
    RouteManager().registerBindsIfNeeded(module ?? this);
    RouteManager().registerRoute(path, module ?? this);
  }

  void _unregister(String path, [Module? module]) {
    Future.delayed(
      const Duration(milliseconds: 500),
      () {
        RouteManager().unregisterRoute(path, module ?? this);
      },
    );
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
