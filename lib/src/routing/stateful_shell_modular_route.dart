import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

/// Modular wrapper for [StatefulShellRoute.indexedStack].
///
/// Each branch contains its own navigator with persistent state,
/// using an IndexedStack to manage the branch Widgets.
///
/// Example:
/// ```dart
/// class AppModule extends Module {
///   @override
///   List<ModularRoute> get routes => [
///     StatefulShellModularRoute(
///       builder: (context, state, navigationShell) => ScaffoldWithNavBar(
///         navigationShell: navigationShell,
///       ),
///       branches: [
///         ModularBranch(
///           routes: [
///             ChildRoute('/home', child: (_, __) => HomePage()),
///           ],
///         ),
///         ModularBranch(
///           module: SettingsModule(),
///         ),
///       ],
///     ),
///   ];
/// }
/// ```
class StatefulShellModularRoute extends ModularRoute {
  final Widget Function(BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell)? builder;
  final Page<dynamic> Function(BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell)? pageBuilder;
  final List<ModularBranch> branches;
  final FutureOr<String?> Function(BuildContext context, GoRouterState state)? redirect;
  final GlobalKey<NavigatorState>? parentNavigatorKey;
  final String? restorationScopeId;
  final GlobalKey<StatefulNavigationShellState>? shellKey;

  StatefulShellModularRoute({
    required this.branches,
    this.builder,
    this.pageBuilder,
    this.redirect,
    this.parentNavigatorKey,
    this.restorationScopeId,
    this.shellKey,
  });
}

/// Represents a branch in a [StatefulShellModularRoute].
///
/// A branch can contain either direct [routes] (ChildRoute/ModuleRoute)
/// or a [module] whose routes will be used.
class ModularBranch {
  final List<ModularRoute>? routes;
  final Module? module;
  final GlobalKey<NavigatorState>? navigatorKey;
  final String? restorationScopeId;
  final String? initialLocation;
  final List<NavigatorObserver>? observers;

  ModularBranch({
    this.routes,
    this.module,
    this.navigatorKey,
    this.restorationScopeId,
    this.initialLocation,
    this.observers,
  }) : assert(routes != null || module != null, 'A ModularBranch must have either routes or a module.');
}
