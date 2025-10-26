import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/core/bind.dart';
import 'package:go_router_modular/src/internal/asserts/go_router_modular_configure_assert.dart';
import 'package:go_router_modular/src/internal/setup.dart';
import 'package:go_router_modular/src/core/module.dart';
import 'package:go_router_modular/src/routing/page_transition_enum.dart';

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
  /// Returns the type of transition configured in [configure].
  /// Throws an exception if [configure] has not been called yet.
  static PageTransition get getDefaultPageTransition {
    assert(_pageTansition != null, 'Add GoRouterModular.configure in main.dart');
    return _pageTansition!;
  }

  /// Private router instance.
  static GoRouter? _router;

  /// Default page transition type.
  static PageTransition? _pageTansition;

  /// Retrieves a registered dependency from the injection container.
  ///
  /// - [T]: The type of the dependency to return.
  /// - **Example**:
  ///   ```dart
  ///   final myService = GoRouterModular.get<MyService>();
  ///   ```
  static T get<T>({String? key}) {
    // Usar o injector contextual para respeitar o isolamento de módulos
    try {
      final contextualInjector = InjectionManager.instance.getContextualInjector();
      return contextualInjector.get<T>(key: key);
    } catch (e) {
      // Fallback para o sistema antigo se necessário
      return Bind.get<T>(key: key);
    }
  }

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
    PageTransition pageTransition = PageTransition.fade,
    int delayDisposeMilliseconds = 1000,
    bool debugLogEventBus = false,
    bool autoDisposeEventsBus = true,
  }) async {
    if (_router != null) return _router!;
    _pageTansition = pageTransition;

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
    _router = GoRouter(
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

  static Future<void> awaitCompleteRoute() async {
    if (_stackCompleters.isEmpty) return;
    await _stackCompleters.first.future;
  }
}
