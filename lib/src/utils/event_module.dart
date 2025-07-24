import 'dart:async';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import '../go_router_modular_configure.dart';

/// Stores all event subscriptions organized by EventBus and event type.
///
/// The structure is: Map<EventBusId, Map<EventType, StreamSubscription>>
/// - EventBusId: EventBus hashCode to identify different instances
/// - EventType: Type.runtimeType of the event to avoid conflicts between types
/// - StreamSubscription: active subscription that can be cancelled when necessary
Map<int, Map<Type, StreamSubscription<dynamic>>> _eventSubscriptions = {};

/// Default global EventBus used by the modular event system.
///
/// This is the main bus that manages all events when no custom EventBus
/// is provided. Enables decoupled communication between modules.
final EventBus _eventBus = EventBus();

/// Global access to the modular event system.
///
/// This provides a convenient way to fire events from anywhere in your application
/// without needing to access the ModularEvent singleton directly.
///
/// Example:
/// ```dart
/// // Fire an event
/// modularEvent.fire(ShowNotificationEvent(message: 'Hello World!'));
/// ```
EventBus get modularEvent => _eventBus;

/// Represents the main Navigator context of the application.
///
/// Can return `null` in the following scenarios:
/// - During application initialization, before the Navigator is mounted
/// - After application disposal, when the Navigator has been unmounted
/// - During page transitions when the context is temporarily unavailable
/// - In cases where modularNavigatorKey was not configured correctly
///
/// It's important to always check if the context is not null before using it:
/// ```dart
/// final context = _navigatorContext;
/// if (context != null) {
///   // Use the context safely
///   context.go('/login');
/// }
/// ```
typedef NavigatorContext = BuildContext?;

/// Gets the current context of the main Navigator of the application.
///
/// This getter returns the BuildContext associated with `modularNavigatorKey`,
/// which is automatically configured by go_router_modular.
///
/// Returns `null` when the Navigator is not available (see [NavigatorContext]).
NavigatorContext get _navigatorContext {
  return modularNavigatorKey.currentContext;
}

/// Singleton class to manage global events in the application.
///
/// Provides a simplified interface to register event listeners
/// and fire events using the global EventBus. Useful for communication
/// between components that are not part of a specific EventModule.
///
/// Usage example:
/// ```dart
/// // Register a listener
/// ModularEvent.instance.on<LogoutEvent>((event, context) {
///   // logout logic
///   context?.go('/login');
/// });
///
/// // Fire an event
/// ModularEvent.fire(LogoutEvent());
/// ```
class ModularEvent {
  static ModularEvent? _instance;

  /// Private constructor to implement the Singleton pattern.
  ModularEvent._();

  /// Singleton instance of ModularEvent.
  ///
  /// Ensures that only one instance is created and reused
  /// throughout the application.
  static ModularEvent get instance => _instance ??= ModularEvent._();

  /// Removes a specific listener for an event type.
  ///
  /// Cancels the active subscription for event type [T] and removes it
  /// from the active subscriptions list. Useful for manual cleanup.
  ///
  /// Parameters:
  /// - [eventBus]: Specific EventBus (optional, uses global if not provided)
  ///
  /// Example:
  /// ```dart
  /// ModularEvent.instance.dispose<MyEvent>();
  /// ```
  void dispose<T>({EventBus? eventBus}) {
    eventBus ??= _eventBus;
    _eventSubscriptions[eventBus.hashCode]?[T]?.cancel();
    _eventSubscriptions[eventBus.hashCode]?.remove(T);
  }

  /// Registers a listener for events of type [T].
  ///
  /// The callback will be executed whenever an event of type [T] is fired.
  /// The current Navigator context is provided automatically, but can be `null`.
  ///
  /// Parameters:
  /// - [callback]: Function that will be executed when the event is received
  /// - [eventBus]: Specific EventBus (optional, uses global if not provided)
  ///
  /// Example:
  /// ```dart
  /// ModularEvent.instance.on<ShowSnackBarEvent>((event, context) {
  ///   if (context != null) {
  ///     ScaffoldMessenger.of(context).showSnackBar(
  ///       SnackBar(content: Text(event.message))
  ///     );
  ///   }
  /// });
  /// ```
  void on<T>(void Function(T event, NavigatorContext? context) callback, {EventBus? eventBus}) {
    eventBus ??= _eventBus;
    _eventSubscriptions[eventBus.hashCode]?[T]?.cancel();
    _eventSubscriptions[eventBus.hashCode]![T] = eventBus.on<T>().listen((event) => Future.microtask(() => callback(event, _navigatorContext)));
  }

