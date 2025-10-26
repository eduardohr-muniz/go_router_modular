import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class ChildRoute extends ModularRoute {
  final String path;
  final Widget Function(BuildContext context, GoRouterState state) child;
  final String? name;
  final Page<dynamic> Function(BuildContext context, GoRouterState state)? pageBuilder;
  final GlobalKey<NavigatorState>? parentNavigatorKey;
  final FutureOr<String?> Function(BuildContext context, GoRouterState state)? redirect;
  final FutureOr<bool> Function(BuildContext context, GoRouterState state)? onExit;
  final GoTransition? transition;
  final Duration? duration;

  ChildRoute(
    this.path, {
    required this.child,
    this.name,
    this.pageBuilder,
    this.parentNavigatorKey,
    this.redirect,
    this.onExit,
    this.transition,
    this.duration,
  });

  /// Resolves the transition for this route, inheriting from parent scope if not defined
  GoTransition? resolveTransition(GoTransition? parentTransition) {
    return transition ?? parentTransition;
  }

  /// Resolves the duration for this route, inheriting from parent scope if not defined
  Duration? resolveDuration(Duration? parentDuration) {
    return duration ?? parentDuration;
  }
}
