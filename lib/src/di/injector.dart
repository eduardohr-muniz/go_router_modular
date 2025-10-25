import 'dart:async';
import 'package:auto_injector/auto_injector.dart';
import 'package:flutter/material.dart';

/// Main injector instance for go_router_modular
final AutoInjector injector = AutoInjector(
  tag: 'GoRouterModular',
  on: (i) {
    i.addInstance<AutoInjector>(i);
    i.commit();
  },
);

/// Extension to add navigation context to AutoInjector
extension InjectorExtends on AutoInjector {
  /// Get current navigation context
  BuildContext? get context => modularNavigatorKey.currentContext;

  /// Get arguments from current route
  Map<String, dynamic> get args => getArguments();

  /// Get arguments helper method
  Map<String, dynamic> getArguments() {
    // This will be implemented based on go_router state
    return {};
  }
}

/// Global navigator key for modular navigation
final GlobalKey<NavigatorState> modularNavigatorKey = GlobalKey<NavigatorState>();

/// Service to manage route completion
class RouteWithCompleterService {
  static final Map<String, Completer<void>> _routeCompleters = {};

  static bool hasRouteCompleter() => _routeCompleters.isNotEmpty;

  static Completer<void> getLastCompleteRoute() {
    if (_routeCompleters.isEmpty) {
      _routeCompleters['default'] = Completer<void>();
    }
    return _routeCompleters.values.last;
  }

  static void clearCompleters() {
    _routeCompleters.clear();
  }
}
