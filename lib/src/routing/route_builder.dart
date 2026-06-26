import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/internal/asserts/module_assert.dart';
import 'package:go_router_modular/src/widgets/once_builder.dart';
import 'package:go_router_modular/src/widgets/parent_widget_observer.dart';
import 'package:go_transitions/go_transitions.dart';

/// Builds GoRouter routes from a Module's route definitions.
class ModularRouteBuilder {
  final Module module;

  ModularRouteBuilder(this.module);

  List<RouteBase> buildRoutes({String modulePath = '', bool topLevel = false}) {
    return [
      ..._createChildRoutes(topLevel: topLevel),
      ..._createModuleRoutes(modulePath: modulePath, topLevel: topLevel),
      ..._createShellRoutes(topLevel, modulePath),
      ..._createStatefulShellRoutes(topLevel, modulePath),
    ];
  }

  // ==================== CHILD ROUTES ====================

  List<GoRoute> _createChildRoutes({required bool topLevel}) {
    return module.routes
        .whereType<ChildRoute>()
        .where((route) => _adjustRoute(route.path) != '/')
        .map((route) => _createChild(childRoute: route, topLevel: topLevel))
        .toList();
  }

  GoRoute _createChild(
      {required ChildRoute childRoute, required bool topLevel}) {
    if (childRoute.pageBuilder != null) {
      return GoRoute(
        path: _normalizePath(path: childRoute.path, topLevel: topLevel),
        name: childRoute.name,
        pageBuilder: childRoute.pageBuilder,
        parentNavigatorKey: childRoute.parentNavigatorKey,
        redirect: childRoute.redirect,
        onExit: childRoute.onExit,
      );
    }

    final transition = childRoute.transition ?? Modular.getDefaultTransition;

    if (transition != null) {
      return _buildGoRouteWithTransition(
        path: childRoute.path,
        name: childRoute.name,
        transition: transition,
        builder: (context, state) => OnceBuilder(
          builder: (_) => childRoute.child(context, state),
        ),
        parentNavigatorKey: childRoute.parentNavigatorKey,
        redirect: childRoute.redirect,
        topLevel: topLevel,
        transitionDuration: childRoute.transitionDuration,
        onExit: childRoute.onExit,
      );
    }

    return GoRoute(
      path: _normalizePath(path: childRoute.path, topLevel: topLevel),
      name: childRoute.name,
      builder: (context, state) => OnceBuilder(
        builder: (_) => childRoute.child(context, state),
      ),
      parentNavigatorKey: childRoute.parentNavigatorKey,
      redirect: childRoute.redirect,
      onExit: childRoute.onExit,
    );
  }

  // ==================== MODULE ROUTES ====================

  List<GoRoute> _createModuleRoutes(
      {required String modulePath, required bool topLevel}) {
    return module.routes
        .whereType<ModuleRoute>()
        .map((m) => _createModule(
            module: m, modulePath: modulePath, topLevel: topLevel))
        .toList();
  }

