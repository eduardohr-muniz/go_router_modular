---
sidebar_position: 9
title: Loader System
description: Custom loading indicators and async navigation
---

# 🎯 Loader System

The Loader System provides automatic and manual loading indicators for better user experience during module loading and async operations.

## 🚀 Automatic Loader

The loader automatically appears during:
- Module loading and initialization
- Dependency injection
- Route transitions
- Async navigation

### **Default Behavior**
```dart
class AppWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ModularApp.router(
      title: 'My App',
      theme: ThemeData(primarySwatch: Colors.blue),
      // Automatic loader is enabled by default
    );
  }
}
```

## 🔧 Manual Control

### **Show/Hide Loader**
```dart
// Show loader
ModularLoader.show();

// Hide loader
ModularLoader.hide();

// Show with custom message
ModularLoader.show(message: 'Loading data...');

// Hide with delay
ModularLoader.hide(delay: Duration(milliseconds: 500));
```

### **Usage in Controllers**
```dart
class UserController {
  Future<void> loadUserData() async {
    ModularLoader.show(message: 'Loading user data...');
    
    try {
      await userService.fetchUser();
    } finally {
      ModularLoader.hide();
    }
  }
}
```

## 🎨 Custom Loader

### **Create Custom Loader**
```dart
class MyLoader extends CustomModularLoader {
  @override
  Color get backgroundColor => Colors.black87;

  @override
  Widget get child => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      CircularProgressIndicator(color: Colors.blue),
      SizedBox(height: 16),
      Text('Loading...', style: TextStyle(color: Colors.white)),
    ],
  );
}
```

### **Use Custom Loader**
```dart
class AppWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ModularApp.router(
      customModularLoader: MyLoader(),
      title: 'My App',
    );
  }
}
```

### **Advanced Custom Loader**
```dart
class AnimatedLoader extends CustomModularLoader {
  @override
  Color get backgroundColor => Colors.black.withOpacity(0.8);

  @override
  Widget get child => Container(
    padding: EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Loading...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
      ],
    ),
  );
}
```

## 🔄 Async Navigation

### **Basic Async Navigation**
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
    ModularLoader.show(message: 'Preparing data...');
    
    try {
      // Pre-load data before navigation
      await userService.loadUserData();
      await productService.loadProducts();
      
      context.go('/dashboard');
    } finally {
      ModularLoader.hide();
    }
  },
  child: Text('Load Dashboard'),
);
```

### **Conditional Loading**
```dart
ElevatedButton(
  onPressed: () async {
    if (needsDataRefresh) {
      ModularLoader.show(message: 'Refreshing data...');
      await refreshData();
      ModularLoader.hide();
    }
    
    context.go('/next-page');
  },
  child: Text('Continue'),
);
```

## 🎯 Advanced Patterns

### **Loader with Progress**
```dart
class ProgressLoader extends CustomModularLoader {
  final double progress;
  
  ProgressLoader(this.progress);
  
  @override
  Widget get child => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      CircularProgressIndicator(value: progress),
      SizedBox(height: 16),
      Text('${(progress * 100).toInt()}% Complete'),
    ],
  );
}

// Usage
ModularLoader.show(customLoader: ProgressLoader(0.5));
```

### **Loader with Actions**
```dart
class ActionLoader extends CustomModularLoader {
  final VoidCallback? onCancel;
  
  ActionLoader({this.onCancel});
  
  @override
  Widget get child => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      CircularProgressIndicator(),
      SizedBox(height: 16),
      Text('Processing...'),
      if (onCancel != null) ...[
        SizedBox(height: 16),
        TextButton(
          onPressed: onCancel,
          child: Text('Cancel'),
        ),
      ],
    ],
  );
}

// Usage
ModularLoader.show(
  customLoader: ActionLoader(
    onCancel: () {
      ModularLoader.hide();
      // Cancel operation
    },
  ),
);
```

### **Module-Specific Loaders**
```dart
class AuthModule extends Module {
  @override
  void initState(Injector i) {
    // Show custom loader for auth module
    ModularLoader.show(
      customLoader: AuthLoader(),
      message: 'Initializing authentication...',
    );
  }
  
  @override
  void dispose() {
    ModularLoader.hide();
  }
}

class AuthLoader extends CustomModularLoader {
  @override
  Widget get child => Column(
    children: [
      Icon(Icons.security, color: Colors.blue, size: 48),
      SizedBox(height: 16),
      Text('Authenticating...'),
    ],
  );
}
```

## 🛡️ Best Practices

### **1. Always Hide Loader**
```dart
// ✅ Good - Always hide loader
try {
  ModularLoader.show();
  await heavyOperation();
} finally {
  ModularLoader.hide();
}

// ❌ Avoid - Might not hide on error
ModularLoader.show();
await heavyOperation();
ModularLoader.hide(); // Won't execute if error occurs
```

### **2. Use Descriptive Messages**
```dart
// ✅ Good - Clear message
ModularLoader.show(message: 'Loading user profile...');

// ❌ Avoid - Generic message
ModularLoader.show(message: 'Loading...');
```

### **3. Consider User Experience**
```dart
// ✅ Good - Show loader only for long operations
if (operationDuration > Duration(milliseconds: 500)) {
  ModularLoader.show();
}

// ❌ Avoid - Show loader for quick operations
ModularLoader.show(); // For operations < 100ms
```

## 📚 Related Topics

- 🛣️ [Routes](./routes) - Async navigation patterns
- 💉 [Dependency Injection](./dependency-injection) - Module initialization
- 🎭 [Event System](./event-system) - Event-driven loading 