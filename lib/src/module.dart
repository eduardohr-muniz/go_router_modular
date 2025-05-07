import 'dart:async';
import 'dart:developer';
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

  List<RouteBase> configureRoutes(
      {String modulePath = '', bool topLevel = false}) {
    RouteManager().registerBindsAppModule(this);

    return [
      ..._createChildRoutes(topLevel: topLevel),
      ..._createModuleRoutes(modulePath: modulePath, topLevel: topLevel),
      ..._createShellRoutes(topLevel),
    ];
  }

  List<GoRoute> _createChildRoutes({required bool topLevel}) {
    return routes
        .whereType<ChildRoute>()
        .where((route) => adjustRoute(route.path) != '/')
        .map((route) => _createChild(childRoute: route, topLevel: topLevel))
        .toList();
  }

  GoRoute _createChild(
      {required ChildRoute childRoute, required bool topLevel}) {
    return GoRoute(
      path: _normalizePath(path: childRoute.path, topLevel: topLevel),
      name: childRoute.name,
      builder: (context, state) =>
          _buildRouteChild(context, state: state, route: childRoute),
      pageBuilder: _getPageBuilder(childRoute),
      parentNavigatorKey: childRoute.parentNavigatorKey,
      redirect: _createRedirect(childRoute),
      onExit: (context, state) => _handleRouteExit(context,
          state: state, route: childRoute, module: this),
    );
  }

  Page<dynamic> Function(BuildContext, GoRouterState)? _getPageBuilder(
      ChildRoute childRoute) {
    if (childRoute.pageBuilder != null) {
      return childRoute.pageBuilder!;
    }
    return (context, state) => _buildCustomTransitionPage(
          context,
          state: state,
          route: childRoute,
        );
  }

  FutureOr<String?> Function(BuildContext, GoRouterState) _createRedirect(
      ChildRoute childRoute) {
    return (context, state) async {
      final path = state.uri.toString();
      await _register(path: path);

      if (childRoute.redirect != null) {
        final redirectPath = await childRoute.redirect!(context, state);
        if (redirectPath != null) {
          return redirectPath;
        }
      }
      return null;
    };
  }

  List<GoRoute> _createModuleRoutes(
      {required String modulePath, required bool topLevel}) {
    return routes
        .whereType<ModuleRoute>()
        .map((module) => _createModule(
            module: module, modulePath: modulePath, topLevel: topLevel))
        .toList();
  }

  GoRoute _createModule(
      {required ModuleRoute module,
      required String modulePath,
      required bool topLevel}) {
    final childRoute = _findModuleChildRoute(module);
    final path = _normalizePath(
        path: module.path + (childRoute?.path ?? ""), topLevel: topLevel);

    return GoRoute(
      path: path,
      name: childRoute?.name ?? module.name,
      builder: (context, state) => _buildModuleChild(context,
          state: state, module: module, route: childRoute),
      routes: module.module
          .configureRoutes(modulePath: module.path, topLevel: false),
      parentNavigatorKey: childRoute?.parentNavigatorKey,
      redirect: _createModuleRedirect(module, childRoute),
      onExit: (context, state) => _handleModuleExit(context,
          state: state, route: childRoute, module: module),
    );
  }

  ChildRoute? _findModuleChildRoute(ModuleRoute module) {
    return module.module.routes
        .whereType<ChildRoute>()
        .where((route) => adjustRoute(route.path) == '/')
        .firstOrNull;
  }

  FutureOr<String?> Function(BuildContext, GoRouterState) _createModuleRedirect(
      ModuleRoute module, ChildRoute? childRoute) {
    return (context, state) async {
      final path = state.uri.toString();
      await _register(path: path, module: module.module);

      if (childRoute?.redirect != null) {
        final redirectPath = await childRoute!.redirect!(context, state);
        if (redirectPath != null) {
          return redirectPath;
        }
      }
      return null;
    };
  }

  FutureOr<bool> _handleModuleExit(
    BuildContext context, {
    required GoRouterState state,
    required ChildRoute? route,
    required ModuleRoute module,
  }) {
    if (route == null) return true;
    return _handleRouteExit(context,
        state: state, route: route, module: module.module);
  }

  List<RouteBase> _createShellRoutes(bool topLevel) {
    return routes.whereType<ShellModularRoute>().map((shellRoute) {
      return ShellRoute(
        builder: (context, state, child) =>
            shellRoute.builder!(context, state, child),
        pageBuilder: shellRoute.pageBuilder,
        redirect: _createShellRedirect(shellRoute),
        navigatorKey: shellRoute.navigatorKey,
        observers: shellRoute.observers,
        parentNavigatorKey: shellRoute.parentNavigatorKey,
        restorationScopeId: shellRoute.restorationScopeId,
        routes: _createShellChildRoutes(shellRoute, topLevel),
      );
    }).toList();
  }

  List<RouteBase> _createShellChildRoutes(
      ShellModularRoute shellRoute, bool topLevel) {
    return shellRoute.routes
        .map((routeOrModule) {
          if (routeOrModule is ChildRoute) {
            if (adjustRoute(routeOrModule.path) == '/') {
              throw Exception(
                  'ShellModularRoute does not accept routes with path "/". Use a specific path like "/home" or "/index".');
            }
            return _createChild(childRoute: routeOrModule, topLevel: topLevel);
          } else if (routeOrModule is ModuleRoute) {
            return _createModule(
              module: routeOrModule,
              modulePath: routeOrModule.path,
              topLevel: topLevel,
            );
          }
          return null;
        })
        .whereType<RouteBase>()
        .toList();
  }

  FutureOr<String?> Function(BuildContext, GoRouterState) _createShellRedirect(
      ShellModularRoute shellRoute) {
    return (context, state) async {
      if (shellRoute.redirect != null) {
        return await shellRoute.redirect!(context, state);
      }
      return null;
    };
  }

  String adjustRoute(String route) {
    if (route == "/") return "/";
    if (route.startsWith("/:")) return "/";
    return route;
  }

  String _normalizePath({required String path, required bool topLevel}) {
    if (path.startsWith("/") && !topLevel && !path.startsWith("/:")) {
      path = path.substring(1);
    }
    return _buildPath(path);
  }

  Widget _buildRouteChild(BuildContext context,
      {required GoRouterState state, required ChildRoute route}) {
    return route.child(context, state);
  }

  Page<void> _buildCustomTransitionPage(BuildContext context,
      {required GoRouterState state, required ChildRoute route}) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: route.child(context, state),
      transitionsBuilder: Transition.builder(
        configRouteManager: () {},
        pageTransition:
            route.pageTransition ?? Modular.getDefaultPageTransition,
      ),
    );
  }

  Widget _buildModuleChild(BuildContext context,
      {required GoRouterState state,
      required ModuleRoute module,
      ChildRoute? route}) {
    return route?.child(context, state) ?? Container();
  }

  FutureOr<bool> _handleRouteExit(BuildContext context,
      {required GoRouterState state,
      required ChildRoute route,
      required Module module}) {
    try {
      final onExit = route.onExit?.call(context, state) ?? Future.value(true);
      if (onExit is Future<bool>) {
        return onExit.then((exit) {
          if (exit) {
            _unregister(state.uri.toString(), module: module);
          }
          return exit;
        }).catchError((error) {
          debugPrint('Error in route exit: $error');
          return false;
        });
      } else {
        if (onExit) {
          _unregister(state.uri.toString(), module: module);
        }
        return onExit;
      }
    } catch (e) {
      debugPrint('Error in route exit: $e');
      return false;
    }
  }

  final Map<String, Module> _modules = {};
  final Map<String, DateTime> _moduleLastAccess = {};
  static const _moduleTimeout = Duration(minutes: 30);

  void _cleanupModules() {
    final now = DateTime.now();
    _moduleLastAccess.removeWhere((path, lastAccess) {
      if (now.difference(lastAccess) > _moduleTimeout) {
        _modules.remove(path);
        return true;
      }
      return false;
    });
  }

  Future<void> _register({required String path, Module? module}) async {
    _cleanupModules();

    if (module != null) {
      _modules[path] = module;
      _moduleLastAccess[path] = DateTime.now();
    }

    final currentModule = _modules[path];
    if (currentModule != null) {
      await currentModule.registerBindsIfNeeded();
    }
  }

  void _disposeModule(Module module) {
    if (Modular.debugLogDiagnostics) {
      log(
          'DISPOSED: ${module.runtimeType} BINDS: ${[
            ...module.binds.map((e) => e.instance.runtimeType.toString()),
            ...module.imports.map((e) =>
                e.binds.map((e) => e.instance.runtimeType.toString()).toList())
          ]}',
          name: "🗑️");
    }
    module.dispose();
  }

  void _unregister(String path, {Module? module}) {
    final moduleToUnregister = module ?? this;
    RouteManager().unregisterRoute(path);

    if (_modules.containsKey(path)) {
      _modules.remove(path);
      _moduleLastAccess.remove(path);

      if (moduleToUnregister != this) {
        _disposeModule(moduleToUnregister);
      }
    }
  }

  void dispose() {
    for (var entry in _modules.entries) {
      final module = entry.value;
      if (module != this) {
        _disposeModule(module);
      }
    }

    _modules.clear();
    _moduleLastAccess.clear();
  }

  String _buildPath(String path) {
    if (!path.endsWith('/')) {
      path = '$path/';
    }
    path = path.replaceAll(RegExp(r'/+'), '/');
    if (path == '/') return path;
    return path.substring(0, path.length - 1);
  }

  Future<void> registerBindsIfNeeded() async {
    await RouteManager().registerBindsIfNeeded(this);
  }
}