  GoRoute _createModule(
      {required ModuleRoute module,
      required String modulePath,
      required bool topLevel}) {
    final childRoute = module.module.routes
        .whereType<ChildRoute>()
        .where((route) => _adjustRoute(route.path) == '/')
        .firstOrNull;
    final isShell =
        module.module.routes.whereType<ShellModularRoute>().isNotEmpty;
    final isStatefulShell =
        module.module.routes.whereType<StatefulShellModularRoute>().isNotEmpty;

    if (!isShell && !isStatefulShell) {
      assert(childRoute != null,
          ModuleAssert.childRouteAssert(module.module.runtimeType.toString()));
    }

    if (isStatefulShell) {
      final statefulRoute =
          module.module.routes.whereType<StatefulShellModularRoute>().first;
      final firstBranchInitialLocation =
          _resolveFirstBranchLocation(statefulRoute, module.path);

      return GoRoute(
        path: _normalizePath(path: module.path, topLevel: topLevel),
        name: module.name,
        routes: module.module
            .configureRoutes(modulePath: module.path, topLevel: false),
        redirect: (context, state) async {
          final result = await _buildRedirectAndInjectBinds(
            context,
            state,
            module: module.module,
            modulePath: module.path,
            redirect: null,
            topLevel: topLevel,
          );
          if (result != null) return result;

          // Se a rota exata é o path do módulo, redirecionar para a primeira branch
          final currentPath = state.uri.path;
          final normalizedModulePath =
              _normalizePath(path: module.path, topLevel: topLevel);
          if (currentPath == normalizedModulePath ||
              currentPath == '$normalizedModulePath/') {
            final target = firstBranchInitialLocation;
            if (target != currentPath &&
                target != '$currentPath/' &&
                currentPath != '$target/') {
              return target;
            }
          }
          return null;
        },
      );
    }

    if (isShell) {
      return GoRoute(
        path: _normalizePath(path: module.path, topLevel: topLevel),
        name: module.name,
        routes: module.module
            .configureRoutes(modulePath: module.path, topLevel: false),
        redirect: (context, state) => _buildRedirectAndInjectBinds(
            context, state,
            module: module.module,
            modulePath: module.path,
            redirect: null,
            topLevel: topLevel),
      );
    }

    final nonNullChildRoute = childRoute!;
    final moduleBuilder = (context, state) => ParentWidgetObserver(
          onDispose: (mod) => _disposeModule(mod),
          didChangeDependencies: (mod) =>
              this.module.onDidChangeGoingReference(mod),
          module: module.module,
          childBuilder: (_) => nonNullChildRoute.child(context, state),
        );

    final fullPath = module.path + nonNullChildRoute.path;
    final moduleName = nonNullChildRoute.name ?? module.name;
    final childRoutes =
        module.module.configureRoutes(modulePath: module.path, topLevel: false);
    final transition =
        nonNullChildRoute.transition ?? Modular.getDefaultTransition;

    if (transition != null) {
      final route = _buildGoRouteWithTransition(
        path: fullPath,
        name: moduleName,
        transition: transition,
        builder: moduleBuilder,
        parentNavigatorKey: nonNullChildRoute.parentNavigatorKey,
        redirect: (context, state) => _buildRedirectAndInjectBinds(
            context, state,
            module: module.module,
            modulePath: module.path,
            redirect: nonNullChildRoute.redirect,
            topLevel: topLevel),
        topLevel: topLevel,
        transitionDuration: nonNullChildRoute.transitionDuration,
        onExit: nonNullChildRoute.onExit,
      );

      return GoRoute(
        path: route.path,
        name: route.name,
        pageBuilder: route.pageBuilder,
        parentNavigatorKey: route.parentNavigatorKey,
        redirect: route.redirect,
        routes: childRoutes.isNotEmpty ? childRoutes : const [],
        onExit: route.onExit,
      );
    }

    return GoRoute(
      path: _normalizePath(path: fullPath, topLevel: topLevel),
      name: moduleName,
      builder: moduleBuilder,
      parentNavigatorKey: nonNullChildRoute.parentNavigatorKey,
      redirect: (context, state) => _buildRedirectAndInjectBinds(
        context,
        state,
        module: module.module,
        modulePath: module.path,
        redirect: nonNullChildRoute.redirect,
        topLevel: topLevel,
      ),
      routes: childRoutes.isNotEmpty ? childRoutes : const [],
      onExit: nonNullChildRoute.onExit,
    );
  }

  // ==================== SHELL ROUTES ====================

  List<RouteBase> _createShellRoutes(bool topLevel, String modulePath) {
    return module.routes.whereType<ShellModularRoute>().map((shellRoute) {
      final existsChildRouteIncorrect = shellRoute.routes
          .whereType<ChildRoute>()
          .where((route) => _adjustRoute(route.path) == '/')
          .isNotEmpty;
      assert(!existsChildRouteIncorrect,
          ModuleAssert.shellRouteAssert(module.runtimeType.toString()));

      return ShellRoute(
        builder: (context, state, child) => shellRoute.builder!(
          context,
          state,
          ParentWidgetObserver(
            onDispose: (mod) => _disposeModule(mod),
            didChangeDependencies: (mod) =>
                module.onDidChangeGoingReference(mod),
            module: module,
            child: child,
          ),
        ),
        pageBuilder: shellRoute.pageBuilder != null
            ? (context, state, child) =>
                shellRoute.pageBuilder!(context, state, child)
            : null,
        redirect: shellRoute.redirect,
        navigatorKey: shellRoute.navigatorKey,
        observers: shellRoute.observers,
        parentNavigatorKey: shellRoute.parentNavigatorKey,
        restorationScopeId: shellRoute.restorationScopeId,
        routes: shellRoute.routes
            .map((routeOrModule) {
              if (routeOrModule is ChildRoute) {
                return _createChild(
                    childRoute: routeOrModule, topLevel: topLevel);
              } else if (routeOrModule is ModuleRoute) {
                return _createModule(
                    module: routeOrModule,
                    modulePath: routeOrModule.path,
                    topLevel: topLevel);
              }
              return null;
            })
            .whereType<RouteBase>()
            .toList(),
      );
    }).toList();
  }

