class ModuleAssert {
  ModuleAssert._();

  static String childRouteAssert(String moduleName) {
    return '''
Module $moduleName must HAVE a ChildRoute with path "/" because it serves as the parent route for the module.

✅ CORRECT - Non-shell module with proper entry point:
```dart
class MyModule extends Module {
  @override
  List<ModularRoute> get routes {
    return [
      ChildRoute(
        '/', // ✅ Required entry point for non-shell modules
        child: (context, state) => MyPage(),
      ),
      ChildRoute(
        '/details',
        child: (context, state) => DetailsPage(),
      ),
    ];
  }
}
```

❌ INCORRECT - Missing entry point:
```dart
class MyModule extends Module {
  @override
  List<ModularRoute> get routes {
    return [
      ChildRoute(
        '/home', // ❌ Missing "/" entry point
        child: (context, state) => HomePage(),
      ),
      ChildRoute(
        '/details',
        child: (context, state) => DetailsPage(),
      ),
    ];
  }
}
```

The ChildRoute with path "/" serves as the entry point for the module.
''';
  }

  static String shellRouteAssert(String moduleName) {
    return '''
Shell module $moduleName cannot have a ChildRoute with path "/" - Shell modules only serve as wrappers for other routes.

✅ CORRECT - Shell module with proper structure:
```dart
class MyShellModule extends Module {
  @override
  List<ModularRoute> get routes {
    return [
      ShellModularRoute(
        builder: (context, state, child) => Scaffold(
          body: Row(
            children: [
              NavigationRail(),
              Expanded(child: child),
            ],
          ),
        ),
        routes: [
          ChildRoute(
            '/dashboard', // ✅ Use specific paths, not "/"
            child: (context, state) => DashboardPage(),
          ),
          ChildRoute(
            '/profile',
            child: (context, state) => ProfilePage(),
          ),
        ],
      ),
    ];
  }
}
```

❌ INCORRECT - Shell module with "/" entry point:
```dart
class MyShellModule extends Module {
  @override
  List<ModularRoute> get routes {
    return [
      ShellModularRoute(
        builder: (context, state, child) => Scaffold(
          body: Row(
            children: [
              NavigationRail(),
              Expanded(child: child),
            ],
          ),
        ),
        routes: [
          ChildRoute(
            '/', // ❌ Shell modules cannot have "/" entry point
            child: (context, state) => DashboardPage(),
          ),
          ChildRoute(
            '/profile',
            child: (context, state) => ProfilePage(),
          ),
        ],
      ),
    ];
  }
}
```

Shell modules are wrappers that provide layout structure for their child routes.
''';
  }
}
