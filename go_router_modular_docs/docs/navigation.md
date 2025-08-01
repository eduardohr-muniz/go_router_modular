---
sidebar_position: 6
title: Navigation
description: Learn all about navigation with GoRouter Modular
---

# 🚦 Navigation

GoRouter Modular offers flexible and powerful navigation for your Flutter apps. This guide covers standard navigation, named navigation, and advanced integration for web.

## 🚀 Standard Navigation

Use the navigation methods directly from the `BuildContext`:

```dart
// Navigate to a route (replaces the current stack)
context.go('/profile');

// Push a new route onto the stack
context.push('/settings');

// Pop the current route
context.pop();

// Replace the current route
context.replace('/dashboard');
```

> **Note:**
> When you use `context.go`, the previous module and its dependencies are disposed. This means the previous module is destroyed, freeing resources and ensuring a clean navigation stack.
>
> **Automatic Bind Disposal:**
> All binds (dependencies) from modules that are removed from the stack are automatically disposed. You don't need to manually clean up resources—GoRouter Modular handles this for you, preventing memory leaks and keeping your app efficient.

## 🏷️ Named Navigation

You can also navigate using named routes, which is useful for more complex apps:

```dart
// Navigate to a named route
context.goNamed('user', pathParameters: {'id': '123'});

// Push a named route
context.pushNamed('settings');
```

Named routes are defined in your module:

```dart
ChildRoute(
  '/user/:id',
  name: 'user',
  child: (context, state) => UserPage(id: state.pathParameters['id']!),
),
```

## 🌐 Advanced Web Integration

For web applications, GoRouter Modular integrates seamlessly with Flutter's navigation system using `RouteInformationParser` and `RouterDelegate`. This ensures that browser navigation (back/forward buttons, URL changes) works as expected.

You don't need to configure this manually—GoRouter Modular handles it for you under the hood. However, if you want to customize the behavior, you can access the underlying router:

```dart
final router = Modular.router;
// Use router.routeInformationParser and router.routerDelegate as needed
```

This allows for advanced scenarios, such as deep linking and custom URL strategies.

## 📚 Related Topics

- 🏗️ [Project Structure](./project-structure) - Organize your modules
- 💉 [Dependency Injection](./dependency-injection) - Manage dependencies
- 🎭 [Event System](./event-system) - Module communication 