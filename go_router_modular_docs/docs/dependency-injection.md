---
sidebar_position: 9
title: Dependency Injection
description: Master the built-in DI system with auto-dispose
---

# 💉 Dependency Injection

GoRouter Modular provides a powerful dependency injection system with automatic disposal to prevent memory leaks.

## 🔧 Basic Usage

### **Module Dependencies**

```dart
class HomeModule extends Module {
  @override
  FutureOr<List<Bind<Object>>> binds() => [
    Bind.singleton<HomeController>((i) => HomeController()),
    Bind.factory<UserRepository>((i) => UserRepository()),
    Bind.lazySingleton<ApiService>((i) => ApiService()),
  ];

  @override
  List<ModularRoute> get routes => [
    ChildRoute('/', child: (context, state) => HomePage()),
  ];
}
```

### **Dependency Types**

#### **Singleton** - One instance for the entire module lifecycle
```dart
Bind.singleton<HomeController>((i) => HomeController());
```

#### **Factory** - New instance every time
```dart
Bind.factory<UserRepository>((i) => UserRepository());
```

#### **Lazy Singleton** - Created only when first accessed
```dart
Bind.lazySingleton<ApiService>((i) => ApiService());
```

## 🔍 Retrieving Dependencies

### **Using Context**
```dart
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.read<HomeController>();
    final repository = context.read<UserRepository>();
    
    return Scaffold(
      body: Text('Hello ${controller.userName}'),
    );
  }
}
```

### **Using Modular**
```dart
final controller = Modular.get<HomeController>();
final repository = Modular.get<UserRepository>();
```

### **Using Bind**
```dart
final controller = Bind.get<HomeController>();
final repository = Bind.get<UserRepository>();
```

## 🔄 Module Lifecycle

### **Initialization**
```dart
class AuthModule extends Module {
  @override
  void initState(Injector i) {
    // Initialize resources when module loads
    final authService = i.get<AuthService>();
    authService.initialize();
  }

  @override
  FutureOr<List<Bind<Object>>> binds() => [
    Bind.singleton<AuthService>((i) => AuthService()),
  ];
}
```

### **Disposal**
```dart
class AuthModule extends Module {
  @override
  void dispose() {
    // The dispose method is used when you want to execute an action when the module is disposed,
    // for example, stop listening to a stream or disconnect from a websocket.
  }
}
```

## ⚡️ Asynchronous Binds

You can use asynchronous binds to initialize dependencies that require async operations, such as fetching remote configuration or initializing plugins.

**Example: Remote Config (e.g., Firebase Remote Config)**
```dart
class RemoteConfigModule extends Module {
  @override
  FutureOr<List<Bind<Object>>> binds() async {
    // Fetch remote config asynchronously
    final remoteConfig = await RemoteConfig.instance.fetchAndActivate();
    return [
      Bind.singleton<Dio>(
        (i) => Dio(BaseOptions(baseUrl: remoteConfig.baseUrl)),
      ),
    ];
  }
}

class SharedPreferencesModule extends Module {
  @override
  FutureOr<List<Bind<Object>>> binds() async {
    // Initialize SharedPreferences asynchronously
    final prefs = await SharedPreferences.getInstance();
    return [
      Bind.singleton<SharedPreferences>((i) => prefs),
      Bind.singleton<LocalStorageService>((i) => LocalStorageService(prefs)),
    ];
  }
}


```
> **⚠️ Important Note**: In async `binds()` methods, avoid using `Modular.get<T>()` because the bind might not have been injected yet. Always use the `Injector` parameter or create dependencies directly.

> **Warning**
> Asynchronous binds are strictly forbidden in the `AppModule`. Only use async binds in feature modules. The root `AppModule` must always use synchronous binds to ensure proper app initialization and avoid unpredictable behavior.

## 🎯 Advanced Patterns

### **Dependency with Parameters**
```dart
class UserModule extends Module {
  @override
  FutureOr<List<Bind<Object>>> binds() => [
    Bind.singleton<UserService>((i) => UserService(
      apiKey: 'your-api-key',
      baseUrl: 'https://api.example.com',
    )),
  ];
}
```

### **Dependent Dependencies**
```dart
class AppModule extends Module {
  @override
  FutureOr<List<Bind<Object>>> binds() => [
    Bind.singleton<ApiService>((i) => ApiService()),
    Bind.singleton<UserRepository>((i) => UserRepository(
      apiService: i.get<ApiService>(), // Inject dependency
    )),
  ];
}
```

### **Conditional Dependencies**
```dart
class AppModule extends Module {
  @override
  FutureOr<List<Bind<Object>>> binds() => [
    if (kDebugMode)
      Bind.singleton<Logger>((i) => DebugLogger())
    else
      Bind.singleton<Logger>((i) => ProductionLogger()),
  ];
}
```

## 🛡️ Memory Management

### **Automatic Disposal**
- Dependencies are automatically disposed when modules are unloaded
- Prevents memory leaks
- No manual cleanup required


## 📚 Related Topics

- 🏗️ [Project Structure](./project-structure) - Organize your modules
- 🛣️ [Routes](./routes) - Define module routes
- 🎭 [Event System](./event-system) - Module communication 