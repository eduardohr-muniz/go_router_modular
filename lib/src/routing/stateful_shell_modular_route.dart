import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_transitions/go_transitions.dart';

import '../core/module/module.dart';
import 'child_route.dart';
import 'i_modular_route.dart';
import 'module_route.dart';

/// Modular wrapper for [StatefulShellRoute].
///
/// Troca entre branches:
/// - **`indexedStack`** (sem animação) só quando não há transição disponível —
///   [Modular.getDefaultTransition] é `null` e você não passou
///   [transition] nem [transitionDuration] nem [reverseTransitionDuration].
/// - Caso contrário, usa-se transição igual à das rotas: preencha só [transition],
///   só `transitionDuration`, ambos ou nenhum; o que faltar usa
///   **[Modular.getDefaultTransition]** e **[GoTransition.defaultDuration]**
///   (esta última também reflete `defaultTransitionDuration` de [GoRouterModular.configure]).
///
/// Sobrescritas explícitas: [transition], [transitionDuration], [reverseTransitionDuration].
/// [navigatorContainerBuilder], quando informado, **substitui** toda a lógica acima.
///
/// As transições de [ChildRoute]/[ModuleRoute] (`go_transitions`) continuam válidas
/// **dentro da pilha de cada branch**.
///
/// Example:
/// ```dart
/// class AppModule extends Module {
///   @override
///   List<ModularRoute> get routes => [
///     StatefulShellModularRoute(
///       transition: GoTransitions.slide.toTop.withFade,
///       transitionDuration: Duration(milliseconds: 300),
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
  final Widget Function(BuildContext context, GoRouterState state,
      StatefulNavigationShell navigationShell)? builder;
  final Page<dynamic> Function(BuildContext context, GoRouterState state,
      StatefulNavigationShell navigationShell)? pageBuilder;
  final List<ModularBranch> branches;

  /// Transição entre branches (`GoTransitions.*`). Omitido usa [Modular.getDefaultTransition]
  /// quando houver animação (ver documentação da classe).
  final GoTransition? transition;

  /// Duração da transição ao trocar de branch. Omitido usa [GoTransition.defaultDuration].
  final Duration? transitionDuration;

  /// Duração reversa opcional. Omitido usa [GoTransition.defaultReverseDuration] ou a duração efetiva.
  final Duration? reverseTransitionDuration;

  /// Container das branches.
  ///
  /// Se não for `null`, **substitui** [StatefulShellRoute.indexedStack] e tem prioridade
  /// sobre [transition] / durações. Veja [StatefulShellBranchTransitions] para presets.
  final ShellNavigationContainerBuilder? navigatorContainerBuilder;

  /// Encaminhado para [StatefulShellRoute]: notificar o observer raiz da troca de páginas.
  final bool notifyRootObserver;
  final FutureOr<String?> Function(BuildContext context, GoRouterState state)?
      redirect;
  final GlobalKey<NavigatorState>? parentNavigatorKey;
  final String? restorationScopeId;
  final GlobalKey<StatefulNavigationShellState>? shellKey;

  StatefulShellModularRoute({
    required this.branches,
    this.builder,
    this.pageBuilder,
    this.transition,
    this.transitionDuration,
    this.reverseTransitionDuration,
    this.navigatorContainerBuilder,
    this.notifyRootObserver = true,
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
