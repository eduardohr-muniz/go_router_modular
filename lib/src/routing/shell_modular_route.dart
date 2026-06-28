import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/src/routing/guards/modular_guard.dart';
import 'package:go_router_modular/src/routing/i_modular_route.dart';

class ShellModularRoute extends ModularRoute {
  /// Guards que protegem o shell, avaliados em curto-circuito ("primeiro que
  /// barrar vence"). Veja [ModularGuard].
  final List<ModularGuard> guards;

  @Deprecated('Use guards: [GuardFn(...)] instead of redirect. '
      'Will be removed in v6.0.0')
  final FutureOr<String?> Function(BuildContext context, GoRouterState state)? redirect;
  final Widget Function(BuildContext context, GoRouterState state, Widget child)? builder;
  final Page<dynamic> Function(BuildContext context, GoRouterState state, Widget child)? pageBuilder;
  final List<NavigatorObserver>? observers;
  final List<ModularRoute> routes;
  final GlobalKey<NavigatorState>? parentNavigatorKey;
  final GlobalKey<NavigatorState>? navigatorKey;
  final String? restorationScopeId;

  ShellModularRoute({
    this.guards = const [],
    @Deprecated('Use guards: [GuardFn(...)] instead of redirect. '
        'Will be removed in v6.0.0')
    this.redirect,
    this.pageBuilder,
    this.observers,
    this.parentNavigatorKey,
    this.navigatorKey,
    this.restorationScopeId,
    required this.builder,
    required this.routes,
  });
}
