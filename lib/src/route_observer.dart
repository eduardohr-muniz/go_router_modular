import 'package:flutter/material.dart';
import 'package:go_router_modular/src/route_manager.dart';

class ModularRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  final RouteManager _routeManager = RouteManager();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      _handleRouteChange(route);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (route is PageRoute) {
      _handleRouteChange(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute is PageRoute) {
      _handleRouteChange(newRoute);
    }
  }

  void _handleRouteChange(Route<dynamic>? route) {
    if (route == null) return;

    final path = route.settings.name ?? route.settings.toString();
    _routeManager.handleRouteChange(path);
  }
}
