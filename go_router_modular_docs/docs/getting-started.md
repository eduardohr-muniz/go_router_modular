---
sidebar_position: 3
title: Getting Started
description: Build your first modular Flutter application step by step
---

# 🚀 Getting Started

Build your first modular Flutter application step by step. This tutorial will guide you through creating a complete app with multiple modules, dependency injection, and event communication.

## 📁 Project Structure

We'll create a well-organized project structure:

```
📁 lib/
  📁 src/
    📁 modules/
      📁 home/
        📄 home_module.dart
        📁 pages/
          📄 home_page.dart
      📁 profile/
        📄 profile_module.dart
        📁 pages/
          📄 profile_page.dart
      📁 shared/
        📄 shared_module.dart
        📄 shared_service.dart
    📄 app_module.dart
    📄 app_widget.dart
  📄 main.dart
```

## 1-  Create the App Module

The App Module is the root of your application that orchestrates all other modules:

```dart title="lib/src/app_module.dart"
import 'dart:async';
import 'package:go_router_modular/go_router_modular.dart';
import 'modules/home/home_module.dart';
import 'modules/shared/shared_module.dart';

class AppModule extends Module {
  @override
  FutureOr<List<Module>> imports() => [
    SharedModule(), // Global dependencies 
  ];

  @override
  FutureOr<List<Bind<Object>>> binds() => [
    // Global app-level dependencies
 
  ];

  @override
  List<ModularRoute> get routes => [
    // A good practice in App Module is to use only ModuleRoutes
    ModuleRoute('/', module: HomeModule()),
  ];
}
```
## 2 - Create the Home Module

```dart title="lib/src/app_module.dart"
import 'dart:async';
import 'package:go_router_modular/go_router_modular.dart';
import 'modules/home/home_page.dart';


class AppModule extends Module {
  @override
  FutureOr<List<Bind<Object>>> binds() => [
    // Module binds
  ];

  @override
  List<ModularRoute> get routes => [
    // A good practice in App Module is to use only ModuleRoutes
    ModuleRoute('/', module: HomePage()),
  ];
}

```

## 3 - Create the App Widget

```dart title="lib/src/app_widget.dart"
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AppWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ModularApp.router( // 👋
      title: 'GoRouter Modular Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
    );
  }
}
```

## 4 - Configure Main

```dart title="lib/main.dart"
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'src/app_module.dart';
import 'src/app_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Modular.configure(
    appModule: AppModule(), 
    initialRoute: "/"
  );
  
  runApp(AppWidget());
}
```

## 🎉 Run Your App

Now run your application:

```bash
flutter run
```

You should see:
- **🏠 Home page** with a welcome message and load data functionality
- **🔄 Smooth navigation** between modules
- **💉 Dependency injection** working seamlessly

## ✨ What You've Achieved

Congratulations! You've just created:

- ✅ **Modular architecture** with separate concerns
- ✅ **Dependency injection** with shared services
- ✅ **Clean navigation** between modules
- ✅ **Scalable structure** ready for team development
- ✅ **Reactive UI** with controllers and state management

## 🚀 Next Steps

Now that you have a working modular app, explore these advanced features:

- 🎭 **[Event System](/docs/event-system)** - Communication between modules
- 🎯 **[Loader System](/docs/loader-system)** - Custom loading indicators
- 🔒 **[Routes](/docs/routes)** - Route protection and navigation


:::tip 💡 Pro Tip
Keep your modules focused on a single responsibility. This makes your app easier to maintain and allows teams to work independently on different features.
:::

Ready to add event communication between modules? Let's explore the **[Event System](/docs/event-system)**! 🎭 