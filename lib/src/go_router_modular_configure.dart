import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class GoRouterModular {
  GoRouterModular._();

  // ignore: prefer_typing_uninitialized_variables
  static late final _router;
  static late bool debugLogDiagnostics;
  static GoRouter configure({
    required Module appModule,
    String initialLocation = '/',
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
    _router = GoRouter(
      routes: appModule.configureRoutes(Injector()),
      initialLocation: initialLocation,
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
    return _router;
  }
}
