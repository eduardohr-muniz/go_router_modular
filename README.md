<div align="center">

<p align="center">
  <img src="https://raw.githubusercontent.com/eduardohr-muniz/go_router_modular/master/assets/go-router-modular-banner.png" alt="Go Router Modular Banner" />
</p>

# 🧩 GoRouter Modular 💉

<h3>Dependency injection and route management</h3>
<p style="margin-top: 4px;">
  <em>Perfect for micro-frontends and event-driven communication</em>
  
</p>

[![Pub Version](https://img.shields.io/pub/v/go_router_modular?color=blue&style=for-the-badge)](https://pub.dev/packages/go_router_modular)
[![GitHub Stars](https://img.shields.io/github/stars/eduardohr-muniz/go_router_modular?color=yellow&style=for-the-badge)](https://github.com/eduardohr-muniz/go_router_modular)
[![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)](LICENSE)

**GoRouter Modular** simplifies Flutter development by implementing a modular architecture with **GoRouter** for route management 🧩 and supports per-module **dependency injection** with auto-dispose 💉.

Perfect for **micro frontends** and large-scale applications! 🚀

</div>

---
## Complete Documentation

<div align="left">



[![Documentação](https://gist.githubusercontent.com/cxmeel/0dbc95191f239b631c3874f4ccf114e2/raw/docs.svg)](https://eduardohr-muniz.github.io/go_router_modular)


</div>



## Contents

- [Key Features](#key-features)
- [Why GoRouter Modular?](#-why-gorouter-modular)
- [Quick Start](#quick-start)
- [Dependency injection](#-dependency-injection)
- [Event System](#-event-system)
- [Navigation Examples](#-navigation-examples)
- [Useful Links](#-useful-links)
- [Contributing](#-contributing)
- [License](#-license)

## ✨ Key Features

- 🧩 **Modular Architecture** - Independent, reusable modules
- 💉 **Dependency Injection** - Built-in DI with auto-dispose
- 🛣️ **GoRouter Integration** - Type-safe and declarative navigation
- 🎭 **Event System** - Event-driven communication between modules
- 🚀 **Performance** - Lazy loading and efficient memory management
- 🛡️ **Type Safety** - Fully type-safe with compile-time error detection

---

## 🧠 Why GoRouter Modular?

- **Real scalability**: independent modules and lazy loading keep your app lightweight.
- **Clear organization**: routes and injections live within their features, improving maintainability.
- **Dependency isolation**: each module manages its own binds with automatic disposal.
- **Decoupled communication**: built-in event system across modules.
- **Developer productivity**: simple API on top of GoRouter without sacrificing flexibility.

---

## ⚡ Quick Start

### 📦 Install

```bash
flutter pub add go_router_modular
```

```yaml
dependencies:
  flutter:
    sdk: flutter
  go_router_modular: ^any
```

### 🧩 Create core files

**lib/src/app_widget.dart**

```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ModularApp.router(
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
        },
      ),
      title: 'Modular GoRoute Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}
```

**lib/src/app_module.dart**

```dart
import 'package:go_router_modular/go_router_modular.dart';

class AppModule extends Module {
  @override
  void binds(Injector i) {
    // Registra seus binds usando o Injector
    i.addSingleton<HomeController>(() => HomeController());
    i.addLazySingleton<AuthService>(() => AuthService());
    i.add<UserRepository>(() => UserRepository());
  }

  @override
  List<ModularRoute> get routes => [
    // ModuleRoute('/', child: (context, state) => HomeModule()),
  ];
}
```

### 🚀 Configure App

**lib/main.dart**

```dart
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Modular.configure(
    appModule: AppModule(), 
    initialRoute: "/",
    debugLogDiagnostics: true,
    debugLogDiagnosticsGoRouter: true,
  );
  runApp(AppWidget());
}
```

---

## 🧩 Module Example

```dart
class HomeModule extends Module {
  @override
  void binds(Injector i) {
    i.addSingleton<HomeController>(() => HomeController());
    i.addLazySingleton<HomeService>(() => HomeService(i.get<HomeController>()));
  }

  @override
  List<ModularRoute> get routes => [
    ChildRoute('/', child: (context, state) => HomePage()),
    ChildRoute('/profile', child: (context, state) => ProfilePage()),
  ];
}
```
---
## 💉 Dependency injection


**Example of binds in the feature package:**

```dart
// features/cart/lib/cart_module.dart
class CartModule extends Module {
  @override
  void binds(Injector i) {
    // Singleton: uma única instância compartilhada
    i.addSingleton<CartController>(() => CartController());
    
    // Lazy Singleton: cria apenas quando necessário
    i.addLazySingleton<CartService>(() => CartService());
    
    // Factory: nova instância a cada chamada
    i.add<CartItem>(() => CartItem());
  }

  @override
  List<ModularRoute> get routes => [
    ChildRoute('/', child: (context, state) => CartPage()),
  ];
}
```

### Types of Binds

- **`addSingleton`**: Cria uma única instância que será reutilizada sempre
- **`addLazySingleton`**: Cria apenas quando necessário (primeira vez que é usado)
- **`add`** (factory): Cria uma nova instância toda vez que é solicitado
---

### How to use your injected dependencies

You can retrieve your dependencies in three main ways:

**1. Using `Modular.get<T>()` anywhere:**

```dart
final cartController = Modular.get<CartController>();
```

**2. Using `Bind.get<T>()` directly:**

```dart
final cartController = Bind.get<CartController>();
```

**3. Using `context.read<T>()` inside a widget:**

```dart
class CartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cartController = context.read<CartController>();
    // Use cartController as needed
    return ...;
  }
}
```

### Binding with Keys

You can also bind with custom keys for multiple instances of the same type:

```dart
@override
void binds(Injector i) {
  i.addLazySingleton<ApiClient>(() => ApiClient(baseUrl: 'https://api.example.com'), key: 'remote');
  i.addLazySingleton<ApiClient>(() => ApiClient(baseUrl: 'http://localhost:3000'), key: 'local');
}

// Usage
final remoteApi = Bind.get<ApiClient>(key: 'remote');
final localApi = Bind.get<ApiClient>(key: 'local');
```

---

## 🎭 Event System

```dart
class NotificationModule extends EventModule {
  @override
  void listen() {
    on<ShowNotificationEvent>((event, context) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(event.message)),
      );
    });
  }
}

// Fire event
ModularEvent.fire(ShowNotificationEvent('Hello!'));
```

---

## 🛣️ Navigation Examples

### Basic Navigation

```dart
// Navigate to a route
context.go('/profile');

// Push a new route
context.push('/settings');

// Go back
context.pop();
```

### Navigation with Parameters

```dart
// Navigate with path parameters
context.go('/user/123');

// Navigate with query parameters
context.go('/search?q=flutter&category=all');

// Navigate with extra data
context.go('/product', extra: {'id': 456, 'name': 'Flutter Book'});
```



### Async Navigation

```dart
ElevatedButton(
  onPressed: () async {
    // Show loading
    ModularLoader.show();
    
    // Perform async operation
    await Future.delayed(Duration(seconds: 2));
    
    // Navigate
    await context.goAsync('/heavy-page');
    
    // Hide loading
    ModularLoader.hide();
  },
  child: Text('Navigate with Loading'),
 ),
```

---

## 📚 Useful Links

- 📖 **[Complete Documentation](https://eduardohr-muniz.github.io/go_router_modular)**
- 📦 **[Pub.dev](https://pub.dev/packages/go_router_modular)**
- 🐛 **[Issues](https://github.com/eduardohr-muniz/go_router_modular/issues)**
- ⭐ **[GitHub](https://github.com/eduardohr-muniz/go_router_modular)**

---

## 🤝 Contributing

Contributions are very welcome! Open an issue to discuss major changes and submit a PR with clear descriptions of the edits.

- Follow the project conventions and keep docs updated.
- Add small usage examples when introducing new features.

## 📄 License

This project is distributed under the **MIT** license. See [`LICENSE`](LICENSE) for details.

---

<div align="center">

### 🎉 **Happy Coding with GoRouter Modular!** 🎉

*Transform your Flutter app into a scalable, modular masterpiece* ✨

<div style={{textAlign: 'center', margin: '2rem 0'}}>
  <a href="https://github.com/eduardohr-muniz/go_router_modular/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=eduardohr-muniz/go_router_modular" alt="Contributors" />
  </a>
  <p style={{marginTop: '1rem', fontSize: '0.9rem', color: 'var(--ifm-color-emphasis-600)'}}>
    <strong>Made with <a href="https://contrib.rocks" target="_blank">contrib.rocks</a></strong>
  </p>
</div>

</div>

---