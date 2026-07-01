<!--
  NOTE: pub.dev's README renderer strips `align`, `style` and `class` attributes,
  so centering does NOT apply there — the layout below is designed to look good
  LEFT-ALIGNED. The few <div align="center"> blocks are a harmless bonus on GitHub.
-->

<p align="center">
  <img src="https://raw.githubusercontent.com/eduardohr-muniz/go_router_modular/master/assets/go-router-modular-banner.png" alt="Go Router Modular" />
</p>

<h1 align="center">🧩 GoRouter Modular 💉</h1>

<p align="center"><em>Modular architecture, dependency injection & route management on top of GoRouter.</em></p>

<p align="center">
  <a href="https://pub.dev/packages/go_router_modular"><img src="https://img.shields.io/pub/v/go_router_modular?color=blue&style=for-the-badge" alt="Pub Version" /></a>
  <a href="https://pub.dev/packages/go_router_modular/score"><img src="https://img.shields.io/pub/points/go_router_modular?color=blue&style=for-the-badge" alt="Pub Points" /></a>
  <a href="https://github.com/eduardohr-muniz/go_router_modular"><img src="https://img.shields.io/github/stars/eduardohr-muniz/go_router_modular?color=yellow&style=for-the-badge" alt="GitHub Stars" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green?style=for-the-badge" alt="License" /></a>
</p>

**GoRouter Modular** brings a modular architecture on top of [**GoRouter**](https://pub.dev/packages/go_router), with per-module **dependency injection** and automatic dispose. Split a large app into independent, lazy-loaded feature modules — perfect for **micro frontends** and scalable, team-friendly codebases. 🚀

<p align="center">
  <a href="https://eduardohr-muniz.github.io/go_router_modular/en"><img src="https://img.shields.io/badge/📖%20Read%20the%20Docs-4A90E2?style=for-the-badge&logoColor=white" alt="Read the Docs" height="42" /></a>
</p>

> 💡 **Inspired by [flutter_modular](https://pub.dev/packages/flutter_modular)** by [Flutterando](https://flutterando.com.br) — we're grateful for their contribution to the Flutter ecosystem.

---

## ✨ Features

| | |
|---|---|
| 🧩 **Modular Architecture** | Independent, reusable feature modules |
| 💉 **Dependency Injection** | Built-in DI with automatic dispose |
| 🛣️ **GoRouter Integration** | Type-safe, declarative navigation |
| 🎭 **Event System** | Decoupled, event-driven communication between modules |
| 🚀 **Lazy Loading** | Modules load on demand with efficient memory management |
| 🛡️ **Type Safety** | Fully type-safe with compile-time checks |

---

## 📦 Installation

```bash
flutter pub add go_router_modular
```

---

## 🚀 Quick Start

**1. Configure & run** — bootstrap in `main.dart`:

```dart
import 'package:flutter/foundation.dart'; // kDebugMode
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

import 'src/app_module.dart';
import 'src/app_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Modular.configure(
    appModule: AppModule(),
    initialRoute: '/',
    // Logs only in debug builds — release stays quiet.
    debugLogDiagnostics: kDebugMode,
  );

  runApp(const AppWidget());
}

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) => ModularApp.router(title: 'My App');
}
```

**2. Compose modules** — the root `AppModule` registers app-wide binds and mounts each feature:

```dart
class AppModule extends Module {
  @override
  void binds(Injector i) {
    i
      ..addSingleton<DioClient>((i) => DioClient())
      ..addSingleton<AuthStore>((i) => AuthStore());
  }

  @override
  List<ModularRoute> get routes => [
        ModuleRoute('/', module: HomeModule()),
        ModuleRoute('/profile', module: ProfileModule()),
      ];
}
```

**3. Define a feature module** — its own binds and routes, disposed automatically when you leave it:

```dart
class HomeModule extends Module {
  @override
  void binds(Injector i) => i.addSingleton<HomeController>((i) => HomeController());

  @override
  List<ModularRoute> get routes => [
        ChildRoute(
          '/',
          name: 'home',
          child: (context, state) => HomePage(controller: Modular.get<HomeController>()),
        ),
      ];
}
```

**4. Navigate** — named-only, type-safe:

```dart
context.goNamed('profile');            // replace the stack
context.pushNamed('home');             // push on top
final controller = Modular.get<HomeController>(); // resolve a dependency
```

---

## 🤖 Agent Skill

This repo ships an **Agent Skill** that teaches AI coding agents (Claude Code, Cursor, Codex, OpenCode, and others) the recommended conventions for this package — per-feature route files, **named-only navigation**, typed binds via the `..` cascade, synchronous modules, and `kDebugMode`-gated logs. The agent then applies them automatically when you scaffold routes, modules, or navigation.

Install it into your project with one command (via the [`skills`](https://github.com/vercel-labs/skills) CLI):

```bash
npx skills add eduardohr-muniz/go_router_modular -s go-router-modular
```

The CLI detects your installed agents and drops the skill into the right place (e.g. `.claude/skills/`). Add `-g` to install it globally for every project.

<details>
<summary><strong>Optional — events add-on</strong></summary>

<br>

If your app uses the event system (`EventModule`, `ModularEvent`, `ModularEventMixin`) for decoupled cross-module communication, install the separate events skill too:

```bash
npx skills add eduardohr-muniz/go_router_modular -s go-router-modular-events
```

</details>

---

## 🤝 Contributing

Contributions are very welcome! Open an issue to discuss major changes, then submit a PR with a clear description of the edits.

## 📄 License

Distributed under the **MIT** license. See [`LICENSE`](LICENSE) for details.

---

<p align="center"><em>Transform your Flutter app into a scalable, modular masterpiece.</em> ✨</p>

<p align="center">
  <a href="https://github.com/eduardohr-muniz/go_router_modular/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=eduardohr-muniz/go_router_modular" alt="Contributors" />
  </a>
</p>