  // ==================== STATEFUL SHELL ROUTES ====================

  List<RouteBase> _createStatefulShellRoutes(bool topLevel, String modulePath) {
    return module.routes
        .whereType<StatefulShellModularRoute>()
        .map((statefulRoute) {
      // Track branch modules for shell-level lifecycle management
      final branchModules = <Module>[];

      final branches = statefulRoute.branches.map((branch) {
        _collectBranchModulesFromRoutes(branch.routes, branchModules);
        final branchRoutes = _buildBranchRoutes(branch, topLevel, modulePath);

        return StatefulShellBranch(
          routes: branchRoutes,
          navigatorKey: branch.navigatorKey,
          restorationScopeId: branch.restorationScopeId,
          initialLocation: branch.initialLocation,
          observers: branch.observers ?? const [],
        );
      }).toList();

      // Always wrap with ParentWidgetObserver for disposal, even if builder is null
      final effectiveBuilder = statefulRoute.builder ??
          (BuildContext context, GoRouterState state,
                  StatefulNavigationShell navigationShell) =>
              navigationShell;

      final shellChild = (
        BuildContext context,
        GoRouterState state,
        StatefulNavigationShell navigationShell,
      ) =>
          ParentWidgetObserver(
            onDispose: (mod) => _disposeStatefulShellModule(mod, branchModules),
            didChangeDependencies: (mod) =>
                module.onDidChangeGoingReference(mod),
            module: module,
            child: effectiveBuilder(context, state, navigationShell),
          );

      final navigatorContainer = _resolvedStatefulShellContainer(statefulRoute);
      if (navigatorContainer != null) {
        return StatefulShellRoute(
          branches: branches,
          notifyRootObserver: statefulRoute.notifyRootObserver,
          navigatorContainerBuilder: navigatorContainer,
          builder: shellChild,
          redirect: statefulRoute.redirect,
          parentNavigatorKey: statefulRoute.parentNavigatorKey,
          restorationScopeId: statefulRoute.restorationScopeId,
          key: statefulRoute.shellKey,
        );
      }

      return StatefulShellRoute.indexedStack(
        branches: branches,
        notifyRootObserver: statefulRoute.notifyRootObserver,
        builder: shellChild,
        redirect: statefulRoute.redirect,
        parentNavigatorKey: statefulRoute.parentNavigatorKey,
        restorationScopeId: statefulRoute.restorationScopeId,
        key: statefulRoute.shellKey,
      );
    }).toList();
  }

  /// [StatefulShellModularRoute]: [navigatorContainerBuilder] OU transição efetiva
  /// (`transition` / [Modular.getDefaultTransition] / durações explícitas / default global).
  ShellNavigationContainerBuilder? _resolvedStatefulShellContainer(
    StatefulShellModularRoute route,
  ) {
    if (route.navigatorContainerBuilder != null) {
      return route.navigatorContainerBuilder;
    }

    final moduleDefault = Modular.getDefaultTransition;
    final transitionFromSources = route.transition ?? moduleDefault;
    final passesExplicitDuration = route.transitionDuration != null ||
        route.reverseTransitionDuration != null;

    final useAnimatedContainer =
        transitionFromSources != null || passesExplicitDuration;

    if (!useAnimatedContainer) return null;

    final effectiveTransition = transitionFromSources ?? GoTransitions.fade;
    final effectiveDuration =
        route.transitionDuration ?? GoTransition.defaultDuration;
    final effectiveReverse = route.reverseTransitionDuration ??
        GoTransition.defaultReverseDuration ??
        effectiveDuration;

    // Durações já normalizadas (GoTransition.default* / configure) para igualar ao
    // comportamento das rotas; o helper quase sempre aplica copyWith nos settings.
    return StatefulShellBranchTransitions.withGoTransition(
      effectiveTransition,
      transitionDuration: effectiveDuration,
      reverseTransitionDuration: effectiveReverse,
    );
  }

  List<RouteBase> _buildBranchRoutes(
      ModularBranch branch, bool topLevel, String modulePath) {
    return branch.routes
        .map((routeOrModule) {
          if (routeOrModule is ChildRoute) {
            return _createChild(childRoute: routeOrModule, topLevel: topLevel);
          }
          if (routeOrModule is ModuleRoute) {
            return _createModule(
                module: routeOrModule,
                modulePath: routeOrModule.path,
                topLevel: topLevel);
          }
          return null;
        })
        .whereType<RouteBase>()
        .toList();
  }

