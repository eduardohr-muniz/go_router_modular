import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/internal/asserts/module_assert.dart';
import 'package:go_router_modular/src/widgets/parent_widget_observer.dart';

typedef FutureBinds = FutureOr<void>;
typedef FutureModules = FutureOr<List<Module>>;

abstract class Module {
  FutureModules imports() => [];
  FutureBinds binds(Injector i) {}
  List<ModularRoute> get routes => const [];
  void initState(InjectorReader i) {}
  void dispose() {}

  List<RouteBase> configureRoutes({String modulePath = '', bool topLevel = false}) {
    List<RouteBase> result = [];
    InjectionManager.instance.registerAppModule(this);

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
    // Se tem pageBuilder customizado, usa ele
    if (childRoute.pageBuilder != null) {
      return GoRoute(
        path: _normalizePath(path: childRoute.path, topLevel: topLevel),
        name: childRoute.name,
        pageBuilder: childRoute.pageBuilder,
        parentNavigatorKey: childRoute.parentNavigatorKey,
        redirect: childRoute.redirect,
      );
    }

    // Se tem transition, usa GoTransitions
    if (childRoute.transition != null) {
      return _buildGoRouteWithTransition(
        path: childRoute.path,
        name: childRoute.name,
        transition: childRoute.transition!,
        builder: (context, state) => _buildRouteChild(context, state: state, route: childRoute),
        parentNavigatorKey: childRoute.parentNavigatorKey,
        redirect: childRoute.redirect,
        topLevel: topLevel,
      );
    }

    // Se tem default transition configurado, usa ele
    final defaultTransition = Modular.getDefaultTransition;
    if (defaultTransition != null) {
      return _buildGoRouteWithTransition(
        path: childRoute.path,
        name: childRoute.name,
        transition: defaultTransition,
        builder: (context, state) => _buildRouteChild(context, state: state, route: childRoute),
        parentNavigatorKey: childRoute.parentNavigatorKey,
        redirect: childRoute.redirect,
        topLevel: topLevel,
      );
    }

    // Sem transição customizada, usa builder padrão
    return GoRoute(
      path: _normalizePath(path: childRoute.path, topLevel: topLevel),
      name: childRoute.name,
      builder: (context, state) => _buildRouteChild(
        context,
        state: state,
        route: childRoute,
      ),
      parentNavigatorKey: childRoute.parentNavigatorKey,
      redirect: childRoute.redirect,
    );
  }

  /// Cria um GoRoute com transição usando GoTransitions
  GoRoute _buildGoRouteWithTransition({
    required String path,
    String? name,
    required GoTransition transition,
    required Widget Function(BuildContext, GoRouterState) builder,
    GlobalKey<NavigatorState>? parentNavigatorKey,
    FutureOr<String?> Function(BuildContext, GoRouterState)? redirect,
    required bool topLevel,
  }) {
    return GoRoute(
      path: _normalizePath(path: path, topLevel: topLevel),
      name: name,
      pageBuilder: transition.build(builder: builder),
      parentNavigatorKey: parentNavigatorKey,
      redirect: redirect,
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

    // Cria o builder com ParentWidgetObserver
    // childRoute não é null aqui porque já foi validado acima
    final nonNullChildRoute = childRoute!;
    final moduleBuilder = (context, state) => ParentWidgetObserver(
          onDispose: (module) => _disposeModule(module),
          didChangeDependencies: (module) => _onDidChange(module),
          module: module.module,
          child: nonNullChildRoute.child(context, state),
        );

    final modulePath = module.path + nonNullChildRoute.path;
    final moduleName = nonNullChildRoute.name ?? module.name;

    // Se o childRoute tem transição, aplica no GoRoute do módulo
    if (nonNullChildRoute.transition != null) {
      return GoRoute(
        path: _normalizePath(path: modulePath, topLevel: topLevel),
        name: moduleName,
        pageBuilder: nonNullChildRoute.transition!.build(builder: moduleBuilder),
        routes: module.module.configureRoutes(modulePath: module.path, topLevel: false),
        parentNavigatorKey: nonNullChildRoute.parentNavigatorKey,
        redirect: (context, state) => _buildRedirectAndInjectBinds(context, state, module: module.module, modulePath: module.path, redirect: nonNullChildRoute.redirect, topLevel: topLevel),
      );
    }

    // Se tem default transition configurado, usa ele
    final defaultTransition = Modular.getDefaultTransition;
    if (defaultTransition != null) {
      return GoRoute(
        path: _normalizePath(path: modulePath, topLevel: topLevel),
        name: moduleName,
        pageBuilder: defaultTransition.build(builder: moduleBuilder),
        routes: module.module.configureRoutes(modulePath: module.path, topLevel: false),
        parentNavigatorKey: nonNullChildRoute.parentNavigatorKey,
        redirect: (context, state) => _buildRedirectAndInjectBinds(context, state, module: module.module, modulePath: module.path, redirect: nonNullChildRoute.redirect, topLevel: topLevel),
      );
    }

    // Sem transição, usa builder padrão
    return GoRoute(
      path: _normalizePath(path: modulePath, topLevel: topLevel),
      name: moduleName,
      builder: moduleBuilder,
      routes: module.module.configureRoutes(modulePath: module.path, topLevel: false),
      parentNavigatorKey: nonNullChildRoute.parentNavigatorKey,
      redirect: (context, state) => _buildRedirectAndInjectBinds(context, state, module: module.module, modulePath: module.path, redirect: nonNullChildRoute.redirect, topLevel: topLevel),
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
