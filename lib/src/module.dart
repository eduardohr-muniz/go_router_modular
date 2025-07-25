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

  List<RouteBase> configureRoutes({String modulePath = '', bool topLevel = false}) {
    List<RouteBase> result = [];
    RouteManager.instance.registerAppModule(this);

    result.addAll(_createChildRoutes(topLevel: topLevel));
    result.addAll(_createModuleRoutes(modulePath: modulePath, topLevel: topLevel));
    result.addAll(_createShellRoutes(topLevel, modulePath));

    return result;
  }

  Set<Module> didChangeGoingReference = {};

  void _onDidChange(Module module) {
    didChangeGoingReference.add(module);
    Future.microtask(() {
      didChangeGoingReference.remove(module);
    });
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

  GoRoute _createModule({required ModuleRoute module, required String modulePath, required bool topLevel}) {
    final childRoute = module.module.routes.whereType<ChildRoute>().where((route) => adjustRoute(route.path) == '/').firstOrNull;
    final isShell = module.module.routes.whereType<ShellModularRoute>().isNotEmpty;
    if (!isShell) {
      assert(childRoute != null, 'Module ${module.module.runtimeType} must HAVE a ChildRoute with path "/" because it serves as the parent route for the module');
    }

    // Para módulos shell, não precisa de um builder específico, apenas as rotas
    if (isShell) {
      assert(childRoute == null, 'Shell module ${module.module.runtimeType} cannot have a ChildRoute with path "/" - Shell modules only serve as wrappers for other routes');
      return GoRoute(
        path: _normalizePath(path: module.path, topLevel: topLevel),
        name: module.name,
        routes: module.module.configureRoutes(modulePath: module.path, topLevel: false),
        redirect: (context, state) => _buildRedirectAndInjectBinds(context, state, module: module.module, modulePath: module.path, redirect: null, topLevel: topLevel),
      );
    }

    return GoRoute(
      path: _normalizePath(path: module.path + (childRoute?.path ?? ""), topLevel: topLevel),
      name: childRoute?.name ?? module.name,
      builder: (context, state) => ParentWidgetObserver(
        // initState: (module) async {},
        onDispose: (module) => _disposeModule(module),
        didChangeDependencies: (module) => _onDidChange(module),
        module: module.module,
        child: childRoute!.child(context, state),
      ),
      routes: module.module.configureRoutes(modulePath: module.path, topLevel: false),
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

      await _registerModule(module);
      completer.complete();
    } else {
      try {
        ModularLoader.show();
        await _registerModule(module);
      } catch (e) {
        // Se for GoRouterModularException, propaga para o usuário
        if (e is GoRouterModularException) {
          rethrow;
        }
        // Para outros erros, continua normalmente
      } finally {
        ModularLoader.hide();
      }
    }

    if (context.mounted) return redirect?.call(context, state);
    return null;
  }

  List<GoRoute> _createModuleRoutes({required String modulePath, required bool topLevel}) {
    return routes.whereType<ModuleRoute>().map((module) {
      return _createModule(module: module, modulePath: modulePath, topLevel: topLevel);
    }).toList();
  }

  List<RouteBase> _createShellRoutes(bool topLevel, String modulePath) {
    return routes.whereType<ShellModularRoute>().map((shellRoute) {
      return ShellRoute(
        builder: (context, state, child) => shellRoute.builder!(
          context,
          state,
          ParentWidgetObserver(
            // initState: (module) async => await _registerModule(module),
            onDispose: (module) => _disposeModule(module),
            didChangeDependencies: (module) => _onDidChange(module),
            module: this,
            child: child,
          ),
        ),
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
    return _parsePath(path);
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

  Future<void> _registerModule(Module module) async {
    await RouteManager.instance.registerBindsModule(module);
  }

  void _disposeModule(Module module) {
    if (didChangeGoingReference.contains(module)) return;
    RouteManager.instance.unregisterModule(module);
  }

  String _parsePath(String path) {
    if (!path.endsWith('/')) {
      path = '$path/';
    }
    path = path.replaceAll(RegExp(r'/+'), '/');
    if (path == '/') return path;
    return path.substring(0, path.length - 1);
  }
}
