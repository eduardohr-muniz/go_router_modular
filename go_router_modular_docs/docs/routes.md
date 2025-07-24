---
sidebar_position: 7
title: Routes
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

// Query parameters
context.go(Uri(path: '/search', queryParameters: {'q': 'flutter'}).toString());

// Extra data
context.go('/user/123', extra: {'userData': userData});
```

### **Navigation with State**
```dart
// Navigate and pass state
context.go('/user/123', extra: {
  'user': user,
  'fromPage': 'home',
});

// Access state in route
class UserPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = GoRouterState.of(context).extra?['user'] as User?;
    final fromPage = GoRouterState.of(context).extra?['fromPage'] as String?;
    
    return Scaffold(
      body: Text('User: ${user?.name} from $fromPage'),
    );
  }
}
```

## 📋 Route Parameters

### **Path Parameters**
```dart
// Define route with parameter
ChildRoute('/user/:id', child: (context, state) => 
  UserPage(id: state.pathParameters['id']!)),

// Navigate with parameter
context.go('/user/123');

// Access parameter
final userId = state.pathParameters['id'];
```

### **Query Parameters**
```dart
// Navigate with query parameters
context.go('/search?q=flutter&category=mobile');

// Access query parameters
final query = state.queryParameters['q'];
final category = state.queryParameters['category'];
```

### **Optional Parameters**
```dart
// Route with optional parameter
ChildRoute('/products/:category?', child: (context, state) => 
  ProductsPage(category: state.pathParameters['category'])),

// Navigate with or without parameter
context.go('/products'); // category = null
context.go('/products/electronics'); // category = 'electronics'
```

## 🎯 Advanced Routing

### **Guarded Routes**
```dart
class AuthModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ChildRoute('/', child: (context, state) => LoginPage()),
    ChildRoute('/dashboard', child: (context, state) => DashboardPage()),
  ];

  @override
  void initState(Injector i) {
    // Add route guards
    final router = Modular.router;
    router.addRedirect('/dashboard', (context, state) {
      final authService = Modular.get<AuthService>();
      return authService.isAuthenticated ? null : '/';
    });
  }
}
```

### **Nested Routes**
```dart
class UserModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ChildRoute('/', child: (context, state) => UserListPage()),
    ChildRoute('/:id', child: (context, state) => UserDetailPage(
      id: state.pathParameters['id']!,
    )),
    ChildRoute('/:id/edit', child: (context, state) => UserEditPage(
      id: state.pathParameters['id']!,
    )),
  ];
}
```

### **Modal Routes**
```dart
class HomeModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ChildRoute('/', child: (context, state) => HomePage()),
    ChildRoute('/modal', child: (context, state) => ModalPage()),
  ];
}

// Navigate to modal
context.push('/modal');
```

## 🔄 Async Navigation

### **Loading States**
```dart
ElevatedButton(
  onPressed: () async {
    setState(() => isLoading = true);
    
    try {
      await context.goAsync('/heavy-page');
    } finally {
      setState(() => isLoading = false);
    }
  },
  child: Text('Navigate'),
);
```

### **Pre-loading Data**
```dart
ElevatedButton(
  onPressed: () async {
    // Pre-load data before navigation
    await userService.loadUserData();
    context.go('/user-details');
  },
  child: Text('Load User'),
);
```

## 🎨 Route Transitions

### **Custom Transitions**
```dart
ChildRoute(
  '/fade-page',
  child: (context, state) => FadePage(),
  transition: TransitionType.fadeIn,
),
```

### **Available Transitions**
- `TransitionType.fadeIn`
- `TransitionType.rightToLeft`
- `TransitionType.leftToRight`
- `TransitionType.upToDown`
- `TransitionType.downToUp`
- `TransitionType.noTransition`

## 📚 Related Topics

- 🏗️ [Project Structure](./project-structure) - Organize your modules
- 💉 [Dependency Injection](./dependency-injection) - Manage dependencies
- 🎭 [Event System](./event-system) - Module communication 