import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/src/core/bind/bind.dart';
import 'package:go_router_modular/src/core/module/module.dart';
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
    assert(_router != null, 'Add GoRouterModular.configure in main.dart');
    return _router!;
  }

  /// Indicates whether GoRouter diagnostic logs are enabled.
  ///
  /// Returns `true` if logs are enabled. Throws an exception if
  /// [configure] has not been called yet.
  static bool get debugLogDiagnostics {
    assert(_debugLogDiagnostics != null, 'Add GoRouterModular.configure in main.dart');
    return _debugLogDiagnostics!;
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

  /// Flag for enabling diagnostic logs.
  static bool? _debugLogDiagnostics;

  /// Default page transition.
  static GoTransition? _defaultTransition;

  /// Retrieves a registered dependency from the injection container.
  ///
  /// - [T]: The type of the dependency to return.
  /// - **Example**:
  ///   ```dart
  ///   final myService = GoRouterModular.get<MyService>();
  ///   ```
  static T get<T>() => Bind.get<T>();

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
  ///   - `pageTransition`: Configures the default page transition.
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
    int delayDisposeMilliseconds = 1000,
  }) async {
    if (_router != null) return _router!;
    _defaultTransition = defaultTransition;
    _debugLogDiagnostics = debugLogDiagnostics;
    GoRouter.optionURLReflectsImperativeAPIs = true;

    assert(
      delayDisposeMilliseconds > 500,
      '❌ delayDisposeMilliseconds must be at least 500ms - Check `go_router_modular main.dart`.',
    );

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
}

/// Extension to add functionalities to [BuildContext] for GoRouter.
extension GoRouterExtension on BuildContext {
  /// Returns the value of a URL parameter by its name.
  ///
  /// - **Parameters**:
  ///   - `param`: The name of the parameter to retrieve.
  /// - **Returns**: The parameter value as a `String`, or `null` if not found.
  /// - **Example**:
  ///   ```dart
  ///   final userId = context.getPathParam('userId');
  ///   print(userId);
  ///   ```
  String? getPathParam(String param) {
    return GoRouterState.of(this).pathParameters[param];
  }

  /// Returns the current route path.
  ///
  /// - **Returns**: The path as a `String`, or `null` if not defined.
  /// - **Example**:
  ///   ```dart
  ///   final path = context.getPath;
  ///   print(path); // Prints the current path
  ///   ```
  String? get getPath {
    return GoRouterState.of(this).path;
  }

  /// Returns the current router state.
  ///
  /// - **Returns**: An instance of [GoRouterState].
  /// - **Example**:
  ///   ```dart
  ///   final state = context.state;
  ///   print(state.location); // Prints the current location
  ///   ```
  GoRouterState get state {
    return GoRouterState.of(this);
  }

  /// Navega para a rota [routeName] e retorna um [Future]
  /// que completa quando a nova página for construída.
  /// This method is similar to [goAsync] but uses a named route instead of a path
  /// to navigate.
  /// - [routeName]: The name of the route to navigate to.
  /// - [pathParameters]: Optional path parameters to include in the route.
  /// - [queryParameters]: Optional query parameters to include in the route.
  /// - [extra]: Optional extra data to pass to the route.
  /// - [onComplete]: Optional callback to execute when the navigation completes.
  /// - **Returns**: A [Future] that completes when the navigation is done.
  /// - **Example**:
  ///   ```dart
  ///   await context.goNamedAsync(
  ///     'userProfile',
  ///     pathParameters: {'userId': '123'},
  ///     queryParameters: {'ref': 'home'},
  ///     extra: {'someData': 'value'},
  ///     onComplete: () {
  ///       print('Navigation completed!');
  ///     },
  ///   );
  Future<void> goNamedAsync(
    String routeName, {
    Map<String, String> pathParameters = const {},
    Map<String, String> queryParameters = const {},
    Object? extra,
    VoidCallback? onComplete,
  }) {
    RouteWithCompleterService.setCompleteRoute(routeName);

    GoRouter.of(this).goNamed(
      routeName,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );

    return RouteWithCompleterService.getLastCompleteRoute().future.then((_) {
      onComplete?.call();
    });
  }

