import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/go_router_modular.dart';

typedef Modular = GoRouterModular;

class GoRouterModular {
  GoRouterModular._();
  static GoRouter get routerConfig {
    assert(_router != null, 'Add GoRouterModular.configure in main.dart');
    return _router!;
  }

  static bool get debugLogDiagnostics {
    assert(_debugLogDiagnostics != null, 'Add GoRouterModular.configure in main.dart');
    return _debugLogDiagnostics!;
  }

  static GoRouter? _router;

  static bool? _debugLogDiagnostics;

  static T get<T>() => Bind.get<T>();

  static getCurrentPathOf(BuildContext context) => GoRouterState.of(context).path ?? '';

  static GoRouterState stateOf(BuildContext context) => GoRouterState.of(context);

  static GoRouter configure({
    required Module appModule,
    required String initialRoute,
    bool debugLogDiagnostics = true,
    Codec<Object?, Object?>? extraCodec,
    void Function(BuildContext, GoRouterState, GoRouter)? onException,
    Page<dynamic> Function(BuildContext, GoRouterState)? errorPageBuilder,
    Widget Function(BuildContext, GoRouterState)? errorBuilder,
    FutureOr<String?> Function(BuildContext, GoRouterState)? redirect,
    Listenable? refreshListenable,
    int redirectLimit = 5,
    bool routerNeglect = false,
    bool overridePlatformDefaultLocation = false,
    Object? initialExtra,
    List<NavigatorObserver>? observers,
    bool debugLogDiagnosticsGoRouter = false,
    GlobalKey<NavigatorState>? navigatorKey,
    String? restorationScopeId,
    bool requestFocus = true,
  }) {
    if (_router != null) return _router!;
    _debugLogDiagnostics = debugLogDiagnostics;
    _router = GoRouter(
      routes: appModule.configureRoutes(Injector()),
      initialLocation: initialRoute,
      debugLogDiagnostics: debugLogDiagnosticsGoRouter,
      errorBuilder: errorBuilder,
      errorPageBuilder: errorPageBuilder,
      extraCodec: extraCodec,
      initialExtra: initialExtra,
      navigatorKey: navigatorKey,
      observers: observers,
      onException: onException,
      overridePlatformDefaultLocation: overridePlatformDefaultLocation,
      redirect: redirect,
      refreshListenable: refreshListenable,
      redirectLimit: redirectLimit,
      requestFocus: requestFocus,
      restorationScopeId: restorationScopeId,
      routerNeglect: routerNeglect,
    );
    debugLogDiagnostics = debugLogDiagnostics;
    return _router!;
  }
}
