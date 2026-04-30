# EventModule for Microfrontends: Technical Documentation

A comprehensive guide for implementing microfrontend architecture using EventModule for inter-module communication.

## Table of Contents

- [Overview](#overview)
- [Microfrontend Architecture](#microfrontend-architecture)
- [EventModule Benefits](#eventmodule-benefits)
- [Implementation Patterns](#implementation-patterns)
- [Communication Strategies](#communication-strategies)
- [Real-World Examples](#real-world-examples)
- [Performance Optimization](#performance-optimization)
- [Deployment Strategies](#deployment-strategies)
- [Monitoring & Debugging](#monitoring--debugging)
- [Best Practices](#best-practices)
- [Migration Guide](#migration-guide)
- [Case Studies](#case-studies)

## Overview

### What are Microfrontends?

Microfrontends extend the concept of microservices to frontend development, allowing teams to:

- **Develop independently** using different technologies
- **Deploy autonomously** without affecting other parts
- **Scale teams** horizontally with clear ownership boundaries
- **Maintain resilience** through isolation and fault tolerance

### EventModule's Role

EventModule provides the **communication backbone** for microfrontends, enabling:

```
┌─────────────────────────────────────────────────────────────┐
│                    EventModule Bus                          │
├─────────────────────────────────────────────────────────────┤
│  🛍️ E-commerce    💰 Payment     👤 Auth     📊 Analytics  │
│  Module           Module         Module      Module         │
│  (React)          (Vue)          (Angular)   (Flutter)      │
└─────────────────────────────────────────────────────────────┘
```

**Key Capabilities:**
- ✅ **Technology Agnostic** - Works with any Flutter-based microfrontend
- ✅ **Type-Safe Communication** - Compile-time verification of event contracts
- ✅ **Loose Coupling** - Modules communicate without direct dependencies
- ✅ **Event Sourcing** - Audit trail of all inter-module communications
- ✅ **Real-time Synchronization** - Immediate state updates across modules

## Microfrontend Architecture

### Traditional Monolith vs Microfrontends

#### Monolithic Frontend
```dart
// ❌ Single large application
class MonolithApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            ECommerceSection(),    // 50,000 lines
            PaymentSection(),      // 30,000 lines  
            UserProfileSection(),  // 25,000 lines
            AnalyticsSection(),    // 15,000 lines
            // Total: 120,000 lines in single app
          ],
        ),
      ),
    );
  }
}
```

**Problems:**
- 🐌 **Slow builds** (5-10 minutes)
- 🚫 **Technology lock-in** (single framework)
- 👥 **Team conflicts** (merge hell)
- 🐛 **Ripple effects** (one bug affects everything)
- 📦 **Large bundles** (slow loading)

#### Microfrontend Architecture
```dart
// ✅ Modular, independent applications
class ShellApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: GoRouterModular.routerConfig,
    );
  }
}

// Independent modules
class ECommerceModule extends EventModule { }    // Team A - 10,000 lines
class PaymentModule extends EventModule { }      // Team B - 8,000 lines  
class UserModule extends EventModule { }         // Team C - 6,000 lines
class AnalyticsModule extends EventModule { }    // Team D - 4,000 lines
```

**Benefits:**
- ⚡ **Fast builds** (30 seconds per module)
- 🎯 **Technology freedom** (best tool for the job)
- 👥 **Team autonomy** (independent development)
- 🛡️ **Fault isolation** (resilient architecture)
- 📦 **Lazy loading** (load on demand)

### EventModule Communication Layer

```dart
// Communication backbone
class MicrofrontendBus {
  // Cross-module events
  static void broadcastUserLogin(User user) {
    ModularEvent.fire(UserLoginEvent(
      userId: user.id,
      email: user.email,
      timestamp: DateTime.now(),
    ));
  }

  static void notifyPurchaseCompleted(Purchase purchase) {
    ModularEvent.fire(PurchaseCompletedEvent(
      orderId: purchase.id,
      userId: purchase.userId,
      amount: purchase.total,
      items: purchase.items,
    ));
  }
}
```

## EventModule Benefits

### 1. Decoupled Architecture

#### Without EventModule (Tight Coupling)
```dart
// ❌ Direct dependencies between modules
class ECommerceModule {
  final PaymentModule paymentModule;
  final UserModule userModule;
  final AnalyticsModule analyticsModule;
  
  ECommerceModule({
    required this.paymentModule,    // Direct dependency
    required this.userModule,       // Direct dependency  
    required this.analyticsModule,  // Direct dependency
  });

  void processOrder(Order order) {
    // Tightly coupled calls
    userModule.validateUser(order.userId);
    paymentModule.processPayment(order.payment);
    analyticsModule.trackPurchase(order);
  }
}
```

**Problems:**
- 🔗 **Tight coupling** - modules know about each other
- 🐛 **Fragile** - changes break other modules
- 🧪 **Hard to test** - requires all dependencies
- 📦 **Bundle bloat** - everything loads together

#### With EventModule (Loose Coupling)
```dart
// ✅ Event-driven, loosely coupled
class ECommerceModule extends EventModule {
  @override
  void listen() {
    on<UserValidatedEvent>((UserValidatedEvent event, BuildContext? context) {
      _proceedWithOrder(event.orderId);
    });

    on<PaymentProcessedEvent>((PaymentProcessedEvent event, BuildContext? context) {
      _fulfillOrder(event.orderId);
    });
  }

  void processOrder(Order order) {
    // Fire events - no direct dependencies
    ModularEvent.fire(ValidateUserEvent(userId: order.userId, orderId: order.id));
    ModularEvent.fire(ProcessPaymentEvent(payment: order.payment, orderId: order.id));
    ModularEvent.fire(TrackPurchaseEvent(order: order));
  }
}
```

**Benefits:**
- 🔓 **Loose coupling** - modules don't know each other
- 🛡️ **Resilient** - modules can fail independently
- 🧪 **Easy testing** - mock events, not dependencies
- 📦 **Lazy loading** - load modules on demand

### 2. Independent Development

```dart
// Team A: E-commerce (develops independently)
class ECommerceModule extends EventModule {
  @override
  List<ModularRoute> get routes => [
    ChildRoute('/products', child: (context, state) => ProductsPage()),
    ChildRoute('/cart', child: (context, state) => CartPage()),
  ];

  @override
  void listen() {
    // Only cares about events it needs
    on<UserLoginEvent>((UserLoginEvent event, BuildContext? context) {
      _loadUserCart(event.userId);
    });
  }
}

// Team B: Payment (develops independently)  
class PaymentModule extends EventModule {
  @override
  List<ModularRoute> get routes => [
    ChildRoute('/payment', child: (context, state) => PaymentPage()),
    ChildRoute('/billing', child: (context, state) => BillingPage()),
  ];

  @override
  void listen() {
    // Different events, different concerns
    on<InitiatePaymentEvent>((InitiatePaymentEvent event, BuildContext? context) {
      _processPayment(event.amount, event.method);
    });
  }
}
```

### 3. Technology Diversity

```dart
// Different modules can use different approaches
class ModernECommerceModule extends EventModule {
  // Uses latest State Management (Riverpod)
  @override
  Widget buildPage(BuildContext context, String route) {
    return ProviderScope(
      child: ModernProductsPage(),
    );
  }
}

class LegacyPaymentModule extends EventModule {
  // Uses older State Management (Provider)
  @override
  Widget buildPage(BuildContext context, String route) {
    return ChangeNotifierProvider(
      create: (_) => PaymentProvider(),
      child: LegacyPaymentPage(),
    );
  }
}

// Events work seamlessly between different architectures
```

### 4. Fault Tolerance

```dart
class ResilientModule extends EventModule {
  @override
  void listen() {
    // Graceful degradation
    on<CriticalServiceDownEvent>((CriticalServiceDownEvent event, BuildContext? context) {
      _enableFallbackMode();
    });

    on<PaymentFailedEvent>((PaymentFailedEvent event, BuildContext? context) {
      // Other modules continue working
      _showErrorToUser(event.error);
      _suggestAlternativePayment();
    });
  }

  void _enableFallbackMode() {
    // Module continues with reduced functionality
    // instead of complete failure
  }
}
```

## Implementation Patterns

### 1. Shell Application Pattern

```dart
// Shell App - Orchestrates microfrontends
class ShellApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Microfrontend Shell',
      routerConfig: GoRouterModular.routerConfig,
    );
  }
}

// Shell Module - Coordinates everything
class ShellModule extends Module {
  @override
  List<Module> get imports => [
    // Microfrontend modules
    ECommerceModule(),
    PaymentModule(),
    UserManagementModule(),
    AnalyticsModule(),
    NotificationModule(),
  ];

  @override
  List<ModularRoute> get routes => [
    ChildRoute('/', child: (context, state) => DashboardPage()),
    ChildRoute('/shell', child: (context, state) => ShellPage()),
  ];
}
```

### 2. Event Contract Pattern

```dart
// Shared event contracts between modules
library microfrontend_events;

// Authentication Events
class UserLoginEvent {
  final String userId;
  final String email;
  final String role;
  final DateTime loginTime;
  
  UserLoginEvent({
    required this.userId,
    required this.email,
    required this.role,
    required this.loginTime,
  });
}

class UserLogoutEvent {
  final String userId;
  final DateTime logoutTime;
  final String reason;
  
  UserLogoutEvent({
    required this.userId,
    required this.logoutTime,
    required this.reason,
  });
}

// E-commerce Events
class ProductAddedToCartEvent {
  final String userId;
  final String productId;
  final int quantity;
  final double price;
  
  ProductAddedToCartEvent({
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.price,
  });
}

class OrderCompletedEvent {
  final String orderId;
  final String userId;
  final double totalAmount;
  final List<OrderItem> items;
  final DateTime completedAt;
  
  OrderCompletedEvent({
    required this.orderId,
    required this.userId,
    required this.totalAmount,
    required this.items,
    required this.completedAt,
  });
}
```

### 3. Module Composition Pattern

```dart
// Composable modules for different business units
class RetailPlatformModule extends Module {
  @override
  List<Module> get imports => [
    // Customer-facing modules
    ProductCatalogModule(),
    ShoppingCartModule(),
    CheckoutModule(),
    
    // Support modules
    CustomerServiceModule(),
    ReviewsModule(),
    RecommendationsModule(),
  ];
}

class AdminPlatformModule extends Module {
  @override
  List<Module> get imports => [
    // Admin modules
    InventoryModule(),
    OrderManagementModule(),
    UserManagementModule(),
    AnalyticsModule(),
    
    // Reporting modules
    SalesReportModule(),
    CustomerReportModule(),
  ];
}

// Main app composes platforms
class MainAppModule extends Module {
  @override
  List<Module> get imports => [
    RetailPlatformModule(),
    AdminPlatformModule(),
    SharedServicesModule(),
  ];
}
```

## Communication Strategies

### 1. Synchronous Communication

```dart
// Request-Response pattern using events
class DataRequestModule extends EventModule {
  final Map<String, Completer<dynamic>> _pendingRequests = {};

  Future<UserProfile> getUserProfile(String userId) async {
    final requestId = _generateRequestId();
    final completer = Completer<UserProfile>();
    _pendingRequests[requestId] = completer;

    // Fire request event
    ModularEvent.fire(UserProfileRequestEvent(
      userId: userId,
      requestId: requestId,
    ));

    return completer.future;
  }

  @override
  void listen() {
    on<UserProfileResponseEvent>((UserProfileResponseEvent event, BuildContext? context) {
      final completer = _pendingRequests.remove(event.requestId);
      completer?.complete(event.profile);
    });
  }
}
```

### 2. Asynchronous Communication

```dart
// Fire-and-forget pattern
class AnalyticsModule extends EventModule {
  @override
  void listen() {
    // Listen to various events for analytics
    on<UserLoginEvent>((UserLoginEvent event, BuildContext? context) {
      _trackUserLogin(event.userId, event.loginTime);
    });

    on<ProductViewedEvent>((ProductViewedEvent event, BuildContext? context) {
      _trackProductView(event.productId, event.userId);
    });

    on<PurchaseCompletedEvent>((PurchaseCompletedEvent event, BuildContext? context) {
      _trackPurchase(event.orderId, event.amount);
    });
  }

  void _trackUserLogin(String userId, DateTime loginTime) {
    // Send to analytics service
    analyticsService.track('user_login', {
      'user_id': userId,
      'timestamp': loginTime.toIso8601String(),
    });
  }
}
```

### 3. State Synchronization

```dart
// Shared state across modules
class SharedStateModule extends EventModule {
  static UserState? _currentUser;
  static CartState _cart = CartState.empty();

  @override
  void listen() {
    // Update shared state based on events
    on<UserLoginEvent>((UserLoginEvent event, BuildContext? context) {
      _currentUser = UserState(
        id: event.userId,
        email: event.email,
        role: event.role,
      );
      
      // Broadcast state change
      ModularEvent.fire(UserStateUpdatedEvent(user: _currentUser!));
    });

    on<CartUpdatedEvent>((CartUpdatedEvent event, BuildContext? context) {
      _cart = event.cart;
      
      // Broadcast to interested modules
      ModularEvent.fire(CartStateUpdatedEvent(cart: _cart));
    });
  }

  // State accessors
  static UserState? get currentUser => _currentUser;
  static CartState get cart => _cart;
}
```

## Real-World Examples

### 1. E-commerce Platform

```dart
// Product Catalog Module
class ProductCatalogModule extends EventModule {
  @override
  List<ModularRoute> get routes => [
    ChildRoute('/products', child: (context, state) => ProductListPage()),
    ChildRoute('/product/:id', child: (context, state) => ProductDetailPage()),
  ];

  @override
  void listen() {
    on<SearchProductsEvent>((SearchProductsEvent event, BuildContext? context) {
      _performSearch(event.query, event.filters);
    });

    on<ProductRecommendationRequestEvent>((ProductRecommendationRequestEvent event, BuildContext? context) {
      _generateRecommendations(event.userId, event.context);
    });
  }

  void _performSearch(String query, Map<String, dynamic> filters) {
    // Search logic
    final results = productService.search(query, filters);
    
    // Broadcast results
    ModularEvent.fire(ProductSearchResultsEvent(
      query: query,
      results: results,
      timestamp: DateTime.now(),
    ));
  }
}

// Shopping Cart Module
class ShoppingCartModule extends EventModule {
  @override
  List<ModularRoute> get routes => [
    ChildRoute('/cart', child: (context, state) => ShoppingCartPage()),
  ];

  @override
  void listen() {
    on<AddToCartEvent>((AddToCartEvent event, BuildContext? context) {
      _addToCart(event.productId, event.quantity);
    });

    on<RemoveFromCartEvent>((RemoveFromCartEvent event, BuildContext? context) {
      _removeFromCart(event.cartItemId);
    });

    on<UserLoginEvent>((UserLoginEvent event, BuildContext? context) {
      _loadUserCart(event.userId);
    });
  }

  void _addToCart(String productId, int quantity) {
    cartService.addItem(productId, quantity);
    
    // Notify other modules
    ModularEvent.fire(CartUpdatedEvent(
      userId: cartService.userId,
      itemCount: cartService.totalItems,
      total: cartService.total,
    ));

    // Analytics
    ModularEvent.fire(ProductAddedToCartEvent(
      userId: cartService.userId,
      productId: productId,
      quantity: quantity,
      price: cartService.getItemPrice(productId),
    ));
  }
}

// Payment Module
class PaymentModule extends EventModule {
  @override
  List<ModularRoute> get routes => [
    ChildRoute('/checkout', child: (context, state) => CheckoutPage()),
    ChildRoute('/payment', child: (context, state) => PaymentPage()),
  ];

  @override
  void listen() {
    on<InitiateCheckoutEvent>((InitiateCheckoutEvent event, BuildContext? context) {
      _startCheckoutProcess(event.cartItems, event.userId);
    });

    on<ProcessPaymentEvent>((ProcessPaymentEvent event, BuildContext? context) {
      _processPayment(event.paymentMethod, event.amount);
    });
  }

  Future<void> _processPayment(PaymentMethod method, double amount) async {
    try {
      final result = await paymentService.process(method, amount);
      
      if (result.success) {
        ModularEvent.fire(PaymentSuccessEvent(
          transactionId: result.transactionId,
          amount: amount,
          method: method,
        ));
      } else {
        ModularEvent.fire(PaymentFailedEvent(
          error: result.error,
          amount: amount,
          method: method,
        ));
      }
    } catch (error) {
      ModularEvent.fire(PaymentErrorEvent(
        error: error.toString(),
        amount: amount,
      ));
    }
  }
}
```

### 2. Banking Application

```dart
// Account Management Module
class AccountModule extends EventModule {
  @override
  void listen() {
    on<TransferMoneyEvent>((TransferMoneyEvent event, BuildContext? context) {
      _processTransfer(event.fromAccount, event.toAccount, event.amount);
    });

    on<DepositEvent>((DepositEvent event, BuildContext? context) {
      _processDeposit(event.accountId, event.amount);
    });
  }

  Future<void> _processTransfer(String fromAccount, String toAccount, double amount) async {
    // Business logic
    final result = await accountService.transfer(fromAccount, toAccount, amount);
    
    if (result.success) {
      // Notify interested modules
      ModularEvent.fire(TransferCompletedEvent(
        transactionId: result.transactionId,
        fromAccount: fromAccount,
        toAccount: toAccount,
        amount: amount,
        timestamp: DateTime.now(),
      ));
    }
  }
}

// Fraud Detection Module
class FraudDetectionModule extends EventModule {
  @override
  void listen() {
    // Monitor all financial transactions
    on<TransferCompletedEvent>((TransferCompletedEvent event, BuildContext? context) {
      _analyzeFraudRisk(event);
    });

    on<LoginAttemptEvent>((LoginAttemptEvent event, BuildContext? context) {
      _checkSuspiciousLogin(event);
    });
  }

  void _analyzeFraudRisk(TransferCompletedEvent event) {
    final riskScore = fraudService.calculateRisk(event);
    
    if (riskScore > 0.8) {
      ModularEvent.fire(SuspiciousActivityEvent(
        userId: event.fromAccount,
        transactionId: event.transactionId,
        riskScore: riskScore,
        reason: 'Unusual transfer pattern',
      ));
    }
  }
}

// Notification Module
class NotificationModule extends EventModule {
  @override
  void listen() {
    on<TransferCompletedEvent>((TransferCompletedEvent event, BuildContext? context) {
      _sendTransferNotification(event);
    });

    on<SuspiciousActivityEvent>((SuspiciousActivityEvent event, BuildContext? context) {
      _sendSecurityAlert(event);
    });

    on<PaymentFailedEvent>((PaymentFailedEvent event, BuildContext? context) {
      _sendFailureNotification(event);
    });
  }

  void _sendTransferNotification(TransferCompletedEvent event) {
    notificationService.send(
      userId: event.fromAccount,
      title: 'Transfer Completed',
      message: 'Your transfer of \$${event.amount} was successful',
      type: NotificationType.info,
    );
  }
}
```

## Performance Optimization

### 1. Lazy Loading Modules

```dart
// Load modules on demand
class LazyModuleLoader {
  static final Map<String, Module> _loadedModules = {};

  static Future<Module> loadModule(String moduleName) async {
    if (_loadedModules.containsKey(moduleName)) {
      return _loadedModules[moduleName]!;
    }

    Module module;
    switch (moduleName) {
      case 'ecommerce':
        module = await _loadECommerceModule();
        break;
      case 'payment':
        module = await _loadPaymentModule();
        break;
      case 'analytics':
        module = await _loadAnalyticsModule();
        break;
      default:
        throw Exception('Unknown module: $moduleName');
    }

    _loadedModules[moduleName] = module;
    return module;
  }

  static Future<ECommerceModule> _loadECommerceModule() async {
    // Simulate loading time
    await Future.delayed(Duration(milliseconds: 500));
    return ECommerceModule();
  }
}
```

### 2. Event Batching

```dart
// Batch events for better performance
class EventBatcher {
  static final Map<Type, List<dynamic>> _batchedEvents = {};
  static Timer? _batchTimer;

  static void batchEvent<T>(T event) {
    _batchedEvents[T] ??= [];
    _batchedEvents[T]!.add(event);

    // Process batch after delay
    _batchTimer?.cancel();
    _batchTimer = Timer(Duration(milliseconds: 100), _processBatch);
  }

  static void _processBatch() {
    for (final entry in _batchedEvents.entries) {
      ModularEvent.fire(BatchedEventsEvent(
        eventType: entry.key,
        events: entry.value,
      ));
    }
    _batchedEvents.clear();
  }
}
```

### 3. Event Filtering

```dart
// Efficient event filtering
class SmartEventModule extends EventModule {
  @override
  void listen() {
    // Only listen to events we care about
    on<UserEvent>((UserEvent event, BuildContext? context) {
      // Filter by user role
      if (event.userRole == UserRole.admin) {
        _handleAdminEvent(event);
      }
    });

    // Debounced search
    on<SearchEvent>((SearchEvent event, BuildContext? context) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(Duration(milliseconds: 300), () {
        _performSearch(event.query);
      });
    });
  }

  Timer? _debounceTimer;
}
```

## Deployment Strategies

### 1. Independent Deployment

```yaml
# CI/CD Pipeline for each module
name: Deploy ECommerce Module
on:
  push:
    paths:
      - 'modules/ecommerce/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Build Module
        run: flutter build web
      
      - name: Deploy to CDN
        run: aws s3 sync build/web s3://cdn/ecommerce-module
      
      - name: Update Module Registry
        run: curl -X POST api/modules/ecommerce/deploy
```

### 2. Version Management

```dart
// Module versioning
class ModuleVersion {
  final String name;
  final String version;
  final List<String> compatibleVersions;

  ModuleVersion({
    required this.name,
    required this.version,
    required this.compatibleVersions,
  });
}

class ModuleRegistry {
  static final Map<String, ModuleVersion> _modules = {
    'ecommerce': ModuleVersion(
      name: 'ecommerce',
      version: '2.1.0',
      compatibleVersions: ['2.0.0', '2.1.0'],
    ),
    'payment': ModuleVersion(
      name: 'payment',
      version: '1.5.2',
      compatibleVersions: ['1.5.0', '1.5.1', '1.5.2'],
    ),
  };

  static bool isCompatible(String module1, String module2) {
    final mod1 = _modules[module1];
    final mod2 = _modules[module2];
    
    return mod1?.compatibleVersions.contains(mod2?.version) ?? false;
  }
}
```

### 3. Blue-Green Deployment

```dart
// Route traffic between module versions
class ModuleRouter {
  static String _currentEnvironment = 'blue';
  
  static Module getModule(String moduleName) {
    switch (_currentEnvironment) {
      case 'blue':
        return _getBlueModule(moduleName);
      case 'green':
        return _getGreenModule(moduleName);
      default:
        throw Exception('Unknown environment: $_currentEnvironment');
    }
  }

  static void switchEnvironment() {
    _currentEnvironment = _currentEnvironment == 'blue' ? 'green' : 'blue';
    
    // Notify all modules about environment switch
    ModularEvent.fire(EnvironmentSwitchedEvent(
      newEnvironment: _currentEnvironment,
      timestamp: DateTime.now(),
    ));
  }
}
```

## Monitoring & Debugging

### 1. Event Tracing

```dart
// Event tracing for debugging
class EventTracer {
  static final List<EventTrace> _traces = [];

  static void traceEvent<T>(T event, String source) {
    _traces.add(EventTrace(
      event: event,
      eventType: T,
      source: source,
      timestamp: DateTime.now(),
      stackTrace: StackTrace.current,
    ));

    // Keep only recent traces
    if (_traces.length > 1000) {
      _traces.removeAt(0);
    }
  }

  static List<EventTrace> getTraces({Type? eventType, String? source}) {
    return _traces.where((trace) {
      if (eventType != null && trace.eventType != eventType) return false;
      if (source != null && trace.source != source) return false;
      return true;
    }).toList();
  }
}

class EventTrace {
  final dynamic event;
  final Type eventType;
  final String source;
  final DateTime timestamp;
  final StackTrace stackTrace;

  EventTrace({
    required this.event,
    required this.eventType,
    required this.source,
    required this.timestamp,
    required this.stackTrace,
  });
}
```

### 2. Performance Monitoring

```dart
// Monitor module performance
class ModulePerformanceMonitor extends EventModule {
  static final Map<String, List<Duration>> _moduleResponseTimes = {};

  @override
  void listen() {
    on<ModuleRequestEvent>((ModuleRequestEvent event, BuildContext? context) {
      _startTimer(event.moduleId, event.requestId);
    });

    on<ModuleResponseEvent>((ModuleResponseEvent event, BuildContext? context) {
      _recordResponseTime(event.moduleId, event.requestId);
    });
  }

  static void _startTimer(String moduleId, String requestId) {
    // Implementation details...
  }

  static void _recordResponseTime(String moduleId, String requestId) {
    // Calculate and store response time
    final responseTime = _calculateResponseTime(moduleId, requestId);
    
    _moduleResponseTimes[moduleId] ??= [];
    _moduleResponseTimes[moduleId]!.add(responseTime);

    // Alert if response time is too high
    if (responseTime > Duration(milliseconds: 1000)) {
      ModularEvent.fire(SlowModuleResponseEvent(
        moduleId: moduleId,
        responseTime: responseTime,
      ));
    }
  }
}
```

### 3. Health Checks

```dart
// Module health monitoring
class ModuleHealthChecker extends EventModule {
  @override
  void listen() {
    // Regular health checks
    Timer.periodic(Duration(minutes: 1), (_) => _performHealthChecks());

    on<ModuleErrorEvent>((ModuleErrorEvent event, BuildContext? context) {
      _handleModuleError(event);
    });
  }

  void _performHealthChecks() {
    final modules = ['ecommerce', 'payment', 'user', 'analytics'];
    
    for (final moduleId in modules) {
      ModularEvent.fire(HealthCheckRequestEvent(
        moduleId: moduleId,
        timestamp: DateTime.now(),
      ));
    }
  }

  void _handleModuleError(ModuleErrorEvent event) {
    // Log error
    logger.error('Module ${event.moduleId} error: ${event.error}');
    
    // Notify monitoring system
    ModularEvent.fire(ModuleUnhealthyEvent(
      moduleId: event.moduleId,
      error: event.error,
      timestamp: DateTime.now(),
    ));
  }
}
```

## Best Practices

### 1. Event Design

```dart
// ✅ GOOD: Well-designed events
class UserRegistrationCompletedEvent {
  final String userId;
  final String email;
  final UserProfile profile;
  final DateTime registrationDate;
  final String source; // web, mobile, api
  
  UserRegistrationCompletedEvent({
    required this.userId,
    required this.email,
    required this.profile,
    required this.registrationDate,
    required this.source,
  });

  // Add useful methods
  bool get isEmailVerified => profile.emailVerified;
  bool get isFromMobile => source == 'mobile';
}

// ❌ BAD: Poorly designed events
class GenericUserEvent {
  Map<String, dynamic>? data; // Untyped
  String? action;              // Unclear
  // Missing timestamp, unclear purpose
}
```

### 2. Module Boundaries

```dart
// ✅ GOOD: Clear module boundaries
class OrderModule extends EventModule {
  // Responsible for: order lifecycle, order validation, order status
  
  @override
  void listen() {
    on<CreateOrderEvent>((CreateOrderEvent event, BuildContext? context) {
      _createOrder(event);
    });

    on<CancelOrderEvent>((CancelOrderEvent event, BuildContext? context) {
      _cancelOrder(event);
    });
  }
}

class PaymentModule extends EventModule {
  // Responsible for: payment processing, payment methods, refunds
  
  @override
  void listen() {
    on<ProcessPaymentEvent>((ProcessPaymentEvent event, BuildContext? context) {
      _processPayment(event);
    });
  }
}

// ❌ BAD: Unclear boundaries
class OrderPaymentModule extends EventModule {
  // Too many responsibilities - should be split
  // Orders + Payments + Inventory + Shipping
}
```

### 3. Error Handling

```dart
// ✅ GOOD: Comprehensive error handling
class RobustModule extends EventModule {
  @override
  void listen() {
    on<ProcessDataEvent>((ProcessDataEvent event, BuildContext? context) async {
      try {
        await _processData(event.data);
        
        ModularEvent.fire(DataProcessedEvent(
          dataId: event.dataId,
          result: 'success',
        ));
      } on ValidationException catch (e) {
        ModularEvent.fire(DataValidationFailedEvent(
          dataId: event.dataId,
          validationErrors: e.errors,
        ));
      } on NetworkException catch (e) {
        ModularEvent.fire(NetworkErrorEvent(
          operation: 'process_data',
          error: e.message,
          retryable: true,
        ));
      } catch (e, stackTrace) {
        // Unexpected error
        ModularEvent.fire(UnexpectedErrorEvent(
          operation: 'process_data',
          error: e.toString(),
          stackTrace: stackTrace.toString(),
        ));
      }
    });
  }
}
```

### 4. Testing Strategies

```dart
// Microfrontend testing
class ECommerceModuleTest {
  late ECommerceModule module;
  late List<dynamic> firedEvents;

  @override
  void setUp() {
    module = ECommerceModule();
    firedEvents = [];
    
    // Mock event firing
    ModularEvent.fire = (event) => firedEvents.add(event);
  }

  @override
  void testAddToCart() {
    // Arrange
    final event = AddToCartEvent(
      userId: 'user123',
      productId: 'product456',
      quantity: 2,
    );

    // Act
    module.handleAddToCart(event);

    // Assert
    expect(firedEvents, hasLength(2));
    expect(firedEvents[0], isA<CartUpdatedEvent>());
    expect(firedEvents[1], isA<ProductAddedToCartEvent>());
  }
}
```

## Migration Guide

### From Monolith to Microfrontends

#### Phase 1: Identify Boundaries
```dart
// Current monolith
class MonolithApp {
  // User management: 15,000 lines
  // Product catalog: 25,000 lines  
  // Shopping cart: 10,000 lines
  // Payment processing: 20,000 lines
  // Order management: 18,000 lines
  // Analytics: 12,000 lines
}

// Target microfrontends
// UserModule: 15,000 lines
// ProductModule: 25,000 lines
// CartModule: 10,000 lines
// PaymentModule: 20,000 lines  
// OrderModule: 18,000 lines
// AnalyticsModule: 12,000 lines
```

#### Phase 2: Extract Modules
```dart
// Step 1: Create EventModule structure
class UserModule extends EventModule {
  // Move user-related code here
}

// Step 2: Replace direct calls with events
// Before:
userService.login(email, password);

// After:
ModularEvent.fire(UserLoginRequestEvent(
  email: email,
  password: password,
));
```

#### Phase 3: Gradual Migration
```dart
// Hybrid approach during migration
class HybridModule extends EventModule {
  final LegacyUserService legacyService; // Keep during transition
  final UserService newService;          // New event-driven service

  @override
  void listen() {
    on<UserLoginEvent>((UserLoginEvent event, BuildContext? context) {
      // Use new service
      newService.login(event.email, event.password);
    });
  }

  // Legacy method - remove after migration
  @deprecated
  void legacyLogin(String email, String password) {
    legacyService.login(email, password);
  }
}
```

## Case Studies

### Case Study 1: E-commerce Platform

**Company**: TechMart (fictional)
**Challenge**: Monolithic e-commerce platform with 8 teams

#### Before Microfrontends
- **Build Time**: 15 minutes
- **Deployment**: Weekly (risky)
- **Team Dependencies**: High
- **Bug Impact**: Entire platform down

#### Implementation
```dart
// Module structure
class TechMartShell extends Module {
  @override
  List<Module> get imports => [
    ProductCatalogModule(),    // Team A
    UserAccountModule(),       // Team B  
    ShoppingCartModule(),      // Team C
    CheckoutModule(),          // Team D
    OrderTrackingModule(),     // Team E
    CustomerServiceModule(),   // Team F
    AdminPanelModule(),        // Team G
    AnalyticsModule(),         // Team H
  ];
}

// Event flow example
class PurchaseFlow {
  static void simulateFlow() {
    // User adds product to cart
    ModularEvent.fire(AddToCartEvent(
      userId: 'user123',
      productId: 'laptop001',
      quantity: 1,
    ));

    // Cart module updates
    // Recommendation module suggests accessories
    // Analytics module tracks behavior
    
    // User proceeds to checkout
    ModularEvent.fire(InitiateCheckoutEvent(
      userId: 'user123',
      cartItems: ['laptop001'],
    ));

    // Checkout module handles payment
    // Order module creates order
    // Inventory module updates stock
    // Email module sends confirmation
  }
}
```

#### Results After Implementation
- **Build Time**: 2 minutes per module
- **Deployment**: Daily (safe)
- **Team Independence**: 95%
- **Bug Isolation**: Module-specific

### Case Study 2: Banking Platform

**Company**: SecureBank (fictional)
**Challenge**: Legacy banking system modernization

#### Module Architecture
```dart
class BankingPlatform extends Module {
  @override
  List<Module> get imports => [
    AccountManagementModule(),
    TransactionModule(),
    LoanModule(),
    InvestmentModule(),
    FraudDetectionModule(),
    ComplianceModule(),
    CustomerSupportModule(),
  ];
}

// Critical event flows
class BankingEvents {
  // High-value transaction monitoring
  static void monitorTransaction(Transaction transaction) {
    ModularEvent.fire(TransactionInitiatedEvent(
      transactionId: transaction.id,
      amount: transaction.amount,
      fromAccount: transaction.fromAccount,
      toAccount: transaction.toAccount,
    ));

    // Automatic triggers:
    // - FraudDetectionModule analyzes risk
    // - ComplianceModule checks regulations
    // - NotificationModule alerts user
  }
}
```

#### Security Benefits
- **Isolated failures**: One module compromise doesn't affect others
- **Audit trails**: All inter-module communication logged
- **Compliance**: Each module meets specific regulations
- **Monitoring**: Real-time health checks and alerts

---

## Conclusion

EventModule provides a robust foundation for microfrontend architectures, enabling:

- **🏗️ Scalable Architecture**: Independent development and deployment
- **🔗 Loose Coupling**: Modules communicate through well-defined events
- **🛡️ Fault Tolerance**: Isolated failures with graceful degradation
- **👥 Team Autonomy**: Clear ownership boundaries and responsibilities
- **📈 Performance**: Lazy loading and optimized resource utilization

By following the patterns and practices outlined in this guide, development teams can build maintainable, scalable microfrontend applications that grow with their business needs.

---

*"Microfrontends with EventModule: Where independent modules create harmonious applications."* 🎼
