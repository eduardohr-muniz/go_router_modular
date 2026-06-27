import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/src/routing/i_modular_route.dart';

class ShellModularRoute extends ModularRoute {
  final FutureOr<String?> Function(BuildContext context, GoRouterState state)? redirect;
  final Widget Function(BuildContext context, GoRouterState state, Widget child)? builder;
  final Page<dynamic> Function(BuildContext context, GoRouterState state, Widget child)? pageBuilder;
  final List<NavigatorObserver>? observers;
  final List<ModularRoute> routes;
  final GlobalKey<NavigatorState>? parentNavigatorKey;
  final GlobalKey<NavigatorState>? navigatorKey;
  final String? restorationScopeId;

  ShellModularRoute({
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