  /// Navega para a rota [routeName] e retorna um [Future]
  /// que completa quando a nova página for construída.
  /// This method is similar to [goNamedAsync] but uses the route path instead of a named route
  /// to navigate.
  /// - [routeName]: The path of the route to navigate to.
  /// - [extra]: Optional extra data to pass to the route.
  /// - [onComplete]: Optional callback to execute when the navigation completes.
  /// - **Returns**: A [Future] that completes when the navigation is done.
  /// - **Example**:
  ///  ```dart
  ///  await context.goAsync(
  ///   '/user',
  ///   extra: {'someData': 'value'},
  ///   onComplete: () {
  ///     print('Navigation completed!');
  ///   },
  /// });
  Future<void> goAsync(
    String routeName, {
    Object? extra,
    VoidCallback? onComplete,
  }) {
    RouteWithCompleterService.setCompleteRoute(routeName);

    GoRouter.of(this).go(
      routeName,
      extra: extra,
    );

    return RouteWithCompleterService.getLastCompleteRoute().future.then((_) {
      onComplete?.call();
    });
  }

  /// Pushes a new route onto the navigation stack and returns a [Future]
  /// that completes when the new page is built.
  /// - [routeName]: The name of the route to push.
  /// - [extra]: Optional extra data to pass to the route.
  /// - [onComplete]: Optional callback to execute when the navigation completes.
  /// - **Returns**: A [Future] that completes when the navigation is done.
  /// - **Example**:
  ///  ```dart
  /// await context.pushAsync(
  ///  '/user',
  ///   extra: {'someData': 'value'},
  ///   onComplete: () {
  ///     print('Navigation completed!');
  ///   },
  /// });
  Future<void> pushAsync(
    String routeName, {
    Object? extra,
    VoidCallback? onComplete,
  }) {
    RouteWithCompleterService.setCompleteRoute(routeName);

    GoRouter.of(this).push(
      routeName,
      extra: extra,
    );

    return RouteWithCompleterService.getLastCompleteRoute().future.then((_) {
      onComplete?.call();
    });
  }

  /// Pushes a named route onto the navigation stack and returns a [Future]
  /// that completes when the new page is built.
  /// - [routeName]: The name of the route to push.
  /// - [pathParameters]: Optional path parameters to include in the route.
  /// - [queryParameters]: Optional query parameters to include in the route.
  /// - [extra]: Optional extra data to pass to the route.
  /// - [onComplete]: Optional callback to execute when the navigation completes.
  /// - **Returns**: A [Future] that completes when the navigation is done.
  /// - **Example**:
  ///  ```dart
  /// await context.pushNamedAsync(
  ///  'userProfile',
  ///   pathParameters: {'userId': '123'},
  ///   queryParameters: {'ref': 'home'},
  ///   extra: {'someData': 'value'},
  ///   onComplete: () {
  ///     print('Navigation completed!');
  ///   },
  /// });
  Future<void> pushNamedAsync(
    String routeName, {
    Map<String, String> pathParameters = const {},
    Map<String, String> queryParameters = const {},
    Object? extra,
    VoidCallback? onComplete,
  }) {
    RouteWithCompleterService.setCompleteRoute(routeName);

    GoRouter.of(this).pushNamed(
      routeName,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );

    return RouteWithCompleterService.getLastCompleteRoute().future.then((_) {
      onComplete?.call();
    });
  }

  /// Pushes a new route onto the navigation stack and replaces the current route.
  /// Returns a [Future] that completes when the new page is built.
  /// - [routeName]: The name of the route to push and replace.
  /// - [extra]: Optional extra data to pass to the route.
  /// - [onComplete]: Optional callback to execute when the navigation completes.
  /// - **Returns**: A [Future] that completes when the navigation is done.
  /// - **Example**:
  /// ```dart
  /// await context.pushReplacementAsync(
  ///  '/user',
  ///   extra: {'someData': 'value'},
  ///   onComplete: () {
  ///     print('Navigation completed!');
  ///   },
  /// });
  Future<void> pushReplacementAsync(
    String routeName, {
    Object? extra,
    VoidCallback? onComplete,
  }) {
    RouteWithCompleterService.setCompleteRoute(routeName);

    GoRouter.of(this).pushReplacement(
      routeName,
      extra: extra,
    );

    return RouteWithCompleterService.getLastCompleteRoute().future.then((_) {
      onComplete?.call();
    });
  }

