---
sidebar_position: 12
title: API Reference
description: Complete API documentation for GoRouter Modular
---

# 📋 API Reference

Complete API documentation for GoRouter Modular 4.x.

## 📚 Core Classes

### **Module**
Base class for all modules.

```dart
abstract class Module {
  /// Import other modules
  FutureOr<List<Module>> imports() => [];
  
  /// Define module dependencies
  FutureOr<List<Bind<Object>>> binds() => [];
  
  /// Define module routes
  List<ModularRoute> get routes;
  
  /// Initialize module resources
  void initState(Injector i) {}
  
  /// Clean up module resources
  void dispose() {}
}
```

### **EventModule**
Module that can listen to and respond to events.

```dart
abstract class EventModule extends Module {
  /// Listen to events
  void listen();
  
  /// Register event listener
  void on<T>(void Function(T event, NavigatorContext? context) callback);
}
```

## 🛣️ Routes

### **ChildRoute**
Simple page route.

```dart
ChildRoute(
  String path,
  {
    required Widget Function(BuildContext, GoRouterState) child,
    TransitionType? transition,
  }
)
```

### **ModuleRoute**
Nested module route.

```dart
ModuleRoute(
  String path,
  {
    required Module module,
  }
)
```

### **ShellModularRoute**
Route with shared layout.

```dart
ShellModularRoute({
  required Widget Function(BuildContext, GoRouterState, Widget) builder,
  required List<ModularRoute> routes,
})
```

## 💉 Dependency Injection

### **Bind Types**

#### **Singleton**
```dart
Bind.singleton<T>((i) => implementation)
```
One instance for the entire module lifecycle.

#### **Factory**
```dart
Bind.factory<T>((i) => implementation)
```
New instance every time it's requested.

#### **Lazy Singleton**
```dart
Bind.lazySingleton<T>((i) => implementation)
```
Created only when first accessed, then reused.

### **Dependency Access**

#### **Using Context**
```dart
final controller = context.read<HomeController>();
```

#### **Using Modular**
```dart
final controller = Modular.get<HomeController>();
```

#### **Using Bind**
```dart
final controller = Bind.get<HomeController>();
```

## 🎭 Event System

### **ModularEvent**
Global event manager.

```dart
class ModularEvent {
  /// Global instance
  static ModularEvent get instance;
  
  /// Fire event
  static void fire<T>(T event);
  
  /// Register event listener
  void on<T>(void Function(T event, NavigatorContext? context) callback);
}
```

### **Event Module Methods**

#### **on Method**
Register event listener.

```dart
void on<T>(void Function(T event, NavigatorContext? context) callback);
```

#### **listen()**
Override to define event listeners.

```dart
@override
void listen() {
  on<MyEvent>((event, context) {
    // Handle event
  });
}
```

## 🎯 Loader System

### **ModularLoader**
Loading indicator management.

```dart
class ModularLoader {
  /// Show loader
  static void show({
    String? message,
    CustomModularLoader? customLoader,
  });
  
  /// Hide loader
  static void hide({Duration? delay});
}
```

### **CustomModularLoader**
Custom loading indicator.

```dart
abstract class CustomModularLoader {
  /// Background color
  Color get backgroundColor;
  
  /// Loading widget
  Widget get child;
}
```



## 🏗️ Lifecycle

### **Module Lifecycle**

#### **initState(Injector i)**
Called when module is initialized.

```dart
@override
void initState(Injector i) {
  // Initialize resources
  final service = i.get<MyService>();
  service.initialize();
}
```

#### **dispose()**
Called when module is disposed.

```dart
@override
void dispose() {
  // Clean up resources
  final service = Modular.get<MyService>();
  service.dispose();
}
```

### **Event Module Lifecycle**

#### **listen()**
Called when event module is initialized.

```dart
@override
void listen() {
  on<MyEvent>((event, context) {
    // Handle event
  });
}
```

## 🛡️ Error Handling

### **ModularException**
Base exception class.

```dart
class ModularException implements Exception {
  final String message;
  final dynamic error;
  
  ModularException(this.message, [this.error]);
}
```

### **BindNotFoundException**
Thrown when dependency is not found.

```dart
class BindNotFoundException extends ModularException {
  final Type type;
  
  BindNotFoundException(this.type) : super('Bind not found: $type');
}
```

## 🧪 Testing

### **Test Configuration**
```dart
void main() {
  setUp(() {
    Modular.configure(
      appModule: TestAppModule(),
      initialRoute: "/",
    );
  });
  
  tearDown(() {
    Modular.destroy();
  });
}
```

### **Mock Dependencies**
```dart
class TestAppModule extends Module {
  @override
  FutureOr<List<Bind<Object>>> binds() => [
    Bind.singleton<IApiService>((i) => MockApiService()),
  ];
}
```

## 📋 Complete Example

### **App Module**
```dart
class AppModule extends Module {
  @override
  FutureOr<List<Module>> imports() => [
    SharedModule(),
  ];

  @override
  FutureOr<List<Bind<Object>>> binds() => [
    Bind.singleton<AppController>((i) => AppController()),
  ];

  @override
  List<ModularRoute> get routes => [
    ModuleRoute("/", module: HomeModule()),
    ModuleRoute("/auth", module: AuthModule()),
  ];
}
```

### **Event Module**
```dart
class NotificationModule extends EventModule {
  @override
  FutureOr<List<Bind<Object>>> binds() => [
    Bind.singleton<NotificationService>((i) => NotificationService()),
  ];

  @override
  List<ModularRoute> get routes => [
    ChildRoute('/', child: (context, state) => NotificationPage()),
  ];

  @override
  void listen() {
    on<ShowNotificationEvent>((event, context) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(event.message)),
        );
      }
    });
  }
}
```

### **Main Function**
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Modular.configure(
    appModule: AppModule(),
    initialRoute: "/",
  );
  runApp(AppWidget());
}

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

## 📚 Related Topics

- 🚀 [Quick Start](./quick-start) - Get started quickly
- 💉 [Dependency Injection](./dependency-injection) - DI patterns
- 🛣️ [Routes](./routes) - Routing concepts
- 🎭 [Event System](./event-system) - Event communication 