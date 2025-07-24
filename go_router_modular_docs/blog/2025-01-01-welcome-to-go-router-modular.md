---
slug: welcome-to-go-router-modular
title: 🎉 Welcome to GoRouter Modular!
authors: [eduardo]
tags: [flutter, modular, architecture, release]
---

# 🎉 Welcome to GoRouter Modular!

We're excited to introduce **GoRouter Modular** - a powerful solution for building scalable Flutter applications with modular architecture!

<!-- truncate -->

## 🚀 What is GoRouter Modular?

GoRouter Modular is a comprehensive framework that brings **modular architecture** to Flutter applications, offering:

- **🧩 Modular Architecture** - Organize your app into independent, reusable modules
- **💉 Dependency Injection** - Per-module DI with automatic lifecycle management  
- **🛣️ GoRouter Integration** - Seamless routing with type safety
- **🎭 Event System** - Decoupled communication between modules
- **🎯 Custom Loaders** - Built-in loading system

## 🏗️ Perfect for Teams

GoRouter Modular shines in **team environments** where:

- Different teams work on different features
- Modules need to communicate without tight coupling
- Scalability and maintainability are priorities
- **Micro frontend** architecture is desired

## 🎭 Event-Driven Communication

One of our favorite features is the **Event System**:

```dart
// Fire events from anywhere
modularEvent.fire(UserLoggedInEvent(user: user));

// Listen in any module
on<UserLoggedInEvent>((event, context) {
  // Handle user login across modules
});
```

This allows teams to work **independently** while maintaining seamless integration!

## 🚀 Get Started Today

Ready to build your first modular Flutter app?

1. **[📦 Install GoRouter Modular](/docs/installation)**
2. **[🚀 Follow our Getting Started guide](/docs/getting-started)**
3. **[🎭 Explore the Event System](/docs/event-system)**

## 💙 Community

Join our growing community:

- **⭐ [Star us on GitHub](https://github.com/eduardohr-muniz/go_router_modular)**
- **📦 [Check us out on pub.dev](https://pub.dev/packages/go_router_modular)**
- **🐛 [Report issues and request features](https://github.com/eduardohr-muniz/go_router_modular/issues)**

We can't wait to see what amazing applications you'll build with GoRouter Modular! 🎯

---

**Happy coding!** 💙  
*The GoRouter Modular Team* 