  /// Pushes a named route onto the navigation stack and replaces the current route.
  /// Returns a [Future] that completes when the new page is built.
  /// - [routeName]: The name of the route to push and replace.
  /// - [pathParameters]: Optional path parameters to include in the route.
  /// - [queryParameters]: Optional query parameters to include in the route.
  /// - [extra]: Optional extra data to pass to the route.
  /// - [onComplete]: Optional callback to execute when the navigation completes.
  /// - **Returns**: A [Future] that completes when the navigation is done.
  /// - **Example**:
  /// ```dart
  /// await context.pushReplacementNamedAsync(
  ///   'userProfile',
  ///   pathParameters: {'userId': '123'},
  ///   queryParameters: {'ref': 'home'},
  ///   extra: {'someData': 'value'},
  ///   onComplete: () {
  ///     print('Navigation completed!');
  ///   },
  /// });
  Future<void> pushReplacementNamedAsync(
    String routeName, {
    Map<String, String> pathParameters = const {},
    Map<String, String> queryParameters = const {},
    Object? extra,
    VoidCallback? onComplete,
  }) {
    RouteWithCompleterService.setCompleteRoute(routeName);

    GoRouter.of(this).pushReplacementNamed(
      routeName,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );

    return RouteWithCompleterService.getLastCompleteRoute().future.then((_) {
      onComplete?.call();
    });
  }

  /// Replaces the current route with a new route and returns a [Future]
  /// that completes when the new page is built.
  /// - [routeName]: The name of the route to replace with.
  /// - [extra]: Optional extra data to pass to the route.
  /// - [onComplete]: Optional callback to execute when the navigation completes.
  /// - **Returns**: A [Future] that completes when the navigation is done.
  /// - **Example**:
  /// ```dart
  /// await context.replaceAsync(
  ///   '/user',
  ///   extra: {'someData': 'value'},
  ///   onComplete: () {
  ///     print('Navigation completed!');
  ///   },
  /// });
  Future<void> replaceAsync(
    String routeName, {
    Object? extra,
    VoidCallback? onComplete,
  }) {
    RouteWithCompleterService.setCompleteRoute(routeName);

    GoRouter.of(this).replace(
      routeName,
      extra: extra,
    );

    return RouteWithCompleterService.getLastCompleteRoute().future.then((_) {
      onComplete?.call();
    });
  }

  /// Replaces the current route with a named route and returns a [Future]
  /// that completes when the new page is built.
  /// - [routeName]: The name of the route to replace with.
  /// - [pathParameters]: Optional path parameters to include in the route.
  /// - [queryParameters]: Optional query parameters to include in the route.
  /// - [extra]: Optional extra data to pass to the route.
  /// - [onComplete]: Optional callback to execute when the navigation completes.
  /// - **Returns**: A [Future] that completes when the navigation is done.
  /// - **Example**:
  /// ```dart
  /// await context.replaceNamedAsync(
  ///  'userProfile',
  ///   pathParameters: {'userId': '123'},
  ///   queryParameters: {'ref': 'home'},
  ///   extra: {'someData': 'value'},
  ///   onComplete: () {
  ///     print('Navigation completed!');
  ///   },
  /// });
  Future<void> replaceNamedAsync(
    String routeName, {
    Map<String, String> pathParameters = const {},
    Map<String, String> queryParameters = const {},
    Object? extra,
    VoidCallback? onComplete,
  }) {
    RouteWithCompleterService.setCompleteRoute(routeName);

    GoRouter.of(this).replaceNamed(
      routeName,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );

    return RouteWithCompleterService.getLastCompleteRoute().future.then((_) {
      onComplete?.call();
    });
  }
}
