---
sidebar_position: 5
title: Project Structure
description: Recommended folder organization for modular Flutter apps
---

# 🏗️ Project Structure

Organize your modular Flutter app with clear boundaries and responsibilities.

## 📁 Recommended Structure

```
📁 lib/
  📁 src/
    📁 modules/
      📁 auth/
        📄 auth_module.dart
        📄 auth_controller.dart
        📁 pages/
          📄 login_page.dart
          📄 register_page.dart
        📁 services/
          📄 auth_service.dart
      📁 home/
        📄 home_module.dart
        📄 home_controller.dart
        📁 pages/
          📄 home_page.dart
          📄 dashboard_page.dart
        📁 widgets/
          📄 home_card.dart
      📁 shared/
        📄 shared_module.dart
        📁 services/
          📄 api_service.dart
        📁 widgets/
          📄 loading_widget.dart
    📄 app_module.dart
    📄 app_widget.dart
  📄 main.dart
```

## 🧩 Module Organization

### **Module Structure**
Each module should contain:
- **Module class** - Main module definition
- **Controllers** - Business logic
- **Pages** - UI screens
- **Services** - External dependencies
- **Widgets** - Reusable components

### **Shared Module**
Common functionality across modules:
- Global services
- Shared widgets
- Utilities
- Constants

## 📋 Best Practices

### **1. Clear Boundaries**
- Each module is independent
- Minimal cross-module dependencies
- Clear public APIs

### **2. Consistent Naming**
- `*_module.dart` for modules
- `*_controller.dart` for controllers
- `*_page.dart` for pages
- `*_service.dart` for services

### **3. Feature-based Organization**
- Group related functionality
- Keep modules focused
- Avoid monolithic modules

### **4. Dependency Management**
- Use dependency injection
- Avoid direct imports between modules
- Use events for communication

## 🎯 Example Module

```dart
// auth_module.dart
class AuthModule extends Module {
  @override
  FutureOr<List<Bind<Object>>> binds() => [
    Bind.singleton<AuthController>((i) => AuthController()),
    Bind.singleton<AuthService>((i) => AuthService()),
  ];

  @override
  List<ModularRoute> get routes => [
    ChildRoute('/', child: (context, state) => LoginPage()),
    ChildRoute('/register', child: (context, state) => RegisterPage()),
  ];
}
```

## 📚 Related Topics

- 💉 [Dependency Injection](./dependency-injection) - Manage module dependencies
- 🛣️ [Routes](./routes) - Define module routes
- 🎭 [Event System](./event-system) - Module communication 