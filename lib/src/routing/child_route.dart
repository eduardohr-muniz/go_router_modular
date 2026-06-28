import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/src/routing/guards/modular_guard.dart';
import 'package:go_transitions/go_transitions.dart';

import 'i_modular_route.dart';

class ChildRoute extends ModularRoute {
  final String path;
  final Widget Function(BuildContext context, GoRouterState state) child;
  final String? name;
  final Page<dynamic> Function(BuildContext context, GoRouterState state)? pageBuilder;
  final GlobalKey<NavigatorState>? parentNavigatorKey;

  /// Guards que protegem esta rota, avaliados em curto-circuito ("primeiro que
  /// barrar vence"). Veja [ModularGuard].
  final List<ModularGuard> guards;

  @Deprecated('Use guards: [GuardFn(...)] instead of redirect. '
      'Will be removed in v6.0.0')
  final FutureOr<String?> Function(BuildContext context, GoRouterState state)? redirect;
  final FutureOr<bool> Function(BuildContext context, GoRouterState state)? onExit;
  final GoTransition? transition;
  final Duration? transitionDuration;

  ChildRoute(
    this.path, {
    required this.child,
    this.name,
    this.pageBuilder,
    this.parentNavigatorKey,
    this.guards = const [],
    @Deprecated('Use guards: [GuardFn(...)] instead of redirect. '
        'Will be removed in v6.0.0')
    this.redirect,
    this.onExit,
    this.transition,
    this.transitionDuration,
  });
}
