# 🧩 GoRouter Modular 💉

## Simplifying modules dependency injections

GoRouter Modular simplifies Flutter development by implementing a modular architecture.

It utilizes GoRouter for route management 🧩 and supports per-module dependency injection with auto-dispose 💉.

With GoRouter Modular, you can easily organize your application into independent modules, streamlining code development and maintenance while promoting component reuse and project scalability.

Simplify your Flutter app development and accelerate your workflow with GoRouter Modular.

# 🚀 Getting Started

1. Create an `app_module.dart`
2. Create an `app_widget.dart`
3. Configure your `main.dart`

> Below you will find examples of the structure and how each file should look.

### Project Structure Example

```css
📁 src
   📁 modules
      📁 home
         📄 home_controller.dart
         📄 home_page.dart
         📄 home_module.dart
   📄 app_module.dart
   📄 app_widget.dart
📄 main.dart
```

#### Main Example

```dart
import 'package:example/src/app_module.dart';
import 'package:example/src/app_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) usePathUrlStrategy();

  Modular.configure(appModule: AppModule(), initialRoute: "/"); // Configure Modular

  runApp(AppWidget()); // Define AppWidget
}
```

#### AppWidget Example

```dart
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override◊
  Widget build(BuildContext context) {
    return ModularApp.router( // Use ModularApp.router instead of MaterialApp.router
      title: 'Modular GoRoute Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}
```

#### AppModule Example

```dart
import 'package:go_router_modular/go_router_modular.dart';
import 'modules/home/home_module.dart';
import 'modules/shared/shared_module.dart';

class AppModule extends Module {
  @override
  FutureOr<List<Module>> imports() => [SharedModule()];

  @override
  FutureOr<List<Bind<Object>>> binds() => [
    Bind.singleton<AuthController>((i) => AuthController()), // Define global binds in app_module
  ];

  @override
  List<ModularRoute> get routes => [
    ModuleRoute("/", module: HomeModule()),
  ];
}
```

# 🎯 LOADER SYSTEM

GoRouter Modular includes a built-in loader system that automatically shows during module registration and can be controlled manually.

## Automatic Loader

The loader automatically appears when navigating between modules during the dependency injection process.

## Manual Loader Control

You can manually control the loader in your code:

```dart
// Show the loader
ModularLoader.show();

// Hide the loader
ModularLoader.hide();
```

## Custom Loader

You can customize the loader appearance by creating a `CustomModularLoader`:

```dart
class MyLoader extends CustomModularLoader {
  @override
  Color get backgroundColor => Colors.black87;

  @override
  Widget get child => const Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
      SizedBox(height: 16),
      Text(
        'Carregando...',
        style: TextStyle(color: Colors.white),
      ),
    ],
  );
}
```

Then use it in your `ModularApp.router`:

```dart
return ModularApp.router(
  customModularLoader: MyLoader(),
  title: 'My App',
);
```

## Local Custom Loader

### goAsync

The `goAsync` method is used to perform asynchronous navigation between pages. It allows you to `await` the navigation, making it possible to customize the loading indicator on your current page before navigating.

- **`onComplete` Callback:** You can provide an optional `onComplete` function that will be executed automatically after navigation is complete. This is useful for actions such as displaying messages, updating state, or logging events.

The same behavior applies to the following methods:

- goAsync
- goNamedAsync
- pushAsync
- pushNamedAsync
- pushReplacementAsync
- pushReplacementNamedAsync
- replaceAsync
- replaceNamedAsync

### Usage Example