  void _collectBranchModulesFromRoutes(
      List<ModularRoute> routes, List<Module> branchModules) {
    for (final modularRoute in routes) {
      if (modularRoute is ModuleRoute) {
        branchModules.add(modularRoute.module);
      }
    }
  }

  /// Disposes all branch modules and then the shell module itself.
  void _disposeStatefulShellModule(
      Module shellMod, List<Module> branchModules) {
    for (final branchModule in branchModules) {
      if (module.didChangeGoingReference.contains(branchModule)) continue;
      InjectionManager.instance.unregisterModule(branchModule);
    }
    _disposeModule(shellMod);
  }

  // ==================== HELPERS ====================

  /// Resolve o caminho da primeira rota da primeira branch de um StatefulShellModularRoute.
  String _resolveFirstBranchLocation(
      StatefulShellModularRoute statefulRoute, String modulePath) {
    final firstBranch = statefulRoute.branches.first;

    // Se a branch tem initialLocation explícito, usar ele
    if (firstBranch.initialLocation != null) {
      return firstBranch.initialLocation!;
    }

    if (firstBranch.routes.isEmpty) {
      return modulePath;
    }

    final firstRoute = firstBranch.routes.first;
    if (firstRoute is ChildRoute) {
      final routePath = firstRoute.path == '/' ? '' : firstRoute.path;
      return '$modulePath$routePath';
    }
    if (firstRoute is ModuleRoute) {
      return '$modulePath${firstRoute.path}';
    }

    return modulePath;
  }

  // ==================== TRANSITIONS ====================

  GoRoute _buildGoRouteWithTransition({
    required String path,
    String? name,
    required GoTransition transition,
    required Widget Function(BuildContext, GoRouterState) builder,
    GlobalKey<NavigatorState>? parentNavigatorKey,
    FutureOr<String?> Function(BuildContext, GoRouterState)? redirect,
    required bool topLevel,
    Duration? transitionDuration,
    FutureOr<bool> Function(BuildContext, GoRouterState)? onExit,
  }) {
    if (transitionDuration != null) {
      final customDuration = transitionDuration;

      final pageBuilder = (BuildContext context, GoRouterState state) {
        final widget = builder(context, state);
        final originalDuration = GoTransition.defaultDuration;
        GoTransition.defaultDuration = customDuration;

        try {
          final tempPage =
              transition.build(builder: (_, __) => widget)(context, state);

          if (tempPage is CustomTransitionPage) {
            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: widget,
              transitionsBuilder: tempPage.transitionsBuilder,
              transitionDuration: customDuration,
              reverseTransitionDuration: customDuration,
              opaque: tempPage.opaque,
              barrierDismissible: tempPage.barrierDismissible,
              barrierColor: tempPage.barrierColor,
              barrierLabel: tempPage.barrierLabel,
              maintainState: tempPage.maintainState,
            );
          }

          return tempPage;
        } finally {
          GoTransition.defaultDuration = originalDuration;
        }
      };

      return GoRoute(
        path: _normalizePath(path: path, topLevel: topLevel),
        name: name,
        pageBuilder: pageBuilder,
        parentNavigatorKey: parentNavigatorKey,
        redirect: redirect,
        onExit: onExit,
      );
    }

    return GoRoute(
      path: _normalizePath(path: path, topLevel: topLevel),
      name: name,
      pageBuilder: transition.build(builder: builder),
      parentNavigatorKey: parentNavigatorKey,
      redirect: redirect,
      onExit: onExit,
    );
  }

  // ==================== REDIRECT & MODULE LIFECYCLE ====================

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
      await InjectionManager.instance.registerBindsModule(module);
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

  void _disposeModule(Module mod) {
    if (module.didChangeGoingReference.contains(mod)) return;
    InjectionManager.instance.unregisterModule(mod);
  }

  // ==================== PATH UTILITIES ====================

  String _adjustRoute(String route) {
    if (route == "/") return "/";
    if (route.startsWith("/:")) return "/";
    return route;
  }

  String _normalizePath({required String path, required bool topLevel}) {
    if (path.startsWith("/") && !topLevel && !path.startsWith("/:")) {
      path = path.substring(1);
    }
    return _parsePath(path);
  }

  String _parsePath(String path) {
    if (!path.endsWith('/')) path = '$path/';
    path = path.replaceAll(RegExp(r'/+'), '/');
    if (path == '/') return path;
    return path.substring(0, path.length - 1);
  }
}
