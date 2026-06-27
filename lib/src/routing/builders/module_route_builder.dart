import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/src/module/module.dart';
import 'package:go_router_modular/src/routing/child_route.dart';
import 'package:go_router_modular/src/routing/modular_router_runtime.dart';
import 'package:go_router_modular/src/routing/module_route.dart';
import 'package:go_router_modular/src/routing/path/route_path_normalizer.dart';
import 'package:go_router_modular/src/routing/redirect/module_route_lifecycle.dart';
import 'package:go_router_modular/src/routing/shell_modular_route.dart';
import 'package:go_router_modular/src/routing/stateful_shell_modular_route.dart';
import 'package:go_router_modular/src/routing/transitions/route_transition_factory.dart';
import 'package:go_router_modular/src/shared/asserts/module_assert.dart';
import 'package:go_router_modular/src/ui/parent_widget_observer.dart';

/// Constrói o [GoRoute] de uma [ModuleRoute], detectando se o módulo de destino
/// é um shell, um stateful shell ou um módulo regular (com rota índice `/`),
/// acoplando o registro de binds no `redirect` e o descarte no observer.
class ModuleRouteBuilder {
  ModuleRouteBuilder({
    required this.lifecycle,
    required this.buildNested,
  });

  final ModuleRouteLifecycle lifecycle;

  /// Constrói as rotas de um submódulo (delegado ao orquestrador) — evita ciclo.
  final List<RouteBase> Function(Module module, String modulePath) buildNested;

  GoRoute build(
      {required ModuleRoute module,
      required String modulePath,
      required bool topLevel}) {
    final childRoute = module.module.routes
        .whereType<ChildRoute>()
        .where((route) => RoutePathNormalizer.adjustRoute(route.path) == '/')
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
        path: RoutePathNormalizer.normalizePath(
            path: module.path, topLevel: topLevel),
        name: module.name,
        routes: buildNested(module.module, module.path),
        redirect: (context, state) async {
          final result = await lifecycle.redirectAndInjectBinds(
            context,
            state,
            module: module.module,
            redirect: null,
          );
          if (result != null) return result;

          // Se a rota exata é o path do módulo, redirecionar para a primeira branch
          final currentPath = state.uri.path;
          final normalizedModulePath = RoutePathNormalizer.normalizePath(
              path: module.path, topLevel: topLevel);
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
        path: RoutePathNormalizer.normalizePath(
            path: module.path, topLevel: topLevel),
        name: module.name,
        routes: buildNested(module.module, module.path),
        redirect: (context, state) => lifecycle.redirectAndInjectBinds(
            context, state,
            module: module.module, redirect: null),
      );
    }

    final nonNullChildRoute = childRoute!;
    moduleBuilder(BuildContext context, GoRouterState state) =>
        ParentWidgetObserver(
          onDispose: (mod) => lifecycle.disposeModule(mod),
          didChangeDependencies: (mod) =>
              lifecycle.parentModule.onDidChangeGoingReference(mod),
          module: module.module,
          childBuilder: (_) => nonNullChildRoute.child(context, state),
        );

    final fullPath = module.path + nonNullChildRoute.path;
    final moduleName = nonNullChildRoute.name ?? module.name;
    final childRoutes = buildNested(module.module, module.path);
    final transition = nonNullChildRoute.transition ?? modularDefaultTransition;

    if (transition != null) {
      final route = RouteTransitionFactory.buildGoRouteWithTransition(
        path: fullPath,
        name: moduleName,
        transition: transition,
        builder: moduleBuilder,
        parentNavigatorKey: nonNullChildRoute.parentNavigatorKey,
        redirect: (context, state) => lifecycle.redirectAndInjectBinds(
            context, state,
            module: module.module, redirect: nonNullChildRoute.redirect),
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
      path: RoutePathNormalizer.normalizePath(
          path: fullPath, topLevel: topLevel),
      name: moduleName,
      builder: moduleBuilder,
      parentNavigatorKey: nonNullChildRoute.parentNavigatorKey,
      redirect: (context, state) => lifecycle.redirectAndInjectBinds(
        context,
        state,
        module: module.module,
        redirect: nonNullChildRoute.redirect,
      ),
      routes: childRoutes.isNotEmpty ? childRoutes : const [],
      onExit: nonNullChildRoute.onExit,
    );
  }

  /// Resolve o caminho da primeira rota da primeira branch de um stateful shell.
  static String _resolveFirstBranchLocation(
      StatefulShellModularRoute statefulRoute, String modulePath) {
    final firstBranch = statefulRoute.branches.first;

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
}
