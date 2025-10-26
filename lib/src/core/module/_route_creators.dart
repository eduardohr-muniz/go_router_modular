part of 'module.dart';

/// Criadores de rotas (child, module, shell)
extension RouteCreators on Module {
  GoRoute _createChild({
    required ChildRoute childRoute,
    required bool topLevel,
    Duration? parentDuration,
    GoTransition? parentTransition,
  }) {
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
                parentDuration: parentDuration,
                parentTransition: parentTransition,
                module: this,
              ),
      parentNavigatorKey: childRoute.parentNavigatorKey,
      redirect: childRoute.redirect,
    );
  }

  GoRoute _createModule({
    required ModuleRoute module,
    required String modulePath,
    required bool topLevel,
    Duration? parentDuration,
    GoTransition? parentTransition,
  }) {
    final childRoute = module.module.routes.whereType<ChildRoute>().where((route) => adjustRoute(route.path) == '/').firstOrNull;
    final isShell = module.module.routes.whereType<ShellModularRoute>().isNotEmpty;

    // Resolve transition and duration for this module
    final resolvedTransition = module.transition ?? parentTransition;
    final resolvedDuration = module.duration ?? parentDuration;

    if (!isShell) {
      assert(childRoute != null, ModuleAssert.childRouteAssert(module.module.runtimeType.toString()));
    }

    // Para módulos shell, não precisa de um builder específico, apenas as rotas
    if (isShell) {
      return GoRoute(
        path: _normalizePath(path: module.path, topLevel: topLevel),
        name: module.name,
        routes: module.module.configureRoutes(
          modulePath: module.path,
          topLevel: false,
          parentDuration: resolvedDuration,
          parentTransition: resolvedTransition,
        ),
        redirect: (context, state) => _buildRedirectAndInjectBinds(context, state, module: module.module, modulePath: module.path, redirect: null, topLevel: topLevel),
      );
    }

    return GoRoute(
      path: _normalizePath(path: module.path + (childRoute?.path ?? ""), topLevel: topLevel),
      name: childRoute?.name ?? module.name,
      pageBuilder: childRoute?.pageBuilder != null
          ? (context, state) => childRoute!.pageBuilder!(context, state)
          : (context, state) => _buildCustomTransitionPage(
                context,
                state: state,
                route: childRoute!,
                parentDuration: resolvedDuration,
                parentTransition: resolvedTransition,
                module: module.module,
              ),
      routes: module.module.configureRoutes(
        modulePath: module.path,
        topLevel: false,
        parentDuration: resolvedDuration,
        parentTransition: resolvedTransition,
      ),
      parentNavigatorKey: childRoute?.parentNavigatorKey,
      redirect: (context, state) => _buildRedirectAndInjectBinds(context, state, module: module.module, modulePath: module.path, redirect: childRoute?.redirect, topLevel: topLevel),
    );
  }

  List<GoRoute> _createChildRoutes({
    required bool topLevel,
    Duration? parentDuration,
    GoTransition? parentTransition,
  }) {
    return routes.whereType<ChildRoute>().where((route) => adjustRoute(route.path) != '/').map((route) {
      return _createChild(
        childRoute: route,
        topLevel: topLevel,
        parentDuration: parentDuration,
        parentTransition: parentTransition,
      );
    }).toList();
  }

  List<GoRoute> _createModuleRoutes({
    required String modulePath,
    required bool topLevel,
    Duration? parentDuration,
    GoTransition? parentTransition,
  }) {
    return routes.whereType<ModuleRoute>().map((module) {
      return _createModule(
        module: module,
        modulePath: modulePath,
        topLevel: topLevel,
        parentDuration: parentDuration,
        parentTransition: parentTransition,
      );
    }).toList();
  }

  List<RouteBase> _createShellRoutes(
    bool topLevel,
    String modulePath, {
    Duration? parentDuration,
    GoTransition? parentTransition,
  }) {
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
                return _createChild(
                  childRoute: routeOrModule,
                  topLevel: topLevel,
                  parentDuration: parentDuration,
                  parentTransition: parentTransition,
                );
              } else if (routeOrModule is ModuleRoute) {
                return _createModule(
                  module: routeOrModule,
                  modulePath: routeOrModule.path,
                  topLevel: topLevel,
                  parentDuration: parentDuration,
                  parentTransition: parentTransition,
                );
              }
              return null;
            })
            .whereType<RouteBase>()
            .toList(),
      );
    }).toList();
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
}
