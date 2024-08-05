import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

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

  List<GoRoute> _createChildRoutes(Injector injector, bool topLevel) {
    return routes.whereType<ChildRoute>().where((route) => adjustRoute(route.path) != '/').map((route) {
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
    }).toList();
  }

  List<RouteBase> _createShellRoutes(Injector injector, bool topLevel) {
    return routes.whereType<ShellModularRoute>().map((shellRoute) {
      if (shellRoute.routes.whereType<ChildRoute>().where((element) => element.path == '/').isNotEmpty) {
        throw Exception('ShellModularRoute cannot contain ChildRoute with path "/"');
      }
      return ShellRoute(
        builder: (context, state, child) => shellRoute.builder!(context, state, child),
        pageBuilder: shellRoute.pageBuilder != null ? (context, state, child) => shellRoute.pageBuilder!(context, state, child) : null,
        routes: shellRoute.routes
            .map((route) {
              if (route is ChildRoute) {
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
              } else if (route is ModuleRoute) {
                return GoRoute(
                  path: _normalizePath(route.path, topLevel),
                  name: route.name,
                  builder: (context, state) => _buildModuleChild(context, state, route, null, injector),
                  routes: route.module.configureRoutes(injector, modulePath: route.path, topLevel: false),
                );
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
