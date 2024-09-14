import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/src/bind.dart';
import 'package:go_router_modular/src/module.dart';
import 'package:go_router_modular/src/page_transition_enum.dart';

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

  static PageTransition get getDefaultPageTransition {
    assert(_pageTansition != null, 'Add GoRouterModular.configure in main.dart');
    return _pageTansition!;
  }

  static GoRouter? _router;

  static bool? _debugLogDiagnostics;

  static PageTransition? _pageTansition;

  static T get<T>() => Bind.get<T>();

  static getCurrentPathOf(BuildContext context) => GoRouterState.of(context).path ?? '';

  static GoRouterState stateOf(BuildContext context) => GoRouterState.of(context);

  static Future<FutureOr<GoRouter>> configure({
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
    PageTransition pageTransition = PageTransition.fade,
  }) async {
    if (_router != null) return _router!;
    _pageTansition = pageTransition;
    _debugLogDiagnostics = debugLogDiagnostics;
    GoRouter.optionURLReflectsImperativeAPIs = true;
    _router = GoRouter(
      routes: appModule.configureRoutes(topLevel: true),
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

extension GoRouterExtension on BuildContext {
  String? getPathParam(String param) {
    return GoRouterState.of(this).pathParameters[param];
  }

  String? get getPath {
    return GoRouterState.of(this).path;
  }

  GoRouterState get state {
    return GoRouterState.of(this);
  }
}
