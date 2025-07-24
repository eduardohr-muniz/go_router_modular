---
sidebar_position: 13
title: Project Structure
description: Clean, modular, and SOLID folder organization for scalable Flutter apps
---

# 🏗️ Project Structure (Clean Architecture + SOLID)

Organize your modular Flutter app following Clean Architecture and SOLID principles for maximum scalability, testability, and maintainability.

## 📁 Recommended Structure (per module)

```
lib/
└── src/
    └── modules/
        ├── 📁 user/           # example feature
        │   ├── 📁 domain/
        │   │   ├── 📁 entities/
        │   │   │   └── 📄 user.dart
        │   │   ├── 📁 repositories/
        │   │   │   └── 📄 user_repository.dart
        │   │   └── 📁 usecases/
        │   │       └── 📄 get_user.dart
        │   ├── 📁 data/
        │   │   ├── 📁 datasources/
        │   │   │   └── 📄 user_remote_datasource.dart
        │   │   ├── 📁 repositories/
        │   │   │   └── 📄 user_repository_impl.dart
        │   │   └── 📁 models/
        │   │       └── 📄 user_model.dart
        │   ├── 📁 presentation/
        │   │   ├── 📁 controllers/
        │   │   │   └── 📄 user_controller.dart
        │   │   ├── 📁 pages/
        │   │   │   └── 📄 user_page.dart
        │   │   └── 📁 widgets/
        │   │       └── 📄 user_card.dart
        │   └── 📄 user_module.dart
        ├── 📁 auth/           # another feature
        │   ├── 📁 domain/
        │   │   ├── 📁 entities/
        │   │   └── 📁 repositories/
        │   │   └── 📁 usecases/
        │   ├── 📁 data/
        │   │   ├── 📁 datasources/
        │   │   ├── 📁 repositories/
        │   │   └── 📁 models/
        │   ├── 📁 presentation/
        │   │   ├── 📁 controllers/
        │   │   ├── 📁 pages/
        │   │   └── 📁 widgets/
        │   └── 📄 auth_module.dart
        ├── 📁 product/        # another feature
        │   ├── 📁 domain/
        │   │   ├── 📁 entities/
        │   │   ├── 📁 repositories/
        │   │   └── 📁 usecases/
        │   ├── 📁 data/
        │   │   ├── 📁 datasources/
        │   │   ├── 📁 repositories/
        │   │   └── 📁 models/
        │   ├── 📁 presentation/
        │   │   ├── 📁 controllers/
        │   │   ├── 📁 pages/
        │   │   └── 📁 widgets/
        │   └── 📄 product_module.dart
        └── 📁 shared/
            ├── 📁 domain/
            ├── 📁 data/
            ├── 📁 presentation/
            └── 📄 shared_module.dart
    ├── 📄 app_module.dart
    ├── 📄 app_widget.dart
└── 📄 main.dart
```

## 🧩 Layered Module Organization

Each module should be self-contained and follow the separation of concerns:

- **Domain**: Business logic, entities, repositories (abstract), use cases
- **Data**: Data sources (API, DB), models, repository implementations
- **Presentation**: UI, controllers, widgets, pages

> **Note**
> Each module must be responsible only for its own feature. Avoid cross-module dependencies and keep boundaries clear. A module should work independently, respecting the Single Responsibility Principle (SRP).



## 💡 Best Practices

- **Single Responsibility**: Each module should encapsulate only its own feature logic.
- **No Cross-Feature Imports**: Use shared module for truly global code only.
- **Explicit APIs**: Expose only what is necessary from each module.
- **Testability**: Keep business logic in domain layer for easy testing.
- **SOLID Principles**: Apply SOLID in all layers for maintainability.
- **Scalability**: This structure supports large teams and codebases.

## 📚 Related Topics

- 💉 [Dependency Injection](./dependency-injection) - Manage module dependencies
- 🛣️ [Routes](./routes) - Define module routes
- 🎭 [Event System](./event-system) - Module communication 