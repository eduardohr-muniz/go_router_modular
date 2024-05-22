import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/injector.dart';

class ChildRoute extends ModularRoute {
  final Widget Function(BuildContext context, GoRouterState state, Injector i) child;
  final String? name;
  final Page<dynamic> Function(BuildContext, GoRouterState)? pageBuilder;
  final GlobalKey<NavigatorState>? parentNavigatorKey;
  final FutureOr<String?> Function(BuildContext, GoRouterState)? redirect;
  final FutureOr<bool> Function(BuildContext, GoRouterState)? onExit;
  final PageTransition pageTransition;

  ChildRoute(super.path,
      {required this.child,
      this.name,
      this.pageBuilder,
      this.parentNavigatorKey,
      this.redirect,
      this.onExit,
      this.pageTransition = PageTransition.fade});
}
