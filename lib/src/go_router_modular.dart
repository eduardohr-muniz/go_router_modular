import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/src/module.dart';
import 'package:go_router_modular/src/route_observer.dart';

class GoRouterModular {
  static final ModularRouteObserver _routeObserver = ModularRouteObserver();

  static GoRouter configure({
    required Module module,
    String initialLocation = '/',
    List<RouteBase> routes = const [],
    List<NavigatorObserver> observers = const [],
    String? debugLabel,
    bool debugLogDiagnostics = false,
  }) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        ...module.configureRoutes(topLevel: true),
        ...routes,
      ],
      observers: [
        _routeObserver,
        ...observers,
      ],
      debugLogDiagnostics: debugLogDiagnostics,
    );
  }
}
