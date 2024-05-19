
# GoRouter Modular
## Simplifying modules dependency injections💉
css
GoRouter Modular simplifies Flutter development by implementing a modular architecture.

It utilizes GoRouter for route management 🧩 and supports per-module dependency injection with auto-dispose 💉.

With GoRouter Modular, you can easily organize your application into independent modules, streamlining code development and maintenance while promoting component reuse and project scalability.

Simplify your Flutter app development and accelerate your workflow with GoRouter Modular.

```css
⚠️ **Attention:** Every dependency when placed in a bind must be typed for correct operation.
Example:
✅ Bind.singleton<HomeController>((i) => HomeController())
❌ Bind.singleton((i) => HomeController())
```

## Installation

```bash
flutter pub add go_router_modular
````
## Project Structure
```css
📁 src
   📁 modules
      📄 home_controller.dart
      📄 home_page.dart
      📄 home_module.dart
   📄 app_module.dart
   📄 app_widget.dart
📄 main.dart
```

## Main Example
```dart
import 'package:example/src/app_module.dart';
import 'package:example/src/app_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

final injector = Injector(); // instance global injectors

final router = GoRouter( // configure routes
  initialLocation: '/',
  routes: AppModule().configureRoutes(injector),
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) usePathUrlStrategy();
  
  runApp(AppWidget(router: router));
}
````
## AppWidget Example
```dart
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AppWidget extends StatelessWidget {
  final GoRouter router;

  const AppWidget({required this.router, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router( // add material app router
      routerConfig: router, // configure go_router
      title: 'Modular GoRoute Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}
```
## AppModule Example

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
//----------------------------------------HomeModule Example---------------------------------------------

import 'package:example/src/modules/home/presenters/home_page.dart';
import 'package:go_router_modular/go_router_modular.dart';

class HomeModule extends Module {
  @override
  List<Bind<Object>> get binds => [
         Bind.singleton<HomeController>((i) => HomeController()), // define binds the module
      ];

  @override
  List<ChildRoute> get routes => [
        ChildRoute('/', name: "home", builder: (context, state, i) => const HomePage()), // define routes
        ChildRoute('/config', name: "config", builder: (context, state, i) => const ConfigPage()),
      ];
}
```
