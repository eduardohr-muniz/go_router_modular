import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/src/module/module.dart';
import 'package:go_router_modular/src/routing/builders/child_route_builder.dart';
import 'package:go_router_modular/src/routing/builders/module_route_builder.dart';
import 'package:go_router_modular/src/routing/child_route.dart';
import 'package:go_router_modular/src/routing/guards/guard_resolver.dart';
import 'package:go_router_modular/src/routing/i_modular_route.dart';
import 'package:go_router_modular/src/routing/modular_router_runtime.dart';
import 'package:go_router_modular/src/routing/module_route.dart';
import 'package:go_router_modular/src/routing/path/route_path_normalizer.dart';
import 'package:go_router_modular/src/routing/redirect/module_route_lifecycle.dart';
import 'package:go_router_modular/src/routing/shell_modular_route.dart';
import 'package:go_router_modular/src/routing/stateful_shell_branch_transitions.dart';
import 'package:go_router_modular/src/routing/stateful_shell_modular_route.dart';
import 'package:go_router_modular/src/shared/asserts/module_assert.dart';
import 'package:go_router_modular/src/ui/parent_widget_observer.dart';
import 'package:go_transitions/go_transitions.dart';

/// Constrói as rotas de shell de um módulo: [ShellModularRoute] → [ShellRoute]
/// e [StatefulShellModularRoute] → [StatefulShellRoute], envolvendo o navegador
/// com [ParentWidgetObserver] para o descarte em cascata.
class ModularShellRouteBuilder {
  ModularShellRouteBuilder({
    required this.parentModule,
    required this.childBuilder,
    required this.moduleBuilder,
    required this.lifecycle,
  });

  final Module parentModule;
  final ChildRouteBuilder childBuilder;
  final ModuleRouteBuilder moduleBuilder;
  final ModuleRouteLifecycle lifecycle;

  List<RouteBase> buildShellRoutes(bool topLevel, String modulePath) {
    return parentModule.routes.whereType<ShellModularRoute>().map((shellRoute) {
      final existsChildRouteIncorrect = shellRoute.routes
          .whereType<ChildRoute>()
          .where((route) => RoutePathNormalizer.adjustRoute(route.path) == '/')
          .isNotEmpty;
      assert(!existsChildRouteIncorrect,
          ModuleAssert.shellRouteAssert(parentModule.runtimeType.toString()));

      return ShellRoute(
        builder: (context, state, child) => shellRoute.builder!(
          context,
          state,
          ParentWidgetObserver(
            onDispose: (mod) => lifecycle.disposeModule(mod),
            didChangeDependencies: (mod) =>
                parentModule.onDidChangeGoingReference(mod),
            module: parentModule,
            child: child,
          ),
        ),
        pageBuilder: shellRoute.pageBuilder != null
            ? (context, state, child) =>
                shellRoute.pageBuilder!(context, state, child)
            : null,
        redirect: resolveGuards(
          shellRoute.guards,
          // ignore: deprecated_member_use_from_same_package
          legacyRedirect: shellRoute.redirect,
        ),
        navigatorKey: shellRoute.navigatorKey,
        observers: shellRoute.observers,
        parentNavigatorKey: shellRoute.parentNavigatorKey,
        restorationScopeId: shellRoute.restorationScopeId,
        routes: shellRoute.routes
            .map((routeOrModule) {
              if (routeOrModule is ChildRoute) {
                return childBuilder.build(
                    childRoute: routeOrModule, topLevel: topLevel);
              } else if (routeOrModule is ModuleRoute) {
                return moduleBuilder.build(
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

  List<RouteBase> buildStatefulShellRoutes(bool topLevel, String modulePath) {
    return parentModule.routes
        .whereType<StatefulShellModularRoute>()
        .map((statefulRoute) {
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

      final effectiveBuilder = statefulRoute.builder ??
          (BuildContext context, GoRouterState state,
                  StatefulNavigationShell navigationShell) =>
              navigationShell;

      shellChild(
        BuildContext context,
        GoRouterState state,
        StatefulNavigationShell navigationShell,
      ) =>
          ParentWidgetObserver(
            onDispose: (mod) =>
                lifecycle.disposeStatefulShellModule(mod, branchModules),
            didChangeDependencies: (mod) =>
                parentModule.onDidChangeGoingReference(mod),
            module: parentModule,
            child: effectiveBuilder(context, state, navigationShell),
          );

      final statefulRedirect = resolveGuards(
        statefulRoute.guards,
        // ignore: deprecated_member_use_from_same_package
        legacyRedirect: statefulRoute.redirect,
      );

      final navigatorContainer = _resolvedStatefulShellContainer(statefulRoute);
      if (navigatorContainer != null) {
        return StatefulShellRoute(
          branches: branches,
          notifyRootObserver: statefulRoute.notifyRootObserver,
          navigatorContainerBuilder: navigatorContainer,
          builder: shellChild,
          redirect: statefulRedirect,
          parentNavigatorKey: statefulRoute.parentNavigatorKey,
          restorationScopeId: statefulRoute.restorationScopeId,
          key: statefulRoute.shellKey,
        );
      }

      return StatefulShellRoute.indexedStack(
        branches: branches,
        notifyRootObserver: statefulRoute.notifyRootObserver,
        builder: shellChild,
        redirect: statefulRedirect,
        parentNavigatorKey: statefulRoute.parentNavigatorKey,
        restorationScopeId: statefulRoute.restorationScopeId,
        key: statefulRoute.shellKey,
      );
    }).toList();
  }

  /// Resolve o container: [navigatorContainerBuilder] explícito OU transição
  /// efetiva (rota/global/durações), senão `indexedStack` sem animação.
  ShellNavigationContainerBuilder? _resolvedStatefulShellContainer(
    StatefulShellModularRoute route,
  ) {
    if (route.navigatorContainerBuilder != null) {
      return route.navigatorContainerBuilder;
    }

    final moduleDefault = modularDefaultTransition;
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
            return childBuilder.build(
                childRoute: routeOrModule, topLevel: topLevel);
          }
          if (routeOrModule is ModuleRoute) {
            return moduleBuilder.build(
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
}
