import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/src/core/bind/bind.dart';
import 'package:go_router_modular/src/internal/asserts/go_router_modular_configure_assert.dart';
import 'package:go_router_modular/src/internal/setup.dart';
import 'package:go_router_modular/src/core/module/module.dart';
import 'package:go_transitions/go_transitions.dart';

/// Alias to simplify the use of GoRouterModular.
typedef Modular = GoRouterModular;

late GlobalKey<NavigatorState> modularNavigatorKey;

/// Main class to manage modular routing using GoRouter.
class GoRouterModular {
  /// Private constructor to prevent direct instantiation.
  GoRouterModular._();

  /// Current router configuration.
  ///
  /// Returns the configured [GoRouter] instance.
  /// Throws an exception if [configure] has not been called yet.
  static GoRouter get routerConfig {
    assert(_router != null, GoRouterModularConfigureAssert.goRouterModularConfigureAssert());
    return _router!;
  }

  static GoRouter goRouter(BuildContext context) {
    return GoRouter.of(context);
  }

  /// Default page transition configuration.
  ///
  /// Returns the transition configured in [configure].
  /// Returns null if [configure] has not been called yet or no default transition was set.
  static GoTransition? get getDefaultTransition {
    return _defaultTransition;
  }

  /// Private router instance.
  static GoRouter? _router;

  /// Router derived from [routerConfig] via [copyRouterConfig]/`copyWith`.
  ///
  /// Memoized so that successive widget rebuilds reuse the same [GoRouter]
  /// instance and the navigation state is preserved.
  static GoRouter? _derivedRouter;

  /// Parameters captured during [configure], used to rebuild the router with
  /// overrides through [copyRouterConfig].
  static _ModularRouterParams? _params;

  /// Default page transition.
  static GoTransition? _defaultTransition;

  /// Retrieves a registered dependency from the injection container.
  ///
  /// - [T]: The type of the dependency to return.
  /// - **Example**:
  ///   ```dart
  ///   final myService = GoRouterModular.get<MyService>();
  ///   ```
  static T get<T>({String? key}) => Bind.get<T>(key: key);

  /// Tries to retrieve a registered dependency without throwing an exception.
  ///
  /// - [T]: The type of the dependency to return.
  /// - **Returns**: The dependency instance if found, `null` otherwise.
  /// - **Example**:
  ///   ```dart
  ///   final myService = GoRouterModular.tryGet<MyService>();
  ///   if (myService != null) {
  ///     // Use myService
  ///   }
  ///   ```
  static T? tryGet<T>({String? key}) => Bind.tryGet<T>(key: key);

  /// Checks if a dependency is registered without throwing an exception.
  ///
  /// - [T]: The type of the dependency to check.
  /// - **Returns**: `true` if the dependency is registered, `false` otherwise.
  /// - **Example**:
  ///   ```dart
  ///   if (GoRouterModular.isRegistered<MyService>()) {
  ///     final myService = GoRouterModular.get<MyService>();
  ///   }
  ///   ```
  static bool isRegistered<T>({String? key}) => Bind.isRegistered<T>(key: key);

  /// Returns the current route path based on the [BuildContext].
  ///
  /// - **Parameters**:
  ///   - `context`: The current [BuildContext].
  /// - **Returns**: A `String` representing the current route path.
  /// - **Example**:
  ///   ```dart
  ///   final path = GoRouterModular.getCurrentPathOf(context);
  ///   print(path); // Prints the current path
  ///   ```
  static String getCurrentPathOf(BuildContext context) => GoRouterState.of(context).path ?? '';

  /// Returns the current router state based on the [BuildContext].
  ///
  /// - **Parameters**:
  ///   - `context`: The current [BuildContext].
  /// - **Returns**: An instance of [GoRouterState].
  static GoRouterState stateOf(BuildContext context) => GoRouterState.of(context);

