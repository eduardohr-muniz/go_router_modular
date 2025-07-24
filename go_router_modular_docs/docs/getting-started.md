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
        📄 home_controller.dart
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

## 1️⃣ Create the App Module

The App Module is the root of your application that orchestrates all other modules:

```dart title="lib/src/app_module.dart"
import 'dart:async';
import 'package:go_router_modular/go_router_modular.dart';
import 'modules/home/home_module.dart';
import 'modules/profile/profile_module.dart';
import 'modules/shared/shared_module.dart';

class AppModule extends Module {
  @override
  FutureOr<List<Module>> imports() => [
    SharedModule(), // Global dependencies
  ];

  @override
  FutureOr<List<Bind<Object>>> binds() => [
    // Global app-level dependencies
    Bind.singleton<AppController>((i) => AppController()),
  ];

  @override
  List<ModularRoute> get routes => [
    ModuleRoute('/', module: HomeModule()),
    ModuleRoute('/profile', module: ProfileModule()),
  ];
}

class AppController {
  String get appTitle => 'My Modular App';
}
```

## 2️⃣ Create the Shared Module

The Shared Module contains services and dependencies used across multiple modules:

```dart title="lib/src/modules/shared/shared_module.dart"
import 'dart:async';
import 'package:go_router_modular/go_router_modular.dart';
import 'shared_service.dart';

class SharedModule extends Module {
  @override
  FutureOr<List<Bind<Object>>> binds() => [
    Bind.singleton<SharedService>((i) => SharedService()),
    Bind.lazySingleton<DatabaseService>((i) => DatabaseService()),
  ];

  @override
  List<ModularRoute> get routes => [];
}
```

```dart title="lib/src/modules/shared/shared_service.dart"
class SharedService {
  void logMessage(String message) {
    print('📝 Log: $message');
  }
  
  Future<String> fetchUserData() async {
    await Future.delayed(Duration(seconds: 1));
    return 'User data from API';
  }
}

class DatabaseService {
  Future<void> saveData(String key, String value) async {
    print('💾 Saving: $key = $value');
  }
}
```

## 3️⃣ Create the Home Module

```dart title="lib/src/modules/home/home_module.dart"
import 'dart:async';
import 'package:go_router_modular/go_router_modular.dart';
import 'home_controller.dart';
import 'pages/home_page.dart';

class HomeModule extends Module {
  @override
  FutureOr<List<Bind<Object>>> binds() => [
    Bind.singleton<HomeController>((i) => HomeController()),
  ];

  @override
  List<ModularRoute> get routes => [
    ChildRoute('/', child: (context, state) => HomePage()),
  ];
}
```

```dart title="lib/src/modules/home/home_controller.dart"
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import '../shared/shared_service.dart';

class HomeController extends ChangeNotifier {
  final SharedService _sharedService = Modular.get<SharedService>();
  
  String _message = 'Welcome to GoRouter Modular!';
  bool _isLoading = false;

  String get message => _message;
  bool get isLoading => _isLoading;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _sharedService.fetchUserData();
      _message = data;
      _sharedService.logMessage('Data loaded successfully');
    } catch (e) {
      _message = 'Error loading data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

```dart title="lib/src/modules/home/pages/home_page.dart"
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import '../home_controller.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController controller;

  @override
  void initState() {
    super.initState();
    controller = context.read<HomeController>();
    controller.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChange);
    super.dispose();
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🏠 Home'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.home, size: 48, color: Colors.blue),
                    SizedBox(height: 16),
                    Text(
                      controller.message,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: controller.isLoading ? null : controller.loadData,
              icon: controller.isLoading 
                ? SizedBox(
                    width: 16, 
                    height: 16, 
                    child: CircularProgressIndicator(strokeWidth: 2)
                  )
                : Icon(Icons.refresh),
              label: Text('Load Data'),
            ),
            SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.go('/profile'),
              icon: Icon(Icons.person),
              label: Text('Go to Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 4️⃣ Create the Profile Module

```dart title="lib/src/modules/profile/profile_module.dart"
import 'dart:async';
import 'package:go_router_modular/go_router_modular.dart';
import 'pages/profile_page.dart';

class ProfileModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ChildRoute('/', child: (context, state) => ProfilePage()),
  ];
}
```

```dart title="lib/src/modules/profile/pages/profile_page.dart"
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('👤 Profile'),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.green,
                      child: Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'John Doe',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      'john.doe@example.com',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.go('/'),
              icon: Icon(Icons.home),
              label: Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 5️⃣ Create the App Widget

```dart title="lib/src/app_widget.dart"
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AppWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ModularApp.router(
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

## 6️⃣ Configure Main

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
- **👤 Profile page** accessible via navigation
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
- 📚 **[API Reference](/docs/api-reference)** - Complete API documentation

:::tip 💡 Pro Tip
Keep your modules focused on a single responsibility. This makes your app easier to maintain and allows teams to work independently on different features.
:::

Ready to add event communication between modules? Let's explore the **[Event System](/docs/event-system)**! 🎭 