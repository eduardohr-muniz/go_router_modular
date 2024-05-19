
# 🧩 GoRouter Modular 💉
## Simplifying modules dependency injections

GoRouter Modular simplifies Flutter development by implementing a modular architecture.

It utilizes GoRouter for route management 🧩 and supports per-module dependency injection with auto-dispose 💉.

With GoRouter Modular, you can easily organize your application into independent modules, streamlining code development and maintenance while promoting component reuse and project scalability.

Simplify your Flutter app development and accelerate your workflow with GoRouter Modular.



## Installation

```bash
flutter pub add go_router_modular
```
##### or
This will add a line like this to your package's pubspec.yaml (and run an implicit flutter pub get):
dependencies:
```bash
go_router_modular: ^0.0.12
```
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
      routerConfig: GoRouterModular.configure(appModule: AppModule()), // Configure AppModule
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
  List<ModuleRoute> get moduleRoutes => [ // define modules
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
      ];

  @override
  List<ChildRoute> get routes => [
        ChildRoute('/', name: "home", builder: (context, state, i) => const HomePage()), // define routes
        ChildRoute('/config', name: "config", builder: (context, state, i) => const ConfigPage()),
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
To retrieve a bind, we have two options:
```dart
final homeController = context.read<HomeController>();
// or
final homeController = Bind.get<HomeController>();
```
# Routes 🛣️
Route control is done by our beloved go_router. The only thing that changes is that we leave the route configurations for the module to use **ChildRoute**, it will have the same structure as GoRoute, you can find an example below.
You can follow the go_router documentation for navigation. [open go_router documentation](https://pub.dev/documentation/go_router/latest/topics/Get%20started-topic.html)

The child route is equivalent to GoRoute(). You may notice that they will have the same parameters.

 > Note that every initial route of your module must start with "/" only.

Ex: Routes
```dart
class HomeModule extends Module {
 
  @override
  List<ChildRoute> get routes => [
        ChildRoute('/', name: "home", builder: (context, state, i) => const HomePage()), // define routes
        ChildRoute('/config', name: "config", builder: (context, state, i) => const ConfigPage()),
      ];
}
```

Your module can also have submodules. 
 > Note that whenever a route calls the module, it will fall into the module's "/" route.
```dart
class AppModule extends Module {
 
  @override
  List<ModuleRoute> get moduleRoutes => [ // define modules
        ModuleRoute("/", module: HomeModule()),
        ModuleRoute("/user", module: UserModule()),
      ];
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








