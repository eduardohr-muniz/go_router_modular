<div align="center">

# 🧩 GoRouter Modular 💉

### Simplifying Flutter development with modular architecture

[![Pub Version](https://img.shields.io/pub/v/go_router_modular?color=blue&style=for-the-badge)](https://pub.dev/packages/go_router_modular)
[![GitHub Stars](https://img.shields.io/github/stars/eduardohr-muniz/go_router_modular?color=yellow&style=for-the-badge)](https://github.com/eduardohr-muniz/go_router_modular)
[![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)](LICENSE)

**GoRouter Modular** simplifies Flutter development by implementing a modular architecture with **GoRouter** for route management 🧩 and supports per-module **dependency injection** with auto-dispose 💉.

Perfect for **micro frontends** and large-scale applications! 🚀

[**📖 Live Documentation**](https://eduardohr-muniz.github.io/go_router_modular/) • [**📦 Pub.dev**](https://pub.dev/packages/go_router_modular) • [**🐛 Issues**](https://github.com/eduardohr-muniz/go_router_modular/issues)

</div>

---

## ✨ Key Features

<table>
<tr>
<td width="50%">

### 🧩 **Modular Architecture**
- Independent, reusable modules
- Clear boundaries and responsibilities  
- Team-friendly development

### 💉 **Dependency Injection**
- Built-in DI with auto-dispose
- Module-scoped and global dependencies
- Memory leak prevention

### 🛣️ **GoRouter Integration**
- Seamless GoRouter integration
- Type-safe navigation
- Declarative routing

</td>
<td width="50%">

### 🎭 **Event System**
- Event-driven communication
- Perfect for **micro frontends**
- Decoupled module interaction

### 🚀 **Performance**
- Lazy loading modules
- Automatic disposal
- Efficient memory management

### 🛡️ **Type Safety**
- Fully type-safe
- Compile-time error detection
- Excellent IDE support

</td>
</tr>
</table>

---

## 🚀 Quick Start

### 1️⃣ Installation

```yaml
dependencies:
  go_router_modular: ^4.0.0
  event_bus: ^2.0.0
```

### 2️⃣ Create App Module

```dart
import 'package:go_router_modular/go_router_modular.dart';

class AppModule extends Module {
  @override
  FutureOr<List<Bind<Object>>> binds() => [
    Bind.singleton<AuthController>((i) => AuthController()),
  ];

  @override
  List<ModularRoute> get routes => [
    ModuleRoute("/", module: HomeModule()),
  ];
}
```

### 3️⃣ Create App Widget

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

### 4️⃣ Configure Main

```dart
void main() {
  Modular.configure(appModule: AppModule(), initialRoute: "/");
  runApp(AppWidget());
}
```

---

## 📚 Documentation

<details>
<summary><b>🏗️ Project Structure</b></summary>

```
📁 lib/
  📁 src/
    📁 modules/
      📁 auth/
        📄 auth_module.dart
        📄 auth_controller.dart
        📁 pages/
          📄 login_page.dart
      📁 home/
        📄 home_module.dart
        📁 pages/
          📄 home_page.dart
    📄 app_module.dart
    📄 app_widget.dart
  📄 main.dart
```

</details>

<details>
<summary><b>💉 Dependency Injection</b></summary>

### Basic Usage

```dart
class HomeModule extends Module {
  @override
  FutureOr<List<Bind<Object>>> binds() => [
    Bind.singleton<HomeController>((i) => HomeController()),
    Bind.factory<UserRepository>((i) => UserRepository()),
  ];

  @override
  List<ModularRoute> get routes => [
    ChildRoute('/', child: (context, state) => HomePage()),
  ];
}
```

### Retrieving Dependencies

```dart
// Using context
final controller = context.read<HomeController>();

// Using Modular
final controller = Modular.get<HomeController>();

// Using Bind
final controller = Bind.get<HomeController>();
```

### Module Lifecycle

```dart
class AuthModule extends Module {
  @override
  void initState(Injector i) {
    // Initialize resources
  }

  @override
  void dispose() {
    // Clean up resources
  }
}
```

</details>

<details>
<summary><b>🛣️ Routes</b></summary>

### Child Routes

```dart
class HomeModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ChildRoute('/', child: (context, state) => HomePage()),
    ChildRoute('/profile', child: (context, state) => ProfilePage()),
    ChildRoute('/user/:id', child: (context, state) => 
      UserPage(id: state.pathParameters['id']!)),
  ];
}
```

### Module Routes

```dart
class AppModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ModuleRoute("/", module: HomeModule()),
    ModuleRoute("/auth", module: AuthModule()),
  ];
}
```

### Shell Routes

```dart
class ShellModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ShellModularRoute(
      builder: (context, state, child) => ShellPage(child: child),
      routes: [
        ChildRoute("/dashboard", child: (context, state) => DashboardPage()),
        ChildRoute("/settings", child: (context, state) => SettingsPage()),
      ],
    ),
  ];
}
```

### Navigation

```dart
// Navigate to route
context.go('/user/123');

// Push route
context.push('/modal');

// With query parameters
context.go(Uri(path: '/search', queryParameters: {'q': 'flutter'}).toString());
```

</details>

<details>
<summary><b>🎭 Event System</b></summary>

### Creating Event Modules

```dart
class NotificationModule extends EventModule {
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

class ShowNotificationEvent {
  final String message;
  ShowNotificationEvent(this.message);
}
```

### Global Events

```dart
// Register global listener
ModularEvent.instance.on<UserLoggedOutEvent>((event, context) {
  if (context != null) context.go('/login');
});

// Fire events
ModularEvent.fire(UserLoggedOutEvent());
modularEvent.fire(ShowNotificationEvent('Welcome!'));
```

</details>

<details>
<summary><b>🎯 Loader System</b></summary>

### Automatic Loader

The loader automatically appears during module loading and dependency injection.

### Manual Control

```dart
// Show loader
ModularLoader.show();

// Hide loader
ModularLoader.hide();
```

### Custom Loader

```dart
class MyLoader extends CustomModularLoader {
  @override
  Color get backgroundColor => Colors.black87;

  @override
  Widget get child => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      CircularProgressIndicator(color: Colors.blue),
      SizedBox(height: 16),
      Text('Loading...', style: TextStyle(color: Colors.white)),
    ],
  );
}

// Use in app
ModularApp.router(
  customModularLoader: MyLoader(),
  title: 'My App',
);
```

### Async Navigation

```dart
ElevatedButton(
  onPressed: () async {
    setState(() => isLoading = true);
    
    await context.goAsync('/heavy-page');
    
    setState(() => isLoading = false);
  },
  child: Text('Navigate'),
);
```

</details>

---

## 🧩 Micro Frontend Architecture

Perfect for **teams working independently** on different features!

### E-commerce Example

<table>
<tr>
<td width="33%">

**🛒 Cart Module (Team A)**
```dart
class CartModule extends EventModule {
  @override
  void listen() {
    on<ProductAddedEvent>((event, context) {
      // Add to cart logic
      ModularEvent.fire(CartUpdatedEvent());
    });
  }
}
```

</td>
<td width="33%">

**🏪 Catalog Module (Team B)**
```dart
class CatalogModule extends EventModule {
  @override
  void listen() {
    on<CartUpdatedEvent>((event, context) {
      // Update availability
    });
  }
}
```

</td>
<td width="33%">

**💳 Checkout Module (Team C)**
```dart
class CheckoutModule extends EventModule {
  @override
  void listen() {
    on<CartUpdatedEvent>((event, context) {
      // Update totals
    });
  }
}
```

</td>
</tr>
</table>

### Benefits for Teams

- 🔄 **Decoupled Communication** - Teams develop independently
- 📡 **Event-driven Integration** - Seamless module communication  
- 🧪 **Easy Testing** - Test modules in isolation
- 📦 **Independent Deployment** - Deploy modules separately
- 🛡️ **Type Safety** - Compile-time error detection

---

## 📖 Migration Guide

<details>
<summary><b>🔄 From 2.x to 4.x</b></summary>

### Breaking Changes

> ⚠️ **Important Changes:**
> - Root routes now required
> - `binds()` method replaces getter
> - New lifecycle methods
> - `ModularApp.router` replaces `MaterialApp.router`

### Migration Steps

#### 1. Update Routes

**Before (2.x):**
```dart
List<ModularRoute> get routes => [
  ChildRoute('/user', builder: (context, state) => UserPage()),
];
```

**After (4.x):**
```dart
List<ModularRoute> get routes => [
  ChildRoute('/', child: (context, state) => UserPage()), // Root required
];
```

#### 2. Convert Binds

**Before (2.x):**
```dart
@override
List<Bind<Object>> get binds => [
  Bind.singleton<UserService>((i) => UserService()),
];
```

**After (4.x):**
```dart
@override
FutureOr<List<Bind<Object>>> binds() => [
  Bind.singleton<UserService>((i) => UserService()),
];
```

#### 3. Update App Widget

**Before (2.x):**
```dart
return MaterialApp.router(
  routerConfig: Modular.routerConfig,
  title: 'My App',
);
```

**After (4.x):**
```dart
return ModularApp.router(
  title: 'My App',
  theme: ThemeData(primarySwatch: Colors.blue),
);
```

</details>

---

## 📋 API Reference

<details>
<summary><b>📚 Core Classes</b></summary>

### Module
```dart
abstract class Module {
  FutureOr<List<Module>> imports() => [];
  FutureOr<List<Bind<Object>>> binds() => [];
  List<ModularRoute> get routes;
  
  void initState(Injector i) {}
  void dispose() {}
}
```

### EventModule
```dart
abstract class EventModule extends Module {
  void listen();
  void on<T>(void Function(T event, NavigatorContext? context) callback);
}
```

### Routes
```dart
// Child Route
ChildRoute(String path, {required Widget Function(BuildContext, GoRouterState) child})

// Module Route  
ModuleRoute(String path, {required Module module})

// Shell Route
ShellModularRoute({
  required Widget Function(BuildContext, GoRouterState, Widget) builder,
  required List<ModularRoute> routes,
})
```

### Dependency Injection
```dart
// Singleton
Bind.singleton<T>((i) => implementation);

// Factory
Bind.factory<T>((i) => implementation);

// Lazy Singleton
Bind.lazySingleton<T>((i) => implementation);
```

</details>

---

## 🤝 Contributing

We welcome contributions! Here's how you can help:

- 🐛 **Report bugs** by creating issues
- 💡 **Suggest features** through discussions
- 🔧 **Submit pull requests** with improvements
- 📖 **Improve documentation**
- ⭐ **Star the repository** to show support

<div align="center">

### Contributors

<a href="https://github.com/eduardohr-muniz/go_router_modular/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=eduardohr-muniz/go_router_modular" />
</a>

**Made with [contrib.rocks](https://contrib.rocks)**

---

### 🎉 **Happy Coding with GoRouter Modular!** 🎉

*Transform your Flutter app into a scalable, modular masterpiece* ✨

</div>
