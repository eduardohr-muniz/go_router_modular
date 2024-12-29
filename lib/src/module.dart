import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/src/bind.dart';
import 'package:go_router_modular/src/go_router_modular_configure.dart';
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

  List<RouteBase> configureRoutes({String modulePath = '', bool topLevel = false}) {
    List<RouteBase> result = [];
    RouteManager().registerBindsAppModule(this);

    result.addAll(_createChildRoutes(topLevel: topLevel));
    result.addAll(_createModuleRoutes(modulePath: modulePath, topLevel: topLevel));
    result.addAll(_createShellRoutes(topLevel));

    return result;
  }

  GoRoute _createChild({required ChildRoute childRoute, required bool topLevel}) {
    return GoRoute(
      path: _normalizePath(path: childRoute.path, topLevel: topLevel),
      name: childRoute.name,
      builder: (context, state) => _buildRouteChild(
        context,
        state: state,
        route: childRoute,
      ),
      pageBuilder: childRoute.pageBuilder != null
          ? (context, state) => childRoute.pageBuilder!(context, state)
          : (context, state) => _buildCustomTransitionPage(
                context,
                state: state,
                route: childRoute,
              ),
      parentNavigatorKey: childRoute.parentNavigatorKey,
      redirect: childRoute.redirect,
      onExit: (context, state) => _handleRouteExit(context, state: state, route: childRoute, module: this),
    );
  }

  List<GoRoute> _createChildRoutes({required bool topLevel}) {
    return routes.whereType<ChildRoute>().where((route) => adjustRoute(route.path) != '/').map((route) {
      return _createChild(childRoute: route, topLevel: topLevel);
    }).toList();
  }

  GoRoute _createModule({required ModuleRoute module, required String modulePath, required bool topLevel}) {
    final childRoute = module.module.routes.whereType<ChildRoute>().where((route) => adjustRoute(route.path) == '/').firstOrNull;

    return GoRoute(
      path: _normalizePath(path: module.path + (childRoute?.path ?? ""), topLevel: topLevel),
      name: childRoute?.name ?? module.name,
      builder: (context, state) => _buildModuleChild(context, state: state, module: module, route: childRoute),
      routes: module.module.configureRoutes(modulePath: module.path, topLevel: false),
      parentNavigatorKey: childRoute?.parentNavigatorKey,
      redirect: childRoute?.redirect,
      onExit: (context, state) =>
          childRoute == null ? Future.value(true) : _handleRouteExit(context, state: state, route: childRoute, module: module.module),
    );
  }

  List<GoRoute> _createModuleRoutes({required String modulePath, required bool topLevel}) {
    return routes.whereType<ModuleRoute>().map((module) {
      return _createModule(module: module, modulePath: modulePath, topLevel: topLevel);
    }).toList();
  }

  List<RouteBase> _createShellRoutes(bool topLevel) {
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
            .map((routeOrModule) {
              if (routeOrModule is ChildRoute) {
                return _createChild(childRoute: routeOrModule, topLevel: topLevel);
              } else if (routeOrModule is ModuleRoute) {
                return _createModule(module: routeOrModule, modulePath: routeOrModule.path, topLevel: topLevel);
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

  String _normalizePath({required String path, required bool topLevel}) {
    if (path.startsWith("/") && !topLevel && !path.startsWith("/:")) {
      path = path.substring(1);
    }
    return _buildPath(path);
  }

  Widget _buildRouteChild(BuildContext context, {required GoRouterState state, required ChildRoute route}) {
    _register(path: state.uri.toString());
    return route.child(context, state);
  }

  Page<void> _buildCustomTransitionPage(BuildContext context, {required GoRouterState state, required ChildRoute route}) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: route.child(context, state),
      transitionsBuilder: Transition.builder(
        configRouteManager: () {
          _register(path: state.uri.toString());
        },
        pageTransition: route.pageTransition ?? Modular.getDefaultPageTransition,
      ),
    );
  }

  Widget _buildModuleChild(BuildContext context, {required GoRouterState state, required ModuleRoute module, ChildRoute? route}) {
    _register(path: state.uri.toString(), module: module.module);
    return route?.child(context, state) ?? Container();
  }

  FutureOr<bool> _handleRouteExit(BuildContext context, {required GoRouterState state, required ChildRoute route, required Module module}) {
    final completer = Completer<bool>();
    final onExit = route.onExit?.call(context, state) ?? Future.value(true);
    completer.complete(onExit);
    return completer.future.then((exit) {
      try {
        if (exit) _unregister(state.uri.toString(), module: module);
        return exit;
      } catch (_) {
        return false;
      }
    });
  }

  void _register({required String path, Module? module}) {
    RouteManager().registerBindsIfNeeded(module ?? this);
    if (path == '/') return;
    RouteManager().registerRoute(path, module ?? this);
  }

  void _unregister(String path, {Module? module}) {
    RouteManager().unregisterRoute(path, module ?? this);
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
