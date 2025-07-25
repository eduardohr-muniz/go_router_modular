---
sidebar_position: 11
title: Micro Frontend Architecture
description: Build scalable apps with independent team development
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

<a className="button button--primary button--lg" href="https://pub.dev/packages/melos" target="_blank" style={{marginBottom: '1em'}}>
  Melos on pub.dev
</a>

> **Melos** is a powerful tool for managing monorepos in Flutter and Dart. It helps you organize, bootstrap, and automate tasks across multiple packages and apps in a single repository.

> **Why is this SOLID?**
> This architecture helps you follow SOLID principles, especially the Dependency Inversion and Single Responsibility principles. Each module is independent and does not rely on external implementations or other modules directly. Communication happens only through well-defined events, making your codebase more maintainable, testable, and robust.

# 🧩 Micro Frontend (Monorepo) — The Simple Way

A micro frontend architecture lets you split your app into independent modules, so each team or developer can work without interfering with others. The best way to organize this in Flutter is with a **monorepo** using [Melos](https://melos.invertase.dev/).

## 📦 Recommended Monorepo Structure

```
📁 apps/
│   └── 📁 main_app/           # Your main Flutter app
│       └── ...
📁 features/
│   ├── 📁 cart/               # Cart feature module
│   ├── 📁 product/            # Product feature module
│   └── 📁 payment/            # Payment feature module
📁 packages/
│   └── 📁 shared_utils/       # Shared code, events, services, etc.
└── melos.yaml                 # Melos workspace config
```

- **apps/**: Where your main app(s) live
- **features/**: Each feature is a Dart/Flutter package (independent)
- **packages/**: Shared code, events, services, UI, etc.

## 🚀 Why Use Melos?
- Manages dependencies and scripts for all packages
- Makes it easy to run tests, analyze, or publish for the whole repo
- Standard for Flutter monorepos

**To get started:**
```bash
flutter pub global activate melos
melos init
```

## 🛠️ How to Create a Feature Package

1. **Create a new package:**
   ```bash
   melos create feature_cart --template=package --path=features/cart
   ```
2. **Add your code:**
   - Place your module, pages, controllers, etc. inside `features/cart/lib/`
3. **Export your module:**
   - In `features/cart/lib/cart_module.dart`, export your main module class.
4. **Add to your app:**
   - In `apps/main_app/pubspec.yaml`, add:
     ```yaml
     dependencies:
       feature_cart:
         path: ../../features/cart
     ```
5. **Import and use in your app:**
   ```dart
   import 'package:feature_cart/cart_module.dart';
   ```

## ⚡️ Advantages & Disadvantages

### ✅ Advantages
- **Team independence:** Each team works on their own module, no merge conflicts
- **Scalability:** Add new features as new packages
- **Isolation:** Bugs and changes in one module don’t break others
- **Reusability:** Shared code in `packages/` is easy to maintain
- **Faster CI:** Test/build only what changed

### ⚠️ Disadvantages
- **Initial setup:** Monorepo and Melos require some configuration
- **Versioning:** Need to manage versions for shared packages
- **Learning curve:** Teams must understand package boundaries

## 🔗 Module Communication with EventModule

Modules should **never** import each other directly. Instead, use the `EventModule` system for communication:

```dart
// In features/auth/lib/auth_module.dart
class AuthModule extends EventModule {
  @override
  void listen() {
    on<LoginSuccessEvent>((event, context) {
      if (context != null) context.go('/dashboard');
    });
  }
}

// In features/cart/lib/cart_module.dart
// Fire an event to notify other modules
ModularEvent.fire(LoginSuccessEvent());
```

- **Events** are defined in a shared package (e.g., `packages/shared_utils/lib/events.dart`)
- Any module can listen or fire events, keeping everything decoupled

## 🧑‍💻 Example: Adding a New Feature

1. `melos create feature_orders --template=package --path=features/orders`
2. Add your module code in `features/orders/`
3. Export your module and add it to your app’s dependencies
4. Communicate with other modules only via events

## 📚 Related Topics
- 🎭 [Event System](./event-system) - Module communication
- 🏗️ [Project Structure](./project-structure) - Team organization
- 💉 [Dependency Injection](./dependency-injection) - Module dependencies 