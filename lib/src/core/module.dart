import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/internal/asserts/module_assert.dart';
import 'package:go_router_modular/src/widgets/parent_widget_observer.dart';

typedef FutureModules = FutureOr<List<Module>>;
typedef FutureBinds = FutureOr<void>;

abstract class Module {
  FutureModules imports() => const [];

  /// Seguindo o padrão do flutter_modular: recebe o injector e registra os binds diretamente
  /// Pode retornar um Future para injeções assíncronas
  FutureBinds binds(Injector i) {}

  /// DEPRECATED: Use binds(Injector i) em vez disso
  @Deprecated('Use binds(Injector i) para seguir o padrão do flutter_modular')
  FutureOr<List<Bind<Object>>> legacyBinds() => [];
  List<ModularRoute> get routes => const [];

  void initState(Injector i) {}
  void dispose() {}

  List<RouteBase> configureRoutes({String modulePath = '', bool topLevel = false}) {
    List<RouteBase> result = [];
    // ✅ AppModule is registered in Modular.configure() BEFORE creating routes
    // ✅ Other modules are registered in _buildRedirectAndInjectBinds() during navigation
    // DO NOT register modules here!

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
          : (childRoute.transition != null || Modular.getDefaultTransition != null)
              ? (context, state) => _buildCustomTransitionPage(
                    context,
                    state: state,
                    route: childRoute,
                  )
              : null,
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
      assert(childRoute != null, ModuleAssert.childRouteAssert(module.module.runtimeType.toString()));
    }

    // Para módulos shell, não precisa de um builder específico, apenas as rotas
    if (isShell) {
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
      builder: childRoute?.pageBuilder != null
          ? null
          : (context, state) => ParentWidgetObserver(
                onDispose: (module) => _disposeModule(module),
                didChangeDependencies: (module) => _onDidChange(module),
                module: module.module,
                child: childRoute!.child(context, state),
              ),
      pageBuilder: childRoute?.pageBuilder != null
          ? (context, state) => childRoute!.pageBuilder!(context, state)
          : (childRoute?.transition != null || Modular.getDefaultTransition != null)
              ? (context, state) => _buildCustomTransitionPageForModule(
                    context,
                    state: state,
                    route: childRoute!,
                    module: module.module,
                  )
              : null,
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
    final shouldShowLoader = !RouteWithCompleterService.hasRouteCompleter();

    try {
      final completer = RouteWithCompleterService.getLastCompleteRoute();
      if (shouldShowLoader) ModularLoader.show();
      await _registerModule(module);
      completer.complete();
    } catch (e) {
      if (e is GoRouterModularException) {
        log('${e.message}', name: 'GO_ROUTER_MODULAR');
        rethrow;
      }
    } finally {
      if (shouldShowLoader) ModularLoader.hide();
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
      final existsChildRouteIncorrect = shellRoute.routes.whereType<ChildRoute>().where((route) => adjustRoute(route.path) == '/').isNotEmpty;
      assert(!existsChildRouteIncorrect, ModuleAssert.shellRouteAssert(runtimeType.toString()));

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

    return route.child(context, state);
  }

  Page<void> _buildCustomTransitionPage(BuildContext context, {required GoRouterState state, required ChildRoute route}) {
    // Usar GoTransition do go_transitions
    final transition = route.transition ?? Modular.getDefaultTransition;
    final duration = route.duration ?? Modular.getDefaultDuration;

    // Configure default duration se fornecida
    if (duration != const Duration(milliseconds: 300)) {
      GoTransition.defaultDuration = duration;
    }

    if (transition != null) {
      final pageBuilder = transition.build(
        builder: (context, state) => ParentWidgetObserver(
          onDispose: (module) => _disposeModule(module),
          didChangeDependencies: (module) => _onDidChange(module),
          module: this,
          child: route.child(context, state),
        ),
      );
      return pageBuilder(context, state);
    }

    // Fallback para página sem transição
    return MaterialPage(
      key: state.pageKey,
      child: ParentWidgetObserver(
        onDispose: (module) => _disposeModule(module),
        didChangeDependencies: (module) => _onDidChange(module),
        module: this,
        child: route.child(context, state),
      ),
    );
  }

  Page<void> _buildCustomTransitionPageForModule(BuildContext context, {required GoRouterState state, required ChildRoute route, required Module module}) {
    // Usar GoTransition do go_transitions
    final transition = route.transition ?? Modular.getDefaultTransition;
    final duration = route.duration ?? Modular.getDefaultDuration;

    // Configure default duration se fornecida
    if (duration != const Duration(milliseconds: 300)) {
      GoTransition.defaultDuration = duration;
    }

    if (transition != null) {
      final pageBuilder = transition.build(
        builder: (context, state) => ParentWidgetObserver(
          onDispose: (m) => _disposeModule(m),
          didChangeDependencies: (m) => _onDidChange(m),
          module: module,
          child: route.child(context, state),
        ),
      );
      return pageBuilder(context, state);
    }

    // Fallback para página sem transição
    return MaterialPage(
      key: state.pageKey,
      child: ParentWidgetObserver(
        onDispose: (m) => _disposeModule(m),
        didChangeDependencies: (m) => _onDidChange(m),
        module: module,
        child: route.child(context, state),
      ),
    );
  }

  Future<void> _registerModule(Module module) async {
    await InjectionManager.instance.registerBindsModule(module);
  }

  void _disposeModule(Module module) {
    if (didChangeGoingReference.contains(module)) return;
    InjectionManager.instance.unregisterModule(module);
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
