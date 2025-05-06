import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/src/module.dart';
import 'package:go_router_modular/src/route_manager.dart';

class ModularRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  final RouteManager _routeManager = RouteManager();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    dev.log('🔵 didPush: ${route.settings.name}', name: 'GO_ROUTER_MODULAR');
    if (route is PageRoute) {
      _handleRouteChange(route);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    dev.log('🔴 didPop: ${route.settings.name}', name: 'GO_ROUTER_MODULAR');
    if (route is PageRoute) {
      _handleRouteChange(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    dev.log('🔄 didReplace: ${newRoute?.settings.name}',
        name: 'GO_ROUTER_MODULAR');
    if (newRoute is PageRoute) {
      _handleRouteChange(newRoute);
    }
  }

  void _handleRouteChange(Route<dynamic>? route) {
    if (route == null) {
      dev.log('❌ Route is null', name: 'GO_ROUTER_MODULAR');
      return;
    }

    final path = route.settings.name ?? route.settings.toString();
    dev.log('📍 Handling route: $path', name: 'GO_ROUTER_MODULAR');

    try {
      final context = route.navigator?.context;
      if (context == null) {
        dev.log('❌ Context is null', name: 'GO_ROUTER_MODULAR');
        return;
      }

      final state = GoRouterState.of(context);
      dev.log('📦 State extra: ${state.extra}', name: 'GO_ROUTER_MODULAR');

      // Extrai o módulo da rota atual
      final module = _extractModuleFromRoute(route);
      if (module != null) {
        dev.log('✅ Module found: ${module.runtimeType}',
            name: 'GO_ROUTER_MODULAR');
        _routeManager.registerRoute(path, module);
      } else {
        dev.log('❌ Module not found for route: $path',
            name: 'GO_ROUTER_MODULAR');
      }
    } catch (e, stack) {
      dev.log('❌ Error handling route: $e\n$stack', name: 'GO_ROUTER_MODULAR');
    }
  }

  Module? _extractModuleFromRoute(Route<dynamic> route) {
    if (route is PageRoute) {
      final context = route.navigator?.context;
      if (context != null) {
        try {
          final state = GoRouterState.of(context);
          final routeMatch = state.extra as Map<String, dynamic>?;
          dev.log('🔍 Route match: $routeMatch', name: 'GO_ROUTER_MODULAR');

          if (routeMatch != null && routeMatch.containsKey('module')) {
            return routeMatch['module'] as Module;
          }
        } catch (e, stack) {
          dev.log('❌ Error extracting module: $e\n$stack',
              name: 'GO_ROUTER_MODULAR');
        }
      }
    }
    return null;
  }
}