````dart
```dart
ElevatedButton(
  onPressed: () async {
    setState(() => isLoading = true);

    /// Wait for the page to load
    await context.goAsync(
      '/user',
      onComplete: () { // optional
        print('Navigation completed');
      },
    );

    setState(() => isLoading = false);
  },
)

ElevatedButton(
  onPressed: () async {
    setState(() => isLoading = true);

    /// Wait for the page to load
    await context.goNamedAsync(
      '/user',
      onComplete: () { // optional
        print('Navigation completed');
      },
    );

    setState(() => isLoading = false);
  },
)
````

# 💉 DEPENDENCY INJECTION

⚠️ **Attention**

> Every dependency when placed in a **BIND** must be **TYPED** for correct operation.

Example:

```dart
✅  Bind.singleton<HomeController>((i) => HomeController())
✅  Bind.singleton((i) => HomeController())
```

### Injecting Dependencies

Create a class for your module and extend it from `Module`. Add your dependencies in the `binds()` method.

> As soon as there are no active routes for your module in the widget tree, the module will automatically dispose of the binds.

Example:

```dart
import 'package:go_router_modular/go_router_modular.dart';
import 'pages/home_page.dart';

class HomeModule extends Module {
  @override
  FutureOr<List<Bind<Object>>> binds() => [
    Bind.singleton<HomeController>((i) => HomeController()), // DEFINE BINDS FOR MODULE
    Bind.factory<IUserRepository>((i) => UserRepository()),
  ];

  @override
  List<ModularRoute> get routes => [
    ChildRoute('/', child: (context, state) => const HomePage()),
  ];
}
```

### Module Imports

You can import other modules to share their dependencies:

```dart
class UserModule extends Module {
  @override
  FutureOr<List<Module>> imports() => [SharedModule()];

  @override
  FutureOr<List<Bind<Object>>> binds() => [
    Bind.singleton<UserService>((i) => UserService()),
  ];
}
```

### Module Lifecycle

Modules have lifecycle methods for initialization and cleanup:

```dart
class AuthModule extends Module {
  bool _isInitialized = false;
  Timer? _authTimer;

  @override
  void initState(Injector i) {
    if (_isInitialized) return;

    // Initialize module resources
    _setupAuthListeners();
    _loadAuthConfig();
    _isInitialized = true;
  }

  @override
  void dispose() {
    // Clean up resources
    _authTimer?.cancel();
    _authTimer = null;
    _isInitialized = false;
  }
}
```

### Global Dependencies

Simply place your binds in your `AppModule`.

> Your `AppModule` will never be disposed of.

```dart
class AppModule extends Module {
  @override
  FutureOr<List<Bind<Object>>> binds() => [
    Bind.singleton<AuthController>((i) => AuthController()), // DEFINE GLOBAL BINDS IN APP_MODULE
  ];
}
```

### Retrieving Dependencies

To retrieve a dependency, you have three options:

```dart
final homeController = context.read<HomeController>();
// or
final homeController = Modular.get<HomeController>();
// or
final homeController = Bind.get<HomeController>();
```

# 🛣️ ROUTES

Route control is handled by GoRouter. The main difference is that we use **ChildRoute** for module route configurations, which has the same structure as GoRoute.

You can follow the GoRouter documentation for navigation: [GoRouter Documentation](https://pub.dev/documentation/go_router/latest/topics/Get%20started-topic.html)

**ChildRoute()** is equivalent to **GoRoute()**. You'll notice they have the same parameters.

> Note that every module must have a root route ("/") that serves as the parent route for the module.

### ChildRoutes

```dart
class HomeModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ChildRoute('/', child: (context, state) => const HomePage()), // Required root route
    ChildRoute('/config', child: (context, state) => const ConfigPage()),
    ChildRoute('/info_product/:id', child: (context, state) =>
      InfoProductPage(id: state.pathParameters['id']!)),
  ];
}
```

### Module Routes

Your module can also have submodules:

> Note that when a route calls a module, it will fall into the module's "/" route.

```dart
class AppModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ModuleRoute("/", module: HomeModule()),
    ModuleRoute("/user", module: UserModule()),
    ChildRoute('/splash', child: (context, state) => const SplashPage()),
  ];
}
```

### Shell Routes

ShellModularRoute is the equivalent of Flutter Modular's RouteOutlet. It allows you to have a navigation window within a page, commonly used for menu construction where options change but only the screen content updates.

> For more details: [GoRouter ShellRoute Documentation](https://pub.dev/documentation/go_router/latest/go_router/ShellRoute-class.html)

```dart
class HomeShellModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ShellModularRoute(
      builder: (context, state, child) => ShellPageExample(shellChild: child),
      routes: [
        ChildRoute("/config", child: (context, state) => const ConfigPage()),
        ChildRoute("/user", child: (context, state) => const UserPage()),
        ChildRoute("/orders", child: (context, state) => const OrdersPage()),
      ],
    ),
  ];
}
```

#### ShellPageExample

```dart
class ShellPageExample extends StatefulWidget {
  final Widget shellChild; // Request a child WIDGET to be rendered in the shell
  const ShellPageExample({super.key, required this.shellChild});

