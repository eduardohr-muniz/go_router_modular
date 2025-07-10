
# 🧩 GoRouter Modular 💉
## Simplifying modules dependency injections

GoRouter Modular simplifies Flutter development by implementing a modular architecture.

It utilizes GoRouter for route management 🧩 and supports per-module dependency injection with auto-dispose 💉.

With GoRouter Modular, you can easily organize your application into independent modules, streamlining code development and maintenance while promoting component reuse and project scalability.

Simplify your Flutter app development and accelerate your workflow with GoRouter Modular.




# Start
1. Create an app_module.dart
2. Create an app_widget.dart
3. Configure your main.dart
 > Below you will find an example of the structure and how each file should look.

### Project Structure example
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
import 'package:example/src/app_module.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router( // Use MaterialApp.router
      routerConfig: Modular.routerConfig, // Define Router config
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
import 'package:example/src/modules/home/home_module.dart';
import 'package:example/src/modules/user/aplication/user_store.dart';
import 'package:example/src/modules/user/user_module.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AppModule extends Module {
  @override
  List<Bind<Object>> get binds => [
        Bind.singleton<AuthController>((i) => AuthController()), // define binds global in app_module
      ];
  @override
  List<ModularRoute> get routes => [ // define modules
        ModuleRoute("/", module: HomeModule()),
      ];
}


```
# DEPENDECY INJECTION 💉


⚠️ **Attention**
 > Every dependency when placed in a **BIND** must be **TYPED** for correct operation.
 
Example:
```dart
✅  Bind.singleton<HomeController>((i) => HomeController())
❌  Bind.singleton((i) => HomeController())
```

### Injecting a Dependency
You should create a class for your module and extend it from Module. Add your dependencies in the binds.

 > As soon as there are no routes for your module in the widget tree, the module will automatically dispose of the binds 

Example:
```dart
import 'package:example/src/modules/home/presenters/home_page.dart';
import 'package:go_router_modular/go_router_modular.dart';

class HomeModule extends Module {
  @override
  List<Bind<Object>> get binds => [
         Bind.singleton<HomeController>((i) => HomeController()), // DEFINE BINDS FOR MODULE
         Bind.factory<IUserRepository>((i) => UserRepository()),
      ];

}
```
## Injecting a Dependency Globally
Simply place your binds in your AppModule. 
 > Your AppModule will never be disposed of.
```dart
class AppModule extends Module {
  @override
  List<Bind<Object>> get binds => [
        Bind.singleton<AuthController>((i) => AuthController()), // DEFINE GLOBAL BINDS IN APP_MODULE
      ];
}
```

## Retrieve a Bind
To retrieve a bind, we have three options:
```dart
final homeController = context.read<HomeController>();
// or
final homeController = Modular.get<HomeController>();
// or
final homeController = Bind.get<HomeController>();
```
# Routes 🛣️
Route control is done by our beloved go_router. The only thing that changes is that we leave the route configurations for the module to use **ChildRoute**, it will have the same structure as GoRoute, you can find an example below.
You can follow the go_router documentation for navigation. [open go_router documentation](https://pub.dev/documentation/go_router/latest/topics/Get%20started-topic.html)

The **ChildRoute()** is equivalent to **GoRoute()**. You may notice that they will have the same parameters.

 > Note that every initial route of your module must start with "/" only.

### ChildRoutes
```dart
class HomeModule extends Module {
 
  @override
    List<ModularRoute> get routes => [
        ChildRoute('/', name: "home", builder: (context, state) => const HomePage()), // define routes
        ChildRoute('/config', name: "config", builder: (context, state) => const ConfigPage()),
        ChildRoute('/info_product/:id', name: "info_product", builder: (context, state) => const InfoProductPage(id: state.pathParameters['id']!)),
      ];
}
```

Your module can also have submodules. 
 > Note that whenever a route calls the module, it will fall into the module's "/" route.
```dart
class AppModule extends Module {
 
  @override
    List<ModularRoute> get routes => [ // define modules
        ModuleRoute("/", module: HomeModule()),
        ModuleRoute("/user", module: UserModule()),
        
        ChildRoute('/splash', name: "splash", builder: (context, state) => const SplashPage()),
      ];
}
```

### ShellRoutes

ShellModularRoute would be the equivalent of FLutter Modular's RouteOutlet
With it you can have a navigation window within a page. It is widely used in menu construction, where you change the options and only the screen changes.

 > Here's the doc if you want to go deeper > [open go_router ShellRoute documentation](https://pub.dev/documentation/go_router/latest/go_router/ShellRoute-class.html)
```dart
class HomeShellModule extends Module {
 
  @override
  List<ModularRoute> get routes => [
        ShellModularRoute(builder: (context, state, child) => ShellPageExample(shellChild: child),  routes:[
          ChildRoute("/config", child: (context, state) => const ConfigPage()),
          ChildRoute("/user", child: (context, state) => const UserPage()),
          ChildRoute("/orders", child: (context, state) => const OrdersPage()),
        ],
      ),
      ];
}

```
### ShellPageExample 
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
                onPressed: () {
                  context.go("/home");
                },
                icon: const Icon(Icons.home)),
            IconButton(
                onPressed: () {
                  context.go("/config");
                },
                icon: const Icon(Icons.settings)),
          ],
        ),
      ]),
    );
  }
}
```

## Go directly to a destination example
Navigating to a destination in GoRouter will replace the current stack of screens with the screens configured to be displayed for the destination route. To change to a new screen, call context.go() with a URL:
```dart
build(BuildContext context) {
  return TextButton(
    onPressed: () => context.go('/users/123'),
  );
}
```

 > This is shorthand for calling GoRouter.of(context).go('/users/123).


To build a URI with query parameters, you can use the Uri class from the Dart standard library:
```dart
context.go(Uri(path: '/users/123', queryParameters: {'filter': 'abc'}).toString());
```
For a more complete example go to [open go_router documentation](https://pub.dev/documentation/go_router/latest/topics/Get%20started-topic.html)

## Contributions

<a href="https://github.com/eduardohr-muniz/go_router_modular/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=eduardohr-muniz/go_router_modular" />
</a>

Made with [contrib.rocks](https://contrib.rocks).







