import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/src/module/module.dart';
import 'package:go_transitions/go_transitions.dart';

/// Neutral runtime state of the modular router.
///
/// Written by `Modular.configure` and read by `routing/` and `events/` without
/// importing the `Modular` facade, which breaks the `config` to `route_builder`
/// coupling: subsystems read state from a neutral holder rather than from the
/// composition root.

/// Global key of the root navigator, set by `Modular.configure`.
late GlobalKey<NavigatorState> modularNavigatorKey;

/// Default transition applied to routes without one of their own, set by
/// `Modular.configure` through `defaultTransition`.
GoTransition? modularDefaultTransition;

/// The module that owns each go_router route built from a [ModuleRoute] or a
/// shell, filled in by the builders. It is what makes it possible to tell which
/// modules are present in a committed configuration
/// ([modulesInConfiguration]).
///
/// The builders register every modular route they produce, whichever router
/// ends up using it, so a route missing from this map carries no module and
/// therefore opens no navigation reference to reconcile.
final Map<RouteBase, Module> modularRouteModules = Map<RouteBase, Module>.identity();

/// The modules with at least one route in [configuration], including the ones
/// nested in shells and the ones stacked with `push`.
Set<Module> modulesInConfiguration(RouteMatchList configuration) {
  final present = Set<Module>.identity();
  void visit(List<RouteMatchBase> matches) {
    for (final match in matches) {
      final module = modularRouteModules[match.route];
      if (module != null) present.add(module);
      if (match is ShellRouteMatch) visit(match.matches);
      if (match is ImperativeRouteMatch) visit(match.matches.matches);
    }
  }

  visit(configuration.matches);
  return present;
}
