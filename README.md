<div align="center">

# 🧩 GoRouter Modular 💉

### Simplifying Flutter development with modular architecture

[![Pub Version](https://img.shields.io/pub/v/go_router_modular?color=blue&style=for-the-badge)](https://pub.dev/packages/go_router_modular)
[![GitHub Stars](https://img.shields.io/github/stars/eduardohr-muniz/go_router_modular?color=yellow&style=for-the-badge)](https://github.com/eduardohr-muniz/go_router_modular)
[![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)](LICENSE)

**GoRouter Modular** simplifies Flutter development by implementing a modular architecture with **GoRouter** for route management 🧩 and supports per-module **dependency injection** with auto-dispose 💉.

Perfect for **micro frontends** and large-scale applications! 🚀

</div>

---

<div align="center">

## 📖 [**Complete Documentation**](https://eduardohr-muniz.github.io/go_router_modular/docs/intro)

[![Documentation](https://img.shields.io/badge/📖-Complete%20Documentation-blue?style=for-the-badge&logo=book)](https://eduardohr-muniz.github.io/go_router_modular/docs/intro)

</div>

---

## ✨ Key Features

- 🧩 **Modular Architecture** - Independent, reusable modules
- 💉 **Dependency Injection** - Built-in DI with auto-dispose
- 🛣️ **GoRouter Integration** - Type-safe and declarative navigation
- 🎭 **Event System** - Event-driven communication between modules
- 🚀 **Performance** - Lazy loading and efficient memory management
- 🛡️ **Type Safety** - Fully type-safe with compile-time error detection

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
  FutureOr<List<Bind<Object>>> binds() => [
   // Bind.singleton<HomeController>((i) => HomeController()),
  ];

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
  FutureOr<List<Bind<Object>>> binds() => [
    Bind.singleton<HomeController>((i) => HomeController()),
  ];

  @override
  List<ModularRoute> get routes => [
    ChildRoute('/', child: (context, state) => HomePage()),
    ChildRoute('/profile', child: (context, state) => ProfilePage()),
  ];
}
```

---

## 🎭 Event System

```dart
class NotificationModule extends EventModule {
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

- 📖 **[Complete Documentation](https://eduardohr-muniz.github.io/go_router_modular/docs/intro)**
- 📦 **[Pub.dev](https://pub.dev/packages/go_router_modular)**
- 🐛 **[Issues](https://github.com/eduardohr-muniz/go_router_modular/issues)**
- ⭐ **[GitHub](https://github.com/eduardohr-muniz/go_router_modular)**

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