  /// Fires an event in the application.
  ///
  /// All listeners registered for type [T] will receive this event.
  /// This is a static method to facilitate usage anywhere in the application.
  ///
  /// Parameters:
  /// - [event]: Instance of the event to be fired
  /// - [eventBus]: Specific EventBus (optional, uses global if not provided)
  ///
  /// Example:
  /// ```dart
  /// // Fire an event
  /// ModularEvent.fire(ShowSnackBarEvent(message: 'Hello World!'));
  ///
  /// // With custom EventBus
  /// ModularEvent.fire(MyEvent(), eventBus: customEventBus);
  /// ```
  static void fire<T>(T event, {EventBus? eventBus}) {
    eventBus ??= _eventBus;
    eventBus.fire(event);
  }
}

/// Abstract module to implement event system.
///
/// Extend this class to create modules that respond to specific events.
/// EventModule automatically manages the lifecycle of listeners,
/// registering them when the module is initialized and removing them when destroyed.
///
/// Main features:
/// - Auto-registration of listeners through the [listen] method
/// - Automatic memory leak management
/// - Integration with go_router_modular's modular system
/// - Custom EventBus support
///
/// Implementation example:
/// ```dart
/// class MyEventModule extends EventModule {
///   @override
///   List<ModularRoute> get routes => [
///     ChildRoute('/', child: (context, state) => MyPage()),
///   ];
///
///   @override
///   void listen() {
///     on<ShowSnackBarEvent>((event, context) {
///       if (context != null) {
///         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(event.message)));
///       }
///     });
///
///     on<LogoutEvent>((event, context) {
///       // logout logic
///       if (context != null) {
///       context?.go('/login');
///       }
///     });
///   }
/// }
/// ```
abstract class EventModule extends Module {
  static final Map<int, Map<Type, bool>> _disposeSubscriptions = {};

  late final EventBus _internalEventBus;

  /// Creates an instance of EventModule.
  ///
  /// Parameters:
  /// - [eventBus]: Custom EventBus (optional, uses global if not provided)
  EventModule({EventBus? eventBus}) {
    _internalEventBus = eventBus ?? _eventBus;
  }

  /// Abstract method where you should register all event listeners.
  ///
  /// This method is called automatically when the module is initialized.
  /// Implement this method to define which events the module should listen to
  /// and how it should respond to them.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void listen() {
  ///   on<ShowSnackBarEvent>((event, context) {
  ///     if (context != null) {
  ///       ScaffoldMessenger.of(context).showSnackBar(
  ///         SnackBar(content: Text(event.message))
  ///       );
  ///     }
  ///   });
  ///
  ///   on<LoginEvent>((event, context) {
  ///     // Logic to show modal
  ///     if (context != null) {
  ///       context.go('/home');
  ///     }
  ///   });
  /// }
  /// ```
  void listen();

  /// Registers a listener for events of type [T] within the module.
  ///
  /// This method should be used within the [listen] method to register
  /// event handlers. The listener will be automatically removed when
  /// the module is destroyed (if [autoDispose] is `true`).
  ///
  /// Parameters:
  /// - [callback]: Function that will be executed when the event is received
  /// - [autoDispose]: If `true`, automatically removes the listener when the module is destroyed (default: `true`)
  ///
  /// Example:
  /// ```dart
  /// on<ShowSnackBarEvent>((event, context) {
  ///   if (context != null) {
  ///     ScaffoldMessenger.of(context).showSnackBar(
  ///       SnackBar(content: Text(event.message))
  ///     );
  ///   }
  /// });
  ///
  /// // Listener that won't be automatically removed
  /// on<PersistentEvent>((event, context) {
  ///   // Logic that should persist
  /// }, autoDispose: false);
  /// ```
  void on<T>(void Function(T event, NavigatorContext? context) callback, {bool autoDispose = true}) {
    final eventBusId = _internalEventBus.hashCode;

    _eventSubscriptions[eventBusId] ??= {};
    _disposeSubscriptions[eventBusId] ??= {};

    _eventSubscriptions[eventBusId]?[T]?.cancel();

    _eventSubscriptions[eventBusId]![T] = _internalEventBus.on<T>().listen((event) => Future.microtask(() => callback(event, _navigatorContext)));

    _disposeSubscriptions[eventBusId]![T] = autoDispose;
  }

  @override
  void initState(Injector i) {
    listen();
    super.initState(i);
  }

  @override
  void dispose() {
    final eventBusId = _internalEventBus.hashCode;

    _disposeSubscriptions[eventBusId]?.forEach((key, value) {
      if (value) {
        _eventSubscriptions[eventBusId]?[key]?.cancel();
        _eventSubscriptions[eventBusId]?.remove(key);
      }
    });

    _disposeSubscriptions.remove(eventBusId);
    _eventSubscriptions.remove(eventBusId);

    super.dispose();
  }
}
