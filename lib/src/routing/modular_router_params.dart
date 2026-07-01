import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Snapshot imutável dos parâmetros usados para construir o [GoRouter] modular.
///
/// Capturado em `Modular.configure` para que o router possa ser
/// reconstruído com sobrescritas via `Modular.copyRouterConfig`.
/// É interno ao pacote (não exportado pelo barril público).
class ModularRouterParams {
  const ModularRouterParams({
    required this.routes,
    required this.initialLocation,
    required this.debugLogDiagnostics,
    required this.errorBuilder,
    required this.errorPageBuilder,
    required this.extraCodec,
    required this.initialExtra,
    required this.navigatorKey,
    required this.observers,
    required this.onException,
    required this.overridePlatformDefaultLocation,
    required this.redirect,
    required this.refreshListenable,
    required this.redirectLimit,
    required this.requestFocus,
    required this.restorationScopeId,
    required this.routerNeglect,
  });

  final List<RouteBase> routes;
  final String initialLocation;
  final bool debugLogDiagnostics;
  final Widget Function(BuildContext, GoRouterState)? errorBuilder;
  final Page<dynamic> Function(BuildContext, GoRouterState)? errorPageBuilder;
  final Codec<Object?, Object?>? extraCodec;
  final Object? initialExtra;
  final GlobalKey<NavigatorState> navigatorKey;
  final List<NavigatorObserver>? observers;
  final void Function(BuildContext, GoRouterState, GoRouter)? onException;
  final bool overridePlatformDefaultLocation;
  final FutureOr<String?> Function(BuildContext, GoRouterState)? redirect;
  final Listenable? refreshListenable;
  final int redirectLimit;
  final bool requestFocus;
  final String? restorationScopeId;
  final bool routerNeglect;

  ModularRouterParams copyWith({
    List<RouteBase>? routes,
    String? initialLocation,
    bool? debugLogDiagnostics,
    Widget Function(BuildContext, GoRouterState)? errorBuilder,
    Page<dynamic> Function(BuildContext, GoRouterState)? errorPageBuilder,
    Codec<Object?, Object?>? extraCodec,
    Object? initialExtra,
    GlobalKey<NavigatorState>? navigatorKey,
    List<NavigatorObserver>? observers,
    void Function(BuildContext, GoRouterState, GoRouter)? onException,
    bool? overridePlatformDefaultLocation,
    FutureOr<String?> Function(BuildContext, GoRouterState)? redirect,
    Listenable? refreshListenable,
    int? redirectLimit,
    bool? requestFocus,
    String? restorationScopeId,
    bool? routerNeglect,
  }) {
    return ModularRouterParams(
      routes: routes ?? this.routes,
      initialLocation: initialLocation ?? this.initialLocation,
      debugLogDiagnostics: debugLogDiagnostics ?? this.debugLogDiagnostics,
      errorBuilder: errorBuilder ?? this.errorBuilder,
      errorPageBuilder: errorPageBuilder ?? this.errorPageBuilder,
      extraCodec: extraCodec ?? this.extraCodec,
      initialExtra: initialExtra ?? this.initialExtra,
      navigatorKey: navigatorKey ?? this.navigatorKey,
      observers: observers ?? this.observers,
      onException: onException ?? this.onException,
      overridePlatformDefaultLocation: overridePlatformDefaultLocation ?? this.overridePlatformDefaultLocation,
      redirect: redirect ?? this.redirect,
      refreshListenable: refreshListenable ?? this.refreshListenable,
      redirectLimit: redirectLimit ?? this.redirectLimit,
      requestFocus: requestFocus ?? this.requestFocus,
      restorationScopeId: restorationScopeId ?? this.restorationScopeId,
      routerNeglect: routerNeglect ?? this.routerNeglect,
    );
  }

  GoRouter build() {
    return GoRouter(
      routes: routes,
      initialLocation: initialLocation,
      debugLogDiagnostics: debugLogDiagnostics,
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
  }
}
