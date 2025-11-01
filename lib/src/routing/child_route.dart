import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_transitions/go_transitions.dart';

class ChildRoute extends ModularRoute {
  final String path;
  final Widget Function(BuildContext context, GoRouterState state) child;
  final String? name;
  final Page<dynamic> Function(BuildContext context, GoRouterState state)? pageBuilder;
  final GlobalKey<NavigatorState>? parentNavigatorKey;
  final FutureOr<String?> Function(BuildContext context, GoRouterState state)? redirect;
  final FutureOr<bool> Function(BuildContext context, GoRouterState state)? onExit;
  final GoTransition? transition;

  ChildRoute(
    this.path, {
    required this.child,
    this.name,
    this.pageBuilder,
    this.parentNavigatorKey,
    this.redirect,
    this.onExit,
    this.transition,
  });
}