  @override
  State<ShellPageExample> createState() => _ShellPageExampleState();
}

class _ShellPageExampleState extends State<ShellPageExample> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Expanded(child: widget.shellChild), // Your routes will be re-rendered here
        Row(
          children: [
            IconButton(
              onPressed: () => context.go("/home"),
              icon: const Icon(Icons.home),
            ),
            IconButton(
              onPressed: () => context.go("/config"),
              icon: const Icon(Icons.settings),
            ),
          ],
        ),
      ]),
    );
  }
}
```

### Navigation Examples

Navigating to a destination in GoRouter will replace the current stack of screens:

```dart
build(BuildContext context) {
  return TextButton(
    onPressed: () => context.go('/users/123'),
  );
}
```

> This is shorthand for calling `GoRouter.of(context).go('/users/123')`.

To build a URI with query parameters, you can use the Uri class:

```dart
context.go(Uri(path: '/users/123', queryParameters: {'filter': 'abc'}).toString());
```

For more complete examples, visit the [GoRouter Documentation](https://pub.dev/documentation/go_router/latest/topics/Get%20started-topic.html)

# 🔄 MIGRATION GUIDE

## Migrating from Version 2.x to 4.x

### Breaking Changes Migration Steps

1. **Update Root Routes**: Ensure every module has a root ChildRoute with path "/"
2. **Convert Binds Getter**: Change `get binds =>` to `binds() =>`
3. **Add Lifecycle Methods**: Implement `initState()` and `dispose()` if needed
4. **Consider Module Imports**: Use `imports()` to share dependencies between modules
5. **Use ModularApp.router**: Replace `MaterialApp.router` with `ModularApp.router`

### Example Complete Migration

**Before (2.x):**

```dart
class UserModule extends Module {
  @override
  List<Bind<Object>> get binds => [
    Bind.singleton<UserService>((i) => UserService()),
  ];

  @override
  List<ModularRoute> get routes => [
    ChildRoute('/user', builder: (context, state) => const UserPage()),
    ChildRoute('/profile', builder: (context, state) => const ProfilePage()),
  ];
}

// AppWidget
class AppWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: Modular.routerConfig,
      title: 'My App',
    );
  }
}
```

**After (4.x):**

```dart
class UserModule extends Module {
  @override
  FutureOr<List<Module>> imports() => [SharedModule()];

  @override
  FutureOr<List<Bind<Object>>> binds() => [
    Bind.singleton<UserService>((i) => UserService()),
  ];

  @override
  List<ModularRoute> get routes => [
    ChildRoute('/', child: (context, state) => const UserPage()), // ✅ Root route required
    ChildRoute('/profile', child: (context, state) => const ProfilePage()),
  ];

  @override
  void initState(Injector i) {
    // Initialize user-related services
  }

  @override
  void dispose() {
    // Clean up user resources
  }
}

// AppWidget
class AppWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ModularApp.router( // ✅ Use ModularApp.router

      title: 'My App',
      loaderDecorator: CustomLoaderDecorator(), // ✅ Optional custom loader
    );
  }
}
```

## Contributions

<a href="https://github.com/eduardohr-muniz/go_router_modular/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=eduardohr-muniz/go_router_modular" />
</a>

Made with [contrib.rocks](https://contrib.rocks).
