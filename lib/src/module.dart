import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/utils/internal_logs.dart';
import 'package:go_router_modular/src/utils/parent_widget_observer.dart';

abstract class Module {
  FutureOr<List<Module>> imports() => [];
  FutureOr<List<Bind<Object>>> binds() => [];
  List<ModularRoute> get routes => const [];

  void initState(Injector i) {}
  void dispose() {}

  Future<List<RouteBase>> configureRoutes({String modulePath = '', bool topLevel = false}) async {
    List<RouteBase> result = [];
    await RouteManager().registerBindsAppModule(this);
    result.addAll(_createChildRoutes(topLevel: topLevel));
    result.addAll(await _createModuleRoutes(modulePath: modulePath, topLevel: topLevel));
    result.addAll(_createShellRoutes(topLevel, modulePath));

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
    );
  }

  List<GoRoute> _createChildRoutes({required bool topLevel}) {
    return routes.whereType<ChildRoute>().where((route) => adjustRoute(route.path) != '/').map((route) {
      return _createChild(childRoute: route, topLevel: topLevel);
    }).toList();
  }

  Future<GoRoute> _createModule({required ModuleRoute module, required String modulePath, required bool topLevel}) async {
    final childRoute = module.module.routes.whereType<ChildRoute>().where((route) => adjustRoute(route.path) == '/').firstOrNull;
    final isShell = module.module.routes.whereType<ShellModularRoute>().isNotEmpty;
    if (!isShell) {
      assert(childRoute != null, 'Module ${module.module.runtimeType} must have a ChildRoute with path "/" because it serves as the parent route for the module');
    }

    return GoRoute(
      path: _normalizePath(path: module.path + (childRoute?.path ?? ""), topLevel: topLevel),
      name: childRoute?.name ?? module.name,
      builder: (context, state) => ParentWidgetObserver(onDispose: () => _handleRouteExit(context, module: module.module), child: _buildModuleChild(context, state: state, module: module, route: childRoute)),
      routes: await module.module.configureRoutes(modulePath: module.path, topLevel: false),
      parentNavigatorKey: childRoute?.parentNavigatorKey,
      redirect: (context, state) => _buildRedirectAndInjectBinds(context, state, module: module.module, modulePath: module.path, redirect: childRoute?.redirect, topLevel: topLevel),
    );
  }

  FutureOr<String?> _buildRedirectAndInjectBinds(
    BuildContext context,
    GoRouterState state, {
    required Module module,
    required String modulePath,
    required bool topLevel,
    FutureOr<String?> Function(BuildContext, GoRouterState)? redirect,
  }) async {
    if (RouteWithCompleterService.hasRouteCompleter()) {
      final completer = RouteWithCompleterService.getLastCompleteRoute();

      await _register(module: module);
      completer.complete();
    } else {
      try {
        ModularLoader.show();
        await _register(module: module);
      } finally {
        ModularLoader.hide();
      }
    }

    if (context.mounted) return redirect?.call(context, state);
    return null;
  }

  Future<List<GoRoute>> _createModuleRoutes({required String modulePath, required bool topLevel}) async {
    final moduleRoutes = routes.whereType<ModuleRoute>();
    return await Future.wait(moduleRoutes.map((module) async {
      return _createModule(module: module, modulePath: modulePath, topLevel: topLevel);
    }).toList());
  }

  List<RouteBase> _createShellRoutes(bool topLevel, String modulePath) {
    return routes.whereType<ShellModularRoute>().map((shellRoute) {
      return ShellRoute(
        builder: (context, state, child) => shellRoute.builder!(context, state, ParentWidgetObserver(onDispose: () => _handleRouteExit(context, module: this), child: child)),
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
    // Executa registro com prioridade (fire and forget - não bloqueia UI)
    iLog('📱 BUILD ChildRoute: ${state.path} - Módulo: $runtimeType', name: "BUILD_DEBUG");
    iLog('📍 CHAMANDO _register de _buildRouteChild', name: "BUILD_DEBUG");

    return route.child(context, state);
  }

  Page<void> _buildCustomTransitionPage(BuildContext context, {required GoRouterState state, required ChildRoute route}) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: route.child(context, state),
      transitionsBuilder: Transition.builder(
        configRouteManager: () {},
        pageTransition: route.pageTransition ?? Modular.getDefaultPageTransition,
      ),
    );
  }

  Widget _buildModuleChild(BuildContext context, {required GoRouterState state, required ModuleRoute module, ChildRoute? route}) {
    // Executa registro com prioridade (fire and forget - não bloqueia UI)
    iLog('📱 BUILD ModuleChild: ${state.path} - Módulo: ${module.module.runtimeType}', name: "BUILD_DEBUG");
    iLog('📍 CHAMANDO _register de _buildModuleChild', name: "BUILD_DEBUG");
    return route?.child(context, state) ?? Container();
  }

  void _handleRouteExit(BuildContext context, {required Module module}) {
    _unregister(module: module);
  }

  Future<void> _register({Module? module}) async {
    final targetModule = module ?? this;

    await RouteManager().registerBindsModule(targetModule);
  }

  void _unregister({Module? module}) {
    final targetModule = module ?? this;

    RouteManager().unregisterModule(targetModule);
  }

  // Limpa entradas do cache de transições para um módulo específico

  // Método público para limpeza de cache chamado pelo RouteManager

  String _buildPath(String path) {
    if (!path.endsWith('/')) {
      path = '$path/';
    }
    path = path.replaceAll(RegExp(r'/+'), '/');
    if (path == '/') return path;
    return path.substring(0, path.length - 1);
  }
}
