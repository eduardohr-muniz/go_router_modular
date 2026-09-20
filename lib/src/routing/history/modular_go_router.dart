import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/src/routing/history/browser_history.dart';
import 'package:go_router_modular/src/routing/history/modular_route_information_provider.dart';
import 'package:go_router_modular/src/routing/history/modular_router_delegate.dart';

/// go_router_modular's [GoRouter].
///
/// The same as a plain [GoRouter], with two swaps:
///
/// - [routerDelegate] is a [ModularRouterDelegate], which reports every
///   resolved navigation to `onNavigationSettled`, used to expire the
///   navigation references of modules that never became a page;
/// - with [syncBrowserHistory] on, [routeInformationProvider] is a
///   [ModularRouteInformationProvider], which keeps the browser history
///   mirrored on the page stack, so that browser back behaves like the back
///   button of every other platform.
///
/// Both substitutes are built in the constructor body and handed out by the
/// overridden getters, because [GoRouter] gives no way to inject them.
class ModularGoRouter extends GoRouter {
  ModularGoRouter({
    required List<RouteBase> routes,
    GoRouterRedirect? redirect,
    int redirectLimit = 5,
    Codec<Object?, Object?>? extraCodec,
    GoExceptionHandler? onException,
    GoRouterPageBuilder? errorPageBuilder,
    GoRouterWidgetBuilder? errorBuilder,
    Listenable? refreshListenable,
    bool routerNeglect = false,
    String? initialLocation,
    bool overridePlatformDefaultLocation = false,
    Object? initialExtra,
    List<NavigatorObserver>? observers,
    bool debugLogDiagnostics = false,
    GlobalKey<NavigatorState>? navigatorKey,
    String? restorationScopeId,
    bool requestFocus = true,
    this.syncBrowserHistory = true,
    void Function(RouteMatchList configuration)? onNavigationSettled,
  }) : super.routingConfig(
          routingConfig: _ConstantRoutingConfig(
            RoutingConfig(
              routes: routes,
              redirect: redirect ?? _noRedirect,
              redirectLimit: redirectLimit,
            ),
          ),
          extraCodec: extraCodec,
          onException: onException,
          errorPageBuilder: errorPageBuilder,
          errorBuilder: errorBuilder,
          // With the synced provider in place the refreshListenable is wired
          // to it instead, leaving the base provider without listeners.
          refreshListenable: syncBrowserHistory ? null : refreshListenable,
          routerNeglect: routerNeglect,
          initialLocation: initialLocation,
          overridePlatformDefaultLocation: overridePlatformDefaultLocation,
          initialExtra: initialExtra,
          observers: observers,
          debugLogDiagnostics: debugLogDiagnostics,
          navigatorKey: navigatorKey,
          restorationScopeId: restorationScopeId,
          requestFocus: requestFocus,
        ) {
    _delegate = ModularRouterDelegate(
      configuration: configuration,
      errorPageBuilder: errorPageBuilder,
      errorBuilder: errorBuilder,
      routerNeglect: routerNeglect,
      observers: <NavigatorObserver>[...observers ?? <NavigatorObserver>[]],
      restorationScopeId: restorationScopeId,
      requestFocus: requestFocus,
      onNavigationSettled: onNavigationSettled,
      builderWithNav: (BuildContext context, Widget child) => InheritedGoRouter(goRouter: this, child: child),
    );
    if (!syncBrowserHistory) return;
    final base = super.routeInformationProvider;
    final baseState = base.value.state;
    _syncedProvider = ModularRouteInformationProvider(
      initialLocation: base.value.uri.toString(),
      initialExtra: baseState is RouteInformationState ? baseState.extra : null,
      refreshListenable: refreshListenable,
      routerNeglect: routerNeglect,
      currentConfiguration: () => routerDelegate.currentConfiguration,
      history: createBrowserHistory(),
    );
  }

  /// Whether the browser history is kept in sync with the page stack.
  final bool syncBrowserHistory;

  @override
  void dispose() {
    // `GoRouter.dispose` calls the overridden getters, so it only reaches the
    // substitutes. The delegate and provider the base constructor built were
    // left unused and have to be disposed here.
    super.routerDelegate.dispose();
    final baseProvider = super.routeInformationProvider;
    if (!identical(routeInformationProvider, baseProvider)) baseProvider.dispose();
    super.dispose();
  }

  ModularRouteInformationProvider? _syncedProvider;
  late final ModularRouterDelegate _delegate;

  @override
  GoRouterDelegate get routerDelegate => _delegate;

  @override
  GoRouteInformationProvider get routeInformationProvider => _syncedProvider ?? super.routeInformationProvider;

  static FutureOr<String?> _noRedirect(BuildContext context, GoRouterState state) => null;
}

/// Immutable route configuration, equivalent to go_router's private
/// `_ConstantRoutingConfig`.
class _ConstantRoutingConfig extends ValueListenable<RoutingConfig> {
  const _ConstantRoutingConfig(this.value);

  @override
  final RoutingConfig value;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}
