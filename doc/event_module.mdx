# EventModule Technical Documentation

A comprehensive event-driven architecture system for Flutter applications using go_router_modular.

## Table of Contents

- [Overview](#overview)
- [Core Concepts](#core-concepts)
- [Installation & Setup](#installation--setup)
- [Basic Usage](#basic-usage)
- [Advanced Features](#advanced-features)
- [API Reference](#api-reference)
- [Best Practices](#best-practices)
- [Performance Considerations](#performance-considerations)
- [Migration Guide](#migration-guide)
- [Troubleshooting](#troubleshooting)

## Overview

EventModule provides a robust event-driven communication system that enables decoupled architecture between different parts of your Flutter application. It supports both regular and exclusive event handling with automatic memory management.

### Key Features

- ✅ **Decoupled Communication** - Modules communicate without direct dependencies
- ✅ **Exclusive Event Handling** - FIFO queue system for exclusive listeners
- ✅ **Automatic Memory Management** - Prevents memory leaks with auto-dispose
- ✅ **Context-Aware Events** - Automatic NavigatorState context injection
- ✅ **Custom EventBus Support** - Isolate events between different systems
- ✅ **TypeSafe Events** - Compile-time type checking for all events
- ✅ **Hot Reload Support** - Maintains state during development

## Core Concepts

### Event Types

Events are simple data classes that carry information:

```dart
class UserLoginEvent {
  final String userId;
  final String username;
  final DateTime timestamp;

  UserLoginEvent({
    required this.userId,
    required this.username,
    required this.timestamp,
  });
}

class ApiErrorEvent {
  final String endpoint;
  final int statusCode;
  final String message;

  ApiErrorEvent({
    required this.endpoint,
    required this.statusCode,
    required this.message,
  });
}
```

### EventModule

Abstract base class for creating event-driven modules:

```dart
class AuthModule extends EventModule {
  @override
  List<ModularRoute> get routes => [
    ChildRoute('/login', child: (context, state) => LoginPage()),
    ChildRoute('/register', child: (context, state) => RegisterPage()),
  ];

  @override
  void listen() {
    // Handle user login events
    on<UserLoginEvent>((UserLoginEvent event, BuildContext? context) {
      print('User ${event.username} logged in at ${event.timestamp}');
      if (context != null) {
        context.go('/dashboard');
      }
    });

    // Handle user logout events
    on<UserLogoutEvent>((UserLogoutEvent event, BuildContext? context) {
      print('User ${event.username} logged out');
      if (context != null) {
        context.go('/login');
      }
    });

    // Handle API errors (exclusive - only one handler at a time)
    on<ApiErrorEvent>((ApiErrorEvent event, BuildContext? context) {
      print('API Error on ${event.endpoint}: ${event.message}');
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${event.message}')),
        );
      }
    }, exclusive: true);
  }
}
```

### ModularEvent

Global event dispatcher for firing events from anywhere in your application:

```dart
// Fire events from anywhere
ModularEvent.fire(UserLoginEvent(
  userId: '123',
  username: 'john_doe',
  timestamp: DateTime.now(),
));

// Listen to events globally (outside modules)
ModularEvent.instance.on<UserLoginEvent>((UserLoginEvent event, BuildContext? context) {
  print('User ${event.username} logged in');
});
```

## Installation & Setup

### 1. Configure GoRouterModular in main.dart

The EventModule system is configured through `GoRouterModular.configure()` in your `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure GoRouterModular with EventBus settings
  await GoRouterModular.configure(
    appModule: AppModule(), // Your root module
    initialRoute: '/login',
    
    // EventBus Configuration
    debugLogEventBus: true,     // Enable event logging (🔥🎭 logs)
    autoDisposeEventsBus: true, // Auto-dispose listeners when modules are destroyed
    
    // Other GoRouter settings
    debugLogDiagnosticsGoRouter: false,
    delayDisposeMilliseconds: 1000,
  );
  
  runApp(MyApp());
}
```

### 2. Create Your App Widget

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'My App',
      routerConfig: GoRouterModular.routerConfig,
    );
  }
}
```

### 3. Create Your Root Module

```dart
class AppModule extends Module {
  @override
  List<Module> get imports => [
    AuthModule(),
    ShoppingModule(),
    NotificationModule(),
  ];

  @override
  List<ModularRoute> get routes => [
    ChildRoute('/', child: (context, state) => HomePage()),
    ChildRoute('/login', child: (context, state) => LoginPage()),
  ];
}
```

## Basic Usage

### Creating Events

```dart
// Simple event
class ButtonClickedEvent {
  final String buttonId;
  ButtonClickedEvent(this.buttonId);
}

// Complex event with multiple properties
class ShoppingCartUpdatedEvent {
  final String userId;
  final List<CartItem> items;
  final double totalPrice;
  final DateTime timestamp;

  ShoppingCartUpdatedEvent({
    required this.userId,
    required this.items,
    required this.totalPrice,
    required this.timestamp,
  });
}

// Event with optional properties
class NotificationEvent {
  final String title;
  final String message;
  final NotificationType type;
  final Duration? duration;

  NotificationEvent({
    required this.title,
    required this.message,
    required this.type,
    this.duration,
  });
}
```

### Creating EventModules

```dart
class ShoppingModule extends EventModule {
  final CartService _cartService = CartService();

  @override
  List<ModularRoute> get routes => [
    ChildRoute('/shop', child: (context, state) => ShopPage()),
    ChildRoute('/cart', child: (context, state) => CartPage()),
    ChildRoute('/checkout', child: (context, state) => CheckoutPage()),
  ];

  @override
  void listen() {
    // Regular listeners (all receive events)
    on<AddToCartEvent>((AddToCartEvent event, BuildContext? context) {
      _cartService.addItem(event.item);
      
      // Fire another event
      ModularEvent.fire(ShoppingCartUpdatedEvent(
        userId: event.userId,
        items: _cartService.items,
        totalPrice: _cartService.totalPrice,
        timestamp: DateTime.now(),
      ));
      
      // Navigate if needed
      if (context != null && event.goToCart) {
        context.go('/cart');
      }
    });

    on<RemoveFromCartEvent>((RemoveFromCartEvent event, BuildContext? context) {
      _cartService.removeItem(event.itemId);
      
      // Fire cart updated event
      ModularEvent.fire(ShoppingCartUpdatedEvent(
        userId: event.userId,
        items: _cartService.items,
        totalPrice: _cartService.totalPrice,
        timestamp: DateTime.now(),
      ));
    });
    
    // Exclusive listener (only one active at a time)
    on<ProcessPaymentEvent>((ProcessPaymentEvent event, BuildContext? context) {
      // Only one payment can be processed at a time
      // Other payment attempts will queue up
      print('Processing payment for ${event.amount}');
      _processPayment(event.paymentData);
    }, exclusive: true);
    
    // Persistent listener (survives module disposal)
    on<AppStartEvent>((AppStartEvent event, BuildContext? context) {
      // Initialize cart when app starts
      _cartService.initialize();
      print('Cart service initialized');
    }, autoDispose: false);
  }
}
```

### Firing Events

```dart
class ShopPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemBuilder: (context, index) {
          return ProductTile(
            product: products[index],
            onAddToCart: () {
              // Fire event when button is pressed
              ModularEvent.fire(AddToCartEvent(
                userId: currentUserId,
                item: products[index],
                goToCart: false,
              ));
            },
          );
        },
      ),
    );
  }
}
```

## Advanced Features

### Exclusive Event Handling

Exclusive events use a FIFO queue system where only one listener is active at a time:

```dart
class PaymentModule extends EventModule {
  @override
  void listen() {
    // Only one payment processor can be active
    on<ProcessPaymentEvent>((ProcessPaymentEvent event, BuildContext? context) {
      _processPayment(event);
    }, exclusive: true);
  }
}

class BackupPaymentModule extends EventModule {
  @override
  void listen() {
    // This will queue behind PaymentModule
    on<ProcessPaymentEvent>((ProcessPaymentEvent event, BuildContext? context) {
      _processPaymentBackup(event);
    }, exclusive: true);
  }
}

// When PaymentModule is disposed, BackupPaymentModule automatically becomes active
```

### Custom EventBus

Isolate events between different systems:

```dart
class AnalyticsModule extends EventModule {
  final EventBus analyticsEventBus = EventBus();

  AnalyticsModule() : super(eventBus: analyticsEventBus);

  @override
  void listen() {
    // Only listens to events fired on analyticsEventBus
    on<AnalyticsEvent>((AnalyticsEvent event, BuildContext? context) {
      print('Tracking: ${event.action} at ${event.timestamp}');
      _analytics.track(event.action, event.properties);
    });
  }
}

// Fire events to specific EventBus
ModularEvent.fire(
  AnalyticsEvent(action: 'button_click'),
  eventBus: analyticsEventBus,
);
```

### Context Handling

The `context` parameter provides access to the current NavigatorState:

```dart
on<NavigationEvent>((NavigationEvent event, BuildContext? context) {
  if (context != null) {
    // Safe to navigate
    context.go(event.route);
    
    // Access other context features
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    
    // Show dialogs
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: Text(event.message),
      ),
    );
  } else {
    // Context not available (e.g., during app initialization)
    // Handle gracefully or defer the action
    _deferredActions.add(() => context?.go(event.route));
  }
});
```

### Memory Management

```dart
class TemporaryModule extends EventModule {
  @override
  void listen() {
    // Auto-disposed when module is disposed (default)
    on<TempEvent>((TempEvent event, BuildContext? context) {
      print('Handling temporary event: ${event.data}');
      // This listener will be automatically disposed
    }, autoDispose: true);
    
    // Survives module disposal (use carefully!)
    on<GlobalEvent>((GlobalEvent event, BuildContext? context) {
      print('Handling global event: ${event.message}');
      // This listener will survive module disposal
    }, autoDispose: false);
  }

  @override
  void dispose() {
    // Clean up custom resources
    _customSubscription?.cancel();
    _timer?.cancel();
    
    // Parent handles event subscriptions automatically
    super.dispose();
  }
}
```

## API Reference

### EventModule

#### Abstract Methods

```dart
abstract class EventModule extends Module {
  // Implement to define event listeners
  void listen();
}
```

#### Event Registration

```dart
void on<T>(
  void Function(T event, BuildContext? context) callback, {
  bool? autoDispose,      // Auto-dispose when module is destroyed
  bool exclusive = false, // Use exclusive queue system
})

// Example usage:
on<MyEvent>((MyEvent event, BuildContext? context) {
  // Handle the event...
});
```

#### Lifecycle Methods

```dart
@override
void initState(Injector i) {
  // Called when module is initialized
  // listen() is called automatically
}

@override
void dispose() {
  // Called when module is destroyed
  // Event subscriptions are cleaned automatically
}
```

### ModularEvent

#### Static Methods

```dart
// Fire event globally
static void fire<T>(T event, {EventBus? eventBus})
```

#### Instance Methods

```dart
// Register global listener
void on<T>(
  void Function(T event, BuildContext? context) callback, {
  EventBus? eventBus,
  bool exclusive = false,
})

// Example usage:
ModularEvent.instance.on<MyEvent>((MyEvent event, BuildContext? context) {
  // Handle the event...
});

// Remove specific listener
void dispose<T>({EventBus? eventBus})
```

### GoRouterModular Configuration Parameters

```dart
// Available EventBus configuration parameters in GoRouterModular.configure()
await GoRouterModular.configure(
  appModule: AppModule(),                // Required: Root module
  initialRoute: '/home',                // Required: Initial route
  
  // EventBus specific parameters
  debugLogEventBus: true,               // Enable 🔥🎭 event logs (default: false)
  autoDisposeEventsBus: true,           // Auto-dispose listeners (default: true)
  
  // Other parameters
  delayDisposeMilliseconds: 1000,       // Delay before disposing modules (default: 1000)
  debugLogDiagnosticsGoRouter: false,   // GoRouter debug logs (default: false)
  // ... other GoRouter parameters
);
```

## Best Practices

### 1. Event Design

```dart
// ✅ GOOD: Immutable events with clear purpose
class UserProfileUpdatedEvent {
  final String userId;
  final UserProfile profile;
  final DateTime updatedAt;

  const UserProfileUpdatedEvent({
    required this.userId,
    required this.profile,
    required this.updatedAt,
  });
}

// ❌ BAD: Mutable events with unclear purpose
class GenericUpdateEvent {
  String? data;
  Map<String, dynamic>? payload;
}
```

### 2. Context Handling

```dart
// ✅ GOOD: Always check context
on<NavigationEvent>((NavigationEvent event, BuildContext? context) {
  if (context != null) {
    context.go(event.route);
  } else {
    // Handle gracefully
    _logger.warning('Navigation attempted without context');
  }
});

// ❌ BAD: Assuming context is available
on<NavigationEvent>((NavigationEvent event, BuildContext? context) {
  context!.go(event.route); // May throw!
});
```

### 3. Error Handling

```dart
// ✅ GOOD: Proper error handling
on<ApiCallEvent>((ApiCallEvent event, BuildContext? context) async {
  try {
    final result = await apiService.call(event.endpoint);
    ModularEvent.fire(ApiSuccessEvent(result));
  } catch (error) {
    ModularEvent.fire(ApiErrorEvent(
      endpoint: event.endpoint,
      error: error.toString(),
    ));
  }
});
```

### 4. Module Organization

```dart
// ✅ GOOD: Focused modules with single responsibility
class AuthModule extends EventModule {
  // Only handles authentication-related events
}

class ShoppingModule extends EventModule {
  // Only handles shopping-related events
}

// ❌ BAD: God module handling everything
class AppModule extends EventModule {
  // Handles auth, shopping, notifications, analytics, etc.
}
```

### 5. Event Naming

```dart
// ✅ GOOD: Descriptive event names
class UserLoginSucceededEvent { }
class ShoppingCartItemAddedEvent { }
class PaymentProcessingStartedEvent { }

// ❌ BAD: Generic event names
class UserEvent { }
class DataEvent { }
class ActionEvent { }
```

## Performance Considerations

### 1. Event Frequency

```dart
// ✅ GOOD: Debounced high-frequency events
class SearchModule extends EventModule {
  Timer? _debounceTimer;

  @override
  void listen() {
    on<SearchQueryChangedEvent>((SearchQueryChangedEvent event, BuildContext? context) {
      // Debounce search to avoid too many API calls
      _debounceTimer?.cancel();
      _debounceTimer = Timer(Duration(milliseconds: 300), () {
        _performSearch(event.query);
      });
    });
  }
}

// ❌ BAD: High-frequency events without debouncing
on<MouseMoveEvent>((MouseMoveEvent event, BuildContext? context) {
  _performExpensiveOperation(); // Called on every mouse move!
});
```

### 2. Memory Management

```dart
// ✅ GOOD: Clean up custom resources
@override
void dispose() {
  _customController.dispose();
  _animationController.dispose();
  _streamSubscription.cancel();
  super.dispose(); // Always call super.dispose()
}

// ❌ BAD: Forgetting to clean up
@override
void dispose() {
  super.dispose();
  // Forgot to clean up custom resources!
}
```

### 3. Event Payload Size

```dart
// ✅ GOOD: Lightweight events with IDs
class UserUpdatedEvent {
  final String userId;
  UserUpdatedEvent(this.userId);
}

// In your module:
@override
void listen() {
  on<UserUpdatedEvent>((UserUpdatedEvent event, BuildContext? context) {
    final user = userService.getUser(event.userId);
    _updateUI(user);
  });
}

// ❌ BAD: Heavy events with full data
class UserUpdatedEvent {
  final User user; // Could be megabytes of data
  final List<Permission> permissions;
  final List<ActivityLog> activityLogs;
}
```

## Migration Guide

### From v3.x to v4.x

#### Breaking Changes

1. **`broadcast` parameter deprecated**:
   ```dart
   // OLD (deprecated)
   on<MyEvent>((event, context) { }, broadcast: true);
   
   // NEW
   on<MyEvent>((event, context) { }, exclusive: true);
   ```

2. **Automatic context injection**:
   ```dart
    // OLD: Manual context passing
    on<MyEvent>((event) { 
    final context = MyApp.navigatorKey.currentContext;
    // Use context...
    });

    // NEW: Automatic context injection
    on<MyEvent>((MyEvent event, BuildContext? context) {
     if (context != null) {
    // Use context directly
       context.go('/new-route');
     }
    });
    ```

#### Migration Steps

1. Replace `broadcast: true` with `exclusive: true`
2. Update event handlers to accept `BuildContext? context` parameter
3. Add null checks for context usage
4. Test exclusive event behavior (FIFO queue vs. last-wins)

## Troubleshooting

### Common Issues

#### 1. Events Not Received

**Problem**: Event listeners not receiving events

**Solutions**:
```dart
// Check if module is properly initialized
class MyModule extends EventModule {
  @override
  void initState(Injector i) {
    super.initState(i); // Don't forget this!
  }
}

// Verify event types match exactly
ModularEvent.fire(UserLoginEvent()); // Event type: UserLoginEvent
on<UserLoginEvent>((UserLoginEvent event, BuildContext? context) { }); // Listener type: UserLoginEvent
```

#### 2. Memory Leaks

**Problem**: Memory not being released

**Solutions**:
```dart
// Ensure proper disposal
@override
void dispose() {
  _customSubscription?.cancel();
  super.dispose(); // Always call super.dispose()
}

// Check autoDispose settings
on<MyEvent>((MyEvent event, BuildContext? context) { }, autoDispose: true); // Default
```

#### 3. Context Not Available

**Problem**: `context` is null in event handlers

**Solutions**:
```dart
on<NavigationEvent>((NavigationEvent event, BuildContext? context) {
  if (context != null) {
    // Safe to use context
    context.go('/route');
  } else {
    // Defer action or use alternative method
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = MyApp.navigatorKey.currentContext;
      if (context != null) {
        context.go('/route');
      }
    });
  }
});
```

#### 4. Exclusive Events Not Working

**Problem**: Multiple exclusive listeners receiving events

**Solutions**:
```dart
// Ensure all listeners use the same EventBus
class Module1 extends EventModule {
  @override
  void listen() {
    on<MyEvent>((MyEvent event, BuildContext? context) { }, exclusive: true);
  }
}

class Module2 extends EventModule {
  @override
  void listen() {
    on<MyEvent>((MyEvent event, BuildContext? context) { }, exclusive: true);
  }
}

// Check that clearEventModuleState() is called between tests
setUp(() {
  clearEventModuleState(); // In tests only
});
```

### Debug Tools

#### Enable Debug Logging

```dart
// Configure in main.dart
await GoRouterModular.configure(
  appModule: AppModule(),
  initialRoute: '/home',
  debugLogEventBus: true, // Enable event logging
);

// Output:
// 🔥 Event fired: UserLoginEvent
// 🎭 Event received: UserLoginEvent
```

#### Clear State (Testing Only)

```dart
import 'package:go_router_modular/src/utils/event_module.dart';

setUp(() {
  clearEventModuleState(); // Clears all global state
});
```

---

## Support

For issues, feature requests, or questions:
- 📖 [Documentation](https://github.com/your-repo/wiki)
- 🐛 [Issue Tracker](https://github.com/your-repo/issues)
- 💬 [Discussions](https://github.com/your-repo/discussions)

---

*Built with ❤️ for the Flutter community*
