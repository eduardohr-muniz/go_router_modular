import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/src/di/bind.dart';
import 'package:go_router_modular/src/routing/guards/guard_resolver.dart';
import 'package:go_router_modular/src/routing/guards/modular_guard.dart';
import 'package:go_router_modular/src/routing/modular_router_params.dart';
import 'package:go_router_modular/src/routing/modular_router_runtime.dart';
import 'package:go_router_modular/src/di/injection_manager.dart';
import 'package:go_router_modular/src/shared/asserts/go_router_modular_configure_assert.dart';
import 'package:go_router_modular/src/shared/setup.dart';
import 'package:go_router_modular/src/module/module.dart';
import 'package:go_router_modular/src/routing/route_builder.dart';
import 'package:go_transitions/go_transitions.dart';

/// Alias to simplify the use of GoRouterModular.
typedef Modular = GoRouterModular;

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
    return modularDefaultTransition;
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
  static ModularRouterParams? _params;

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

  /// Returns the current [GoRouterState] based on the [BuildContext].
  ///
  /// - **Parameters**:
  ///   - `context`: The current [BuildContext].
  /// - **Returns**: An instance of [GoRouterState].
  /// - **Example**:
  ///   ```dart
  ///   final routerState = GoRouterModular.routerStateOf(context);
  ///   print(routerState.uri);
  ///   ```
  static GoRouterState routerStateOf(BuildContext context) => GoRouterState.of(context);

  /// Returns the current route path based on the [BuildContext].
  ///
  /// - **Parameters**:
  ///   - `context`: The current [BuildContext].
  /// - **Returns**: The current route path as a `String`, or `null` if not defined.
  /// - **Example**:
  ///   ```dart
  ///   final path = GoRouterModular.currentPathOf(context);
  ///   print(path); // Prints the current path
  ///   ```
  static String? currentPathOf(BuildContext context) => GoRouterState.of(context).path;

  /// Returns the value of a path parameter by its name based on the [BuildContext].
  ///
  /// - **Parameters**:
  ///   - `context`: The current [BuildContext].
  ///   - `name`: The name of the path parameter to retrieve.
  /// - **Returns**: The parameter value as a `String`, or `null` if not found.
  /// - **Example**:
  ///   ```dart
  ///   final userId = GoRouterModular.pathParamOf(context, 'userId');
  ///   ```
  static String? pathParamOf(BuildContext context, String name) => GoRouterState.of(context).pathParameters[name];

  /// Returns all path parameters of the current route based on the [BuildContext].
  ///
  /// - **Returns**: A read-only `Map<String, String>` of path parameters.
  static Map<String, String> pathParamsOf(BuildContext context) => GoRouterState.of(context).pathParameters;

  /// Returns all query parameters of the current route based on the [BuildContext].
  ///
  /// - **Returns**: A read-only `Map<String, String>` of query parameters.
  static Map<String, String> queryParamsOf(BuildContext context) => GoRouterState.of(context).uri.queryParameters;

  /// Returns the value of a query parameter by its name based on the [BuildContext].
  ///
  /// - **Parameters**:
  ///   - `context`: The current [BuildContext].
  ///   - `name`: The name of the query parameter to retrieve.
  /// - **Returns**: The parameter value as a `String`, or `null` if not found.
  /// - **Example**:
  ///   ```dart
  ///   final ref = GoRouterModular.queryParamOf(context, 'ref');
  ///   ```
  static String? queryParamOf(BuildContext context, String name) => GoRouterState.of(context).uri.queryParameters[name];

  /// Returns the current [Uri] of the route based on the [BuildContext].
  static Uri currentUriOf(BuildContext context) => GoRouterState.of(context).uri;

  /// Returns the current matched location of the route based on the [BuildContext].
  ///
  /// - **Returns**: The matched location as a `String`.
  static String currentLocationOf(BuildContext context) => GoRouterState.of(context).matchedLocation;

  /// Returns the typed `extra` data passed to the current route based on the [BuildContext].
  ///
  /// - **Type Parameters**:
  ///   - `T`: The expected type of the `extra` data.
  /// - **Returns**: The `extra` value cast to `T`, or `null` if absent or of a different type.
  /// - **Example**:
  ///   ```dart
  ///   final payload = GoRouterModular.extraOf<MyPayload>(context);
  ///   ```
  static T? extraOf<T>(BuildContext context) => GoRouterState.of(context).extra is T ? GoRouterState.of(context).extra as T : null;

  /// Returns the current route path based on the [BuildContext].
  ///
  /// Returns an empty string when no path is defined.
  @Deprecated('Use GoRouterModular.currentPathOf instead. Will be removed in a future major release.')
  static String getCurrentPathOf(BuildContext context) => currentPathOf(context) ?? '';

  /// Returns the current router state based on the [BuildContext].
  @Deprecated('Use GoRouterModular.routerStateOf instead. Will be removed in a future major release.')
  static GoRouterState stateOf(BuildContext context) => routerStateOf(context);

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
  ///   - `guards`: Global [ModularGuard] list applied to every navigation,
  ///     evaluated in short-circuit order ("first that blocks wins").
  ///   - `redirect`: **Deprecated** — use `guards`. Dynamic redirection function.
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
    List<ModularGuard> guards = const [],
    @Deprecated('Use guards: [GuardFn(...)] instead of redirect. '
        'Will be removed in v6.0.0')
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
    modularDefaultTransition = defaultTransition;

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

    // Composition root: registra o AppModule e constrói as rotas top-level.
    // Antes vivia em Module.configureRoutes (dupla responsabilidade); centralizar
    // aqui quebra o ciclo module ⇄ routing.
    InjectionManager.instance.registerAppModule(appModule);

    _params = ModularRouterParams(
      routes: ModularRouteBuilder(appModule).buildRoutes(topLevel: true),
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
      // Guards globais compõem com o redirect legado: [...guards, GuardFn(redirect)].
      redirect: resolveGuards(
        guards,
        // ignore: deprecated_member_use_from_same_package
        legacyRedirect: redirect,
      ),
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

