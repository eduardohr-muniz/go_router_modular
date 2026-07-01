import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/src/bootstrap/modular_configure.dart';
import 'package:go_router_modular/src/ui/async_navigation_helper.dart';

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
  @Deprecated('Use Modular.pathParamOf(context, param) instead. Will be removed in a future major release.')
  String? getPathParam(String param) {
    return Modular.pathParamOf(this, param);
  }

  /// Returns the current route path.
  ///
  /// - **Returns**: The path as a `String`, or `null` if not defined.
  /// - **Example**:
  ///   ```dart
  ///   final path = context.getPath;
  ///   print(path); // Prints the current path
  ///   ```
  @Deprecated('Use Modular.currentPathOf(context) instead. Will be removed in a future major release.')
  String? get getPath {
    return Modular.currentPathOf(this);
  }

  /// Returns the current router state.
  ///
  /// - **Returns**: An instance of [GoRouterState].
  /// - **Example**:
  ///   ```dart
  ///   final state = context.state;
  ///   print(state.location); // Prints the current location
  ///   ```
  @Deprecated('Use Modular.routerStateOf(context) instead. Will be removed in a future major release.')
  GoRouterState get state {
    return Modular.routerStateOf(this);
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
    return AsyncNavigationHelper.run(
      this,
      routeName,
      navigate: (router) => router.goNamed(
        routeName,
        pathParameters: pathParameters,
        queryParameters: queryParameters,
        extra: extra,
      ),
      onComplete: onComplete,
    );
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
    return AsyncNavigationHelper.run(
      this,
      routeName,
      navigate: (router) => router.go(
        routeName,
        extra: extra,
      ),
      onComplete: onComplete,
    );
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
    return AsyncNavigationHelper.run(
      this,
      routeName,
      navigate: (router) => router.push(
        routeName,
        extra: extra,
      ),
      onComplete: onComplete,
    );
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
    return AsyncNavigationHelper.run(
      this,
      routeName,
      navigate: (router) => router.pushNamed(
        routeName,
        pathParameters: pathParameters,
        queryParameters: queryParameters,
        extra: extra,
      ),
      onComplete: onComplete,
    );
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
    return AsyncNavigationHelper.run(
      this,
      routeName,
      navigate: (router) => router.pushReplacement(
        routeName,
        extra: extra,
      ),
      onComplete: onComplete,
    );
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
    return AsyncNavigationHelper.run(
      this,
      routeName,
      navigate: (router) => router.pushReplacementNamed(
        routeName,
        pathParameters: pathParameters,
        queryParameters: queryParameters,
        extra: extra,
      ),
      onComplete: onComplete,
    );
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
    return AsyncNavigationHelper.run(
      this,
      routeName,
      navigate: (router) => router.replace(
        routeName,
        extra: extra,
      ),
      onComplete: onComplete,
    );
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
    return AsyncNavigationHelper.run(
      this,
      routeName,
      navigate: (router) => router.replaceNamed(
        routeName,
        pathParameters: pathParameters,
        queryParameters: queryParameters,
        extra: extra,
      ),
      onComplete: onComplete,
    );
  }

  void popUntil(String location) {
    final router = GoRouter.of(this);

    while (router.canPop()) {
      final match = router.routerDelegate.currentConfiguration.last;
      if (match.matchedLocation == location) {
        break;
      }
      router.pop();
    }
  }

  void popUntilNamed(String routeName) {
    final router = GoRouter.of(this);

    while (router.canPop()) {
      final match = router.routerDelegate.currentConfiguration.last;
      if (match.route.name == routeName) {
        break;
      }
      router.pop();
    }
  }
}
