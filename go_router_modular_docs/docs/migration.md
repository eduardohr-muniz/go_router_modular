---
sidebar_position: 14
title: Migration Guide
description: Migrate from older versions to GoRouter Modular 4.x
---

# 📖 Migration Guide

Migrate your existing GoRouter Modular app from version 2.x to 4.x with this comprehensive guide.

## ⚠️ Breaking Changes

### **Important Changes in 4.x:**
- Root routes now required
- `binds()` method replaces getter
- New lifecycle methods
- `ModularApp.router` replaces `MaterialApp.router`

## 🔄 Migration Steps

### **1. Update Routes**

**Before (2.x):**
```dart
class HomeModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ChildRoute('/user', builder: (context, state) => UserPage()),
    ChildRoute('/profile', builder: (context, state) => ProfilePage()),
  ];
}
```

**After (4.x):**
```dart
class HomeModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ChildRoute('/', child: (context, state) => UserPage()), // Root required
    ChildRoute('/profile', child: (context, state) => ProfilePage()),
  ];
}
```

### **2. Convert Binds**

**Before (2.x):**
```dart
class HomeModule extends Module {
  @override
  List<Bind<Object>> get binds => [
    Bind.singleton<UserService>((i) => UserService()),
    Bind.factory<UserRepository>((i) => UserRepository()),
  ];
}
```

**After (4.x):**
```dart
class HomeModule extends Module {
  @override
  FutureOr<List<Bind<Object>>> binds() => [
    Bind.singleton<UserService>((i) => UserService()),
    Bind.factory<UserRepository>((i) => UserRepository()),
  ];
}
```

### **3. Update App Widget**

**Before (2.x):**
```dart
class AppWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: Modular.routerConfig,
      title: 'My App',
      theme: ThemeData(primarySwatch: Colors.blue),
    );
  }
}
```

**After (4.x):**
```dart
class AppWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ModularApp.router(
      title: 'My App',
      theme: ThemeData(primarySwatch: Colors.blue),
    );
  }
}
```

### **4. Update Route Parameters**

**Before (2.x):**
```dart
ChildRoute('/user/:id', builder: (context, state) => 
  UserPage(id: state.params['id'])),
```

**After (4.x):**
```dart
ChildRoute('/user/:id', child: (context, state) => 
  UserPage(id: state.pathParameters['id']!)),
```

### **5. Update Navigation**

**Before (2.x):**
```dart
Modular.to.navigate('/user/123');
Modular.to.pushNamed('/modal');
```

**After (4.x):**
```dart
context.go('/user/123');
context.push('/modal');
```

## 🎯 Detailed Migration Examples

### **Complete Module Migration**

**Before (2.x):**
```dart
class AuthModule extends Module {
  @override
  List<Bind<Object>> get binds => [
    Bind.singleton<AuthService>((i) => AuthService()),
    Bind.singleton<AuthController>((i) => AuthController()),
  ];

  @override
  List<ModularRoute> get routes => [
    ChildRoute('/login', builder: (context, state) => LoginPage()),
    ChildRoute('/register', builder: (context, state) => RegisterPage()),
    ChildRoute('/user/:id', builder: (context, state) => 
      UserPage(id: state.params['id'])),
  ];
}
```

**After (4.x):**
```dart
class AuthModule extends Module {
  @override
  FutureOr<List<Bind<Object>>> binds() => [
    Bind.singleton<AuthService>((i) => AuthService()),
    Bind.singleton<AuthController>((i) => AuthController()),
  ];

  @override
  List<ModularRoute> get routes => [
    ChildRoute('/', child: (context, state) => LoginPage()), // Root route
    ChildRoute('/register', child: (context, state) => RegisterPage()),
    ChildRoute('/user/:id', child: (context, state) => 
      UserPage(id: state.pathParameters['id']!)),
  ];
}
```

### **App Module Migration**

**Before (2.x):**
```dart
class AppModule extends Module {
  @override
  List<Bind<Object>> get binds => [
    Bind.singleton<AppController>((i) => AppController()),
  ];

  @override
  List<ModularRoute> get routes => [
    ModuleRoute("/", module: HomeModule()),
    ModuleRoute("/auth", module: AuthModule()),
  ];
}
```

**After (4.x):**
```dart
class AppModule extends Module {
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

### **Main Function Migration**

**Before (2.x):**
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Modular.configure(Modular.configure(appModule: AppModule(), initialRoute: "/");
  runApp(AppWidget());
}

class AppWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: Modular.routerConfig,
      title: 'My App',
      theme: ThemeData(primarySwatch: Colors.blue),
    );
  }
}
```

**After (4.x):**
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Modular.configure(Modular.configure(appModule: AppModule(), initialRoute: "/");
  runApp(AppWidget());
}

class AppWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ModularApp.router(
      title: 'My App',
      theme: ThemeData(primarySwatch: Colors.blue),
    );
  }
}
```

## 🔧 Advanced Migration

### **Event Module Migration**

**Before (2.x):**
```dart
class NotificationModule extends Module {
  @override
  void initState() {
    modularEvent.on<ShowNotificationEvent>().listen((event) {
      // Handle event
    });
  }
}
```

**After (4.x):**
```dart
class NotificationModule extends EventModule {
  @override
  void listen() {
    on<ShowNotificationEvent>((event, context) {
      // Handle event with context
    });
  }
}
```

### **Dependency Access Migration**

**Before (2.x):**
```dart
// In widgets
final controller = Modular.get<UserController>();

// In services
final service = Modular.get<UserService>();
```

**After (4.x):**
```dart
// In widgets (recommended)
final controller = context.read<UserController>();

// In services (still works)
final service = Modular.get<UserService>();
```

## 🚨 Common Issues

### **1. Missing Root Route**
```dart
// ❌ Error - Missing root route
List<ModularRoute> get routes => [
  ChildRoute('/profile', child: (context, state) => ProfilePage()),
];

// ✅ Fix - Add root route
List<ModularRoute> get routes => [
  ChildRoute('/', child: (context, state) => HomePage()),
  ChildRoute('/profile', child: (context, state) => ProfilePage()),
];
```

### **2. Wrong Parameter Access**
```dart
// ❌ Error - Old parameter access
final id = state.params['id'];

// ✅ Fix - New parameter access
final id = state.pathParameters['id']!;
```

### **3. Wrong Navigation Method**
```dart
// ❌ Error - Old navigation
Modular.to.navigate('/user/123');

// ✅ Fix - New navigation
context.go('/user/123');
```

## 🧪 Testing Migration

### **Update Test Files**
```dart
// Before (2.x)
void main() {
  setUp(() {
    Modular.configure(appModule: TestModule());
  });
}

// After (4.x)
void main() {
  setUp(() {
    Modular.configure(appModule: TestModule(), initialRoute: "/");
  });
}
```

## 📚 Related Topics

- 🚀 [Quick Start](./quick-start) - Get started with 4.x
- 💉 [Dependency Injection](./dependency-injection) - New DI patterns
- 🛣️ [Routes](./routes) - Updated routing system 