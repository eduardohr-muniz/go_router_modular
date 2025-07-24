---
sidebar_position: 7
title: Shell 
description: Learn all about Shell Modules with GoRouter Modular
---

# 🐚 Shell Modules

<!-- Example GIF placeholder removed. Insert your GIF here in the future if desired. -->

> **Warning**
> A Shell Module cannot have a `/` (root) route. Defining a root route inside a Shell Module will cause navigation errors and is not supported. Always use specific subpaths (e.g., `/dashboard`, `/settings`) for child routes inside a shell. This is a common pitfall and is emphasized in the official Docusaurus documentation as well.

Shell Modules in GoRouter Modular allow you to create shared layouts and navigation structures that persist across multiple child routes. This is especially useful for apps with bottom navigation bars, tab bars, or persistent side menus.

## 🧐 What is a Shell Module?

A Shell Module is a special type of module that wraps a set of routes with a common UI structure. It uses `ShellModularRoute` to define a shared layout and manage navigation between its child routes.

## 🚦 When to Use Shell Modules?
- When you need a persistent navigation bar (bottom/tab/side) across multiple pages
- For dashboards, admin panels, or apps with complex navigation hierarchies
- To keep state or widgets alive while navigating between child routes

## 📝 Basic Example

```dart
class ShellModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ShellModularRoute(
      builder: (context, state, child) => ShellPage(child: child),
      routes: [
        ChildRoute('/dashboard', child: (context, state) => DashboardPage()),
        ChildRoute('/settings', child: (context, state) => SettingsPage()),
        ChildRoute('/profile', child: (context, state) => ProfilePage()),
      ],
    ),
  ];
}
```

In this example, `ShellPage` is a widget that receives the current child route as its `child` parameter. You can use this to display a navigation bar, drawer, or any persistent UI element.

## 🧭 Internal Navigation Example

```dart
class ShellPage extends StatelessWidget {
  final Widget child;
  const ShellPage({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Shell Example')),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              context.go('/settings');
              break;
            case 2:
              context.go('/profile');
              break;
          }
        },
      ),
    );
  }
}
```

## 💡 Tips
- The `child` parameter in the builder is the currently active route inside the shell.
- You can keep stateful widgets alive (like navigation bars or controllers) while switching between child routes.
- Shell Modules can be nested for advanced layouts.
- Use unique paths for each child route to avoid navigation conflicts.

## 📚 Related Topics
- [Routes Overview](./routes_overview) - Learn about all route types
- [Navigation](./navigation) - How navigation works
- [Project Structure](./project-structure) - Organize your modules

