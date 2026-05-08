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
///         ModuleBranch(
///           '/settings',
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
/// Uma branch define pelo menos uma rota ([ChildRoute], [ModuleRoute], etc.).
/// Quando a branch é só um `ModuleRoute(path, module: …)`, use [ModuleBranch] como atalho.
class ModularBranch {
  final List<ModularRoute> routes;
  final GlobalKey<NavigatorState>? navigatorKey;
  final String? restorationScopeId;
  final String? initialLocation;
  final List<NavigatorObserver>? observers;

  ModularBranch({
    required this.routes,
    this.navigatorKey,
    this.restorationScopeId,
    this.initialLocation,
    this.observers,
  }) : assert(routes.isNotEmpty, 'A ModularBranch must have routes.');
}

/// Atalho para uma branch do [StatefulShellModularRoute] que monta um único [Module]
/// em um segmento de URL ([path]).
///
/// É equivalente a:
/// ```dart
/// ModularBranch(
///   routes: [ModuleRoute(path, module: module)],
///   navigatorKey: navigatorKey,
///   restorationScopeId: restorationScopeId,
///   initialLocation: initialLocation,
///   observers: observers,
/// )
/// ```
///
/// O primeiro argumento é o [path] posicional (mesmo estilo de [ModuleRoute]).
///
/// O [path] deve ser **único entre as branches** do mesmo shell (por exemplo `/pos`,
/// `/settings`). Caminhos duplicados quebram redirects e rotas nomeadas do GoRouter.
///
/// O módulo recebe binds e rotas como em qualquer [ModuleRoute]: registro lazy ao
/// visitar a aba e dispose quando o shell sai da árvore de navegação.
class ModuleBranch extends ModularBranch {
  /// Módulo montado nesta aba (mesmo valor passado ao [ModuleRoute] interno).
  final Module module;

  /// Segmento desta aba sob o módulo pai (mesmo valor passado ao [ModuleRoute] interno).
  final String path;

  /// [path] posicional: segmento de URL desta aba (único entre as branches do shell).
  ModuleBranch(
    this.path, {
    required this.module,
    super.navigatorKey,
    super.restorationScopeId,
    super.initialLocation,
    super.observers,
  }) : super(
          routes: [ModuleRoute(path, module: module)],
        );
}