  /// Configures the modular router with the provided modules and options.
  ///
  /// This method initializes the router based on the root module and additional options.
  ///
  /// - **Parameters**:
  ///   - `appModule`: The root module configuring the routes.
  ///   - `initialRoute`: The application's initial route.
  ///   - `debugLogDiagnostics`: Enables or disables diagnostic logs.
  ///   - `extraCodec`: Optional codec for encoding/decoding extras.
  ///   - `onException`: Callback to handle exceptions during routing.
  ///   - `errorPageBuilder`: Builder for error pages.
  ///   - `errorBuilder`: Builder for error widgets.
  ///   - `redirect`: Function for dynamic redirections.
  ///   - `refreshListenable`: Listenable to trigger router refreshes.
  ///   - `redirectLimit`: Limit for consecutive redirections.
  ///   - `routerNeglect`: Ignores URL changes during imperative navigations.
  ///   - `overridePlatformDefaultLocation`: Overrides the default browser location behavior.
  ///   - `initialExtra`: Initial extra data for the starting route.
  ///   - `observers`: List of navigation observers.
  ///   - `debugLogDiagnosticsGoRouter`: Enables or disables GoRouter diagnostic logs.
  ///   - `navigatorKey`: Global navigator key.
  ///   - `restorationScopeId`: Identifier for restoration scope.
  ///   - `requestFocus`: Defines whether focus will be requested automatically.
  ///   - `defaultTransition`: Configures the default page transition.
  ///   - `defaultTransitionDuration`: Configures the default duration for all transitions.
  ///   - `defaultTransitionCurve`: Configures the default curve for all transitions.
  ///   - `delayDisposeMilliseconds`: Time to wait before disposing a module in milliseconds.
  ///
  /// - **Returns**: A future instance of [GoRouter].
  ///
  /// - **Example**:
  ///   ```dart
  ///   final router = await GoRouterModular.configure(
  ///     appModule: AppModule(),
  ///     initialRoute: '/',
  ///   );
  ///   ```
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
    GoTransition? defaultTransition,
    Duration? defaultTransitionDuration,
    int delayDisposeMilliseconds = 1000,
    bool debugLogEventBus = false,
    bool autoDisposeEventsBus = true,
  }) async {
    if (_router != null) return _router!;
    _defaultTransition = defaultTransition;

    // Afeta GoTransition.defaultDuration usada por rotas sem duração explícita e por
    // [StatefulShellModularRoute] quando [transitionDuration] é omitido.
    if (defaultTransitionDuration != null) {
      GoTransition.defaultDuration = defaultTransitionDuration;
    }

    GoRouter.optionURLReflectsImperativeAPIs = true;

    SetupModular.instance.setDebugModel(
      SetupModel(
        debugLogEventBus: debugLogEventBus,
        debugLogGoRouter: debugLogDiagnosticsGoRouter,
        debugLogGoRouterModular: debugLogDiagnostics,
        autoDisposeEvents: autoDisposeEventsBus,
      ),
    );

    assert(
      delayDisposeMilliseconds > 500,
      '❌ delayDisposeMilliseconds must be at least 500ms - Check `go_router_modular main.dart`.',
    );
    modularNavigatorKey = navigatorKey ?? GlobalKey<NavigatorState>();

    _params = _ModularRouterParams(
      routes: appModule.configureRoutes(topLevel: true),
      initialLocation: initialRoute,
      debugLogDiagnostics: debugLogDiagnosticsGoRouter,
      errorBuilder: errorBuilder,
      errorPageBuilder: errorPageBuilder,
      extraCodec: extraCodec,
      initialExtra: initialExtra,
      navigatorKey: modularNavigatorKey,
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

    _router = _params!.build();
    debugLogDiagnostics = debugLogDiagnostics;
    return _router!;
  }

  /// Builds a [GoRouter] reusing the configuration provided to [configure],
  /// overriding only the parameters you pass.
  ///
  /// Prefer the `Modular.routerConfig.copyWith(...)` extension, which forwards
  /// to this method. Useful to tweak view-level options (for example
  /// [observers]) directly at `MaterialApp.router` without repeating the whole
  /// [configure] call:
  ///
  /// ```dart
  /// MaterialApp.router(
  ///   routerConfig: Modular.routerConfig.copyWith(
  ///     observers: [MyNavigatorObserver()],
  ///   ),
  /// );
  /// ```
  ///
  /// The derived router is memoized: the first call builds it and subsequent
  /// calls return the same instance, so widget rebuilds keep the navigation
  /// state intact.
  static GoRouter copyRouterConfig({
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
    assert(_params != null, GoRouterModularConfigureAssert.goRouterModularConfigureAssert());
    if (_derivedRouter != null) return _derivedRouter!;

    _derivedRouter = _params!
        .copyWith(
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
        )
        .build();
    return _derivedRouter!;
  }
}

/// Immutable snapshot of the parameters used to build the modular [GoRouter].
///
/// Captured during [GoRouterModular.configure] so the router can be rebuilt
/// with overrides via [GoRouterModular.copyRouterConfig].
class _ModularRouterParams {
  const _ModularRouterParams({
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

  _ModularRouterParams copyWith({
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
    return _ModularRouterParams(
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

/// Adds a [copyWith] to the [GoRouter] returned by [GoRouterModular.routerConfig].
///
/// Lets you override modular routing options (for example [observers])
/// directly where the router is consumed, reusing everything else provided to
/// [GoRouterModular.configure].
extension ModularRouterConfigCopyWith on GoRouter {
  /// Returns a [GoRouter] reusing the modular configuration with the given
  /// overrides applied. See [GoRouterModular.copyRouterConfig].
  GoRouter copyWith({
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
    return GoRouterModular.copyRouterConfig(
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

class RouteWithCompleterService {
  const RouteWithCompleterService._();

  /// Map to store route completers.
  static final List<Completer> _stackCompleters = [];

  /// Completes the navigation for a specific route.
  ///
  /// - [route]: The route path to complete.
  static void setCompleteRoute(String route) {
    _stackCompleters.add(Completer<void>());
  }

  static Completer getLastCompleteRoute() {
    final completer = _stackCompleters.isNotEmpty ? _stackCompleters.removeLast() : Completer<void>();
    return completer;
  }

  /// Checks if any route completer exists.
  static bool hasRouteCompleter() {
    return _stackCompleters.isNotEmpty;
  }

  static Future<void> awaitCompleteRoute() async {
    if (_stackCompleters.isEmpty) return;
    await _stackCompleters.first.future;
  }
}
