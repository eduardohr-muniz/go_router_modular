---
sidebar_position: 5
title: Routes Overview
description: Master routing with GoRouter integration
---

# 🛣️ Routes

GoRouter Modular provides seamless integration with GoRouter for powerful, type-safe navigation.

## 🚀 Route Types



### **Child Routes** - Simple page routes
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

### **Module Routes** - Nested modules
```dart
class AppModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ModuleRoute("/", module: HomeModule()),
    ModuleRoute("/auth", module: AuthModule()),
    ModuleRoute("/user", module: UserModule()),
  ];
}
```

### **Shell Routes** - Shared layouts
```dart
class ShellModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ShellModularRoute(
      builder: (context, state, child) => ShellPage(child: child),
      routes: [
        ChildRoute("/dashboard", child: (context, state) => DashboardPage()),
        ChildRoute("/settings", child: (context, state) => SettingsPage()),
        ChildRoute("/profile", child: (context, state) => ProfilePage()),
      ],
    ),
  ];
}
```

## 🧭 Navigation

### **Basic Navigation**
```dart
// Navigate to route
context.go('/user/123');

// Push route (stack navigation)
context.push('/modal');

// Pop current route
context.pop();

// Replace current route
context.replace('/new-route');
```

### **Navigation with Parameters**
```dart
// Path parameters
context.go('/user/123');

// Extra data
context.go('/user/123', extra: {'userData': userData});
```


## 📋 Route Parameters

### **Path Parameters**
```dart
// Define route with parameter
ChildRoute('/user/:user_name', child: (context, state) => 
  UserPage(id: state.pathParameters['user_name']!)),

// Navigate with parameter
context.go('/user/Eduardo');

// Access parameter
final userId = state.pathParameters['user_name'];
```

### **Query Parameters**
```dart
// Navigate with query parameters
context.go('/search?q=flutter&category=mobile');

// Access query parameters
final query = state.queryParameters['q'];
final category = state.queryParameters['category'];
```

## 🔄 Async Navigation

### **Loading States**
```dart
ElevatedButton(
  onPressed: () async {
    setState(() => isLoading = true);
    // While navigation happens, the bindings are injected    
    try {
      await context.goAsync('/heavy-page');
    
    } finally {
      setState(() => isLoading = false);
    }
  },
  child: Text('Navigate'),
);
```