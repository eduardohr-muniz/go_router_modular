---
sidebar_position: 4
title: Quick Start
description: Get started with GoRouter Modular in minutes
---

# 🚀 Quick Start

Get your modular Flutter app running in minutes!

## 1 -  Installation

Add the dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  go_router_modular: ^4.0.0
```

## 2 - Create App Module  and Home Module

Create your main app module:

```dart
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AppModule extends Module {
  @override
  FutureOr<List<Bind<Object>>> binds() => [];

  @override
  List<ModularRoute> get routes => [
    ModuleRoute("/", module: HomeModule()),
  ];
}

//********************************************************

class HomeModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ChildRoute(
      "/",
      child: (context, state) => Scaffold(
        body: Center(
          child: Text('Hello GoRouter Modular'),
        ),
      ),
    ),
  ];
}
```

## 3 - Create App Widget

Set up your app widget:

```dart
class AppWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ModularApp.router(
      title: 'My Modular App',
      theme: ThemeData(primarySwatch: Colors.blue),
    );
  }
}
```

## 4 - Configure Main

Initialize the modular system:

```dart
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Modular.configure(appModule: AppModule(), initialRoute: "/");

  runApp(AppWidget());
}
```

## 🎯 What's Next?

- 📁 [Project Structure](./project-structure) - Learn about recommended folder organization
- 💉 [Dependency Injection](./dependency-injection) - Master the DI system
- 🛣️ [Routes](./routes) - Understand routing concepts
- 🎭 [Event System](./event-system) - Build decoupled communication 