import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/internal/setup.dart';

/// Global storage for all event subscriptions organized by EventBus and event type.
///
/// Structure: `Map<EventBusId, Map<EventType, StreamSubscription>>`
/// - **EventBusId**: EventBus hashCode to identify different instances
/// - **EventType**: Type.runtimeType of the event to avoid conflicts between types
/// - **StreamSubscription**: active subscription that can be cancelled when necessary
Map<int, Map<Type, StreamSubscription<dynamic>>> _eventSubscriptions = {};

/// Global storage for exclusive event streams.
///
/// Structure: `Map<EventBusHashCode, Map<EventType, BroadcastStream>>`
/// Stores shared broadcast streams for exclusive event listeners.
Map<int, Map<Type, Stream<dynamic>>> _exclusiveStreams = {};

/// Queue system for exclusive event listeners.
///
/// Structure: `Map<EventBusHashCode, Map<EventType, List<ExclusiveListener>>>`
/// Manages FIFO queue of exclusive listeners waiting to receive events.
Map<int, Map<Type, List<ExclusiveListener>>> _exclusiveQueue = {};

/// Currently active exclusive listener for each event type.
///
/// Structure: `Map<EventBusHashCode, Map<EventType, ExclusiveListener?>>`
/// Tracks which listener is currently receiving exclusive events.
Map<int, Map<Type, ExclusiveListener?>> _activeExclusiveListener = {};

/// Represents an exclusive event listener in the queue system.
///
/// Contains all necessary information to manage an exclusive listener:
/// callback function, context access, and subscription management.
class ExclusiveListener {
  /// Unique identifier for the module that owns this listener
  final int moduleId;

  /// Callback function to execute when event is received
  final Function callback;

  /// Function to get current BuildContext for the callback
  final BuildContext? Function() getContext;

  /// Stream subscription when this listener is active
  StreamSubscription<dynamic>? subscription;

  ExclusiveListener({
    required this.moduleId,
    required this.callback,
    required this.getContext,
  });
}

/// Default global EventBus used by the modular event system.
///
/// This is the main bus that manages all events when no custom EventBus
/// is provided. Enables decoupled communication between modules.
final EventBus _eventBus = EventBus();

/// Gets the current Navigator context from the modular navigator key.
///
/// This context is used in event callbacks to provide access to the current
/// navigation state. Can be null in web applications during page refreshes
/// or redirects before the widget tree is fully mounted.
BuildContext? get _navigatorContext => modularNavigatorKey.currentContext;

/// Gets debug logging configuration from SetupModular
bool get _debugLog => SetupModular.instance.debugLogEventBus;

/// Gets auto-dispose configuration from SetupModular
bool get _autoDisposeEvents => SetupModular.instance.autoDisposeEvents;

/// Clears all global event state - useful for testing
///
/// **WARNING**: This should only be used for testing purposes.
/// In production, this could cause memory leaks if called inappropriately.
@visibleForTesting
void clearEventModuleState() {
  _eventSubscriptions.values.forEach((subscriptions) {
    subscriptions.values.forEach((subscription) => subscription.cancel());
  });
  _eventSubscriptions.clear();

  _exclusiveStreams.clear();
  _exclusiveQueue.clear();
  _activeExclusiveListener.clear();

  EventModule._disposeSubscriptions.clear();
}

/// Singleton class to manage global events in the application.
///
/// Provides a simplified interface to register event listeners
/// and fire events using the global EventBus. Useful for communication
/// between components that are not part of a specific EventModule.
///
/// **Usage Example:**
/// ```dart
/// // Register a listener
/// ModularEvent.instance.on<LogoutEvent>((event, context) {
///   if (context != null) {
///     context.go('/login');
///   }
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

  /// Gets EventBus identifier for internal tracking
  int _eventBusId(EventBus eventBus) => eventBus.hashCode;

  /// Removes a specific listener for an event type.
  ///
  /// Cancels the active subscription for event type [T] and removes it
  /// from the active subscriptions list. Useful for manual cleanup.
  ///
  /// **Parameters:**
  /// - `eventBus`: Specific EventBus (optional, uses global if not provided)
  ///
  /// **Example:**
  /// ```dart
  /// ModularEvent.instance.dispose<MyEvent>();
  /// ```
  void dispose<T>({EventBus? eventBus}) {
    eventBus ??= _eventBus;
    final eventBusId = _eventBusId(eventBus);
    _eventSubscriptions[eventBusId]?[T]?.cancel();
    _eventSubscriptions[eventBusId]?.remove(T);
  }

  /// Registers a listener for events of type [T].
  ///
  /// The callback will be executed whenever an event of type [T] is fired.
  /// The current Navigator context is provided automatically, but can be `null`.
  ///
  /// **Context Information:**
  /// The `context` parameter is obtained from `modularNavigatorKey.currentContext`.
  /// This context represents the current navigation context and can be used for
  /// navigation operations, accessing Scaffold, and other Flutter widget operations.
  ///
  /// **Important Web Consideration:**
  /// In web applications, especially during redirects or page refreshes, the context
  /// might not be available (null) if the event is fired before the widget tree is
  /// fully mounted. Always check if context is not null before using it.
  ///
  /// **Parameters:**
  /// - `callback`: Function that will be executed when the event is received
  /// - `eventBus`: Specific EventBus (optional, uses global if not provided)
  /// - `exclusive`: If true, only one listener receives the event (default: false)
  ///
  /// **Example:**
  /// ```dart
  /// ModularEvent.instance.on<ShowSnackBarEvent>((event, context) {
  ///   if (context != null) {
  ///     ScaffoldMessenger.of(context).showSnackBar(
  ///       SnackBar(content: Text(event.message))
  ///     );
  ///   }
  /// });
  /// ```
  void on<T>(
    void Function(T event, BuildContext? context) callback, {
    EventBus? eventBus,
    @Deprecated('Use exclusive parameter instead. broadcast will be removed in a future version. 4.0') bool? broadcast,
    bool exclusive = false,
  }) {
    exclusive = broadcast ?? exclusive;
    eventBus ??= _eventBus;
    final eventBusId = _eventBusId(eventBus);

    // Initialize subscription map if it doesn't exist
    _eventSubscriptions[eventBusId] ??= {};

    // Cancel any existing subscription for this event type
    _eventSubscriptions[eventBusId]?[T]?.cancel();

    if (exclusive) {
      _eventSubscriptions[eventBusId]![T] = eventBus.on<T>().asBroadcastStream().listen((event) {
        if (_debugLog) log('🎭 Event received: ${event.runtimeType}', name: 'EVENT GO_ROUTER_MODULAR');
        return callback(event, _navigatorContext);
      });
    } else {
      _eventSubscriptions[eventBusId]![T] = eventBus.on<T>().listen((event) {
        if (_debugLog) log('🎭 Event received: ${event.runtimeType}', name: 'EVENT GO_ROUTER_MODULAR');
        return callback(event, _navigatorContext);
      });
    }
  }

  /// Fires an event in the application.
  ///
  /// All listeners registered for type [T] will receive this event.
  /// This is a static method to facilitate usage anywhere in the application.
  ///
  /// **Parameters:**
  /// - `event`: Instance of the event to be fired
  /// - `eventBus`: Specific EventBus (optional, uses global if not provided)
  ///
  /// **Example:**
  /// ```dart
  /// // Fire an event
  /// ModularEvent.fire(ShowSnackBarEvent(message: 'Hello World!'));
  ///
  /// // With custom EventBus
  /// ModularEvent.fire(MyEvent(), eventBus: customEventBus);
  /// ```
  static void fire<T>(T event, {EventBus? eventBus}) {
    eventBus ??= _eventBus;
    if (_debugLog) log('🔥 Event fired: ${event.runtimeType}', name: 'EVENT GO_ROUTER_MODULAR');
    eventBus.fire(event);
  }
}

/// Abstract module to implement event system with automatic lifecycle management.
///
/// Extend this class to create modules that respond to specific events.
/// EventModule automatically manages the lifecycle of listeners,
/// registering them when the module is initialized and removing them when destroyed.
///
/// **Main Features:**
/// - Auto-registration of listeners through the [listen] method
/// - Automatic memory leak management
/// - Integration with go_router_modular's modular system
/// - Custom EventBus support
/// - Exclusive event listener support with queue system
///
/// **Implementation Example:**
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
///         ScaffoldMessenger.of(context).showSnackBar(
///           SnackBar(content: Text(event.message))
///         );
///       }
///     });
///
///     on<LogoutEvent>((event, context) {
///       if (context != null) {
///         context.go('/login');
///       }
///     }, exclusive: true);
///   }
/// }
/// ```
abstract class EventModule extends Module {
  /// Tracks which event subscriptions should be auto-disposed
  static final Map<int, Map<Type, bool>> _disposeSubscriptions = {};

  /// Internal EventBus instance for this module
  late final EventBus _internalEventBus;

  /// Unique identifier for this module instance
  int get _eventBusId => _internalEventBus.hashCode + hashCode;

  /// Creates an instance of EventModule.
  ///
  /// **Parameters:**
  /// - `eventBus`: Custom EventBus (optional, uses global if not provided)
  EventModule({EventBus? eventBus}) {
    _internalEventBus = eventBus ?? _eventBus;
  }

  /// Abstract method where you should register all event listeners.
  ///
  /// This method is called automatically when the module is initialized.
  /// Implement this method to define which events the module should listen to
  /// and how it should respond to them.
  ///
  /// **Example:**
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
  ///     if (context != null) {
  ///       context.go('/home');
  ///     }
  ///   }, exclusive: true);
  /// }
  /// ```
  void listen();

  /// Registers a listener for events of type [T] within the module.
  ///
  /// This method should be used within the [listen] method to register
  /// event handlers. The listener will be automatically removed when
  /// the module is destroyed (if [autoDispose] is `true`).
  ///
  /// **Context Information:**
  /// The `context` parameter is obtained from `modularNavigatorKey.currentContext`.
  /// This context represents the current navigation context and can be used for
  /// navigation operations, accessing Scaffold, and other Flutter widget operations.
  ///
  /// **Important Web Consideration:**
  /// In web applications, especially during redirects or page refreshes, the context
  /// might not be available (null) if the event is fired before the widget tree is
  /// fully mounted. Always check if context is not null before using it.
  ///
  /// **Exclusive Events:**
  /// When `exclusive: true`, only one module can receive the event at a time.
  /// If multiple modules register for the same exclusive event, they form a queue.
  /// When the active listener is disposed, the next in queue automatically takes over.
  ///
  /// **Parameters:**
  /// - `callback`: Function executed when the event is received
  /// - `autoDispose`: If true, automatically removes listener when module is destroyed
  /// - `exclusive`: If true, only one listener receives the event at a time
  ///
  /// **Example:**
  /// ```dart
  /// // Regular listener (all modules receive the event)
  /// on<ShowSnackBarEvent>((event, context) {
  ///   if (context != null) {
  ///     ScaffoldMessenger.of(context).showSnackBar(
  ///       SnackBar(content: Text(event.message))
  ///     );
  ///   }
  /// });
  ///
  /// // Exclusive listener (only one module receives at a time)
  /// on<PlayMusicEvent>((event, context) {
  ///   playMusic(event.song);
  /// }, exclusive: true);
  /// ```
  void on<T>(
    void Function(T event, BuildContext? context) callback, {
    bool? autoDispose,
    @Deprecated('Use exclusive parameter instead. broadcast will be removed in a future version. 4.0') bool? broadcast,
    bool exclusive = false,
  }) {
    exclusive = broadcast ?? exclusive;

    // Initialize subscription maps
    _eventSubscriptions[_eventBusId] ??= {};
    _disposeSubscriptions[_eventBusId] ??= {};

    // Cancel previous listener for this event type in this module
    _eventSubscriptions[_eventBusId]?[T]?.cancel();

    final eventBusHashCode = _internalEventBus.hashCode;
    _exclusiveStreams[eventBusHashCode] ??= {};
    _exclusiveQueue[eventBusHashCode] ??= {};
    _activeExclusiveListener[eventBusHashCode] ??= {};

    if (exclusive) {
      _registerExclusiveListener<T>(callback, eventBusHashCode);
    } else {
      _registerRegularListener<T>(callback, eventBusHashCode);
    }

    _disposeSubscriptions[_eventBusId]![T] = autoDispose ?? _autoDisposeEvents;
  }

  /// Registers an exclusive event listener with queue management.
  ///
  /// **Parameters:**
  /// - `callback`: Function to execute when event is received
  /// - `eventBusHashCode`: Hash code of the EventBus for tracking
  void _registerExclusiveListener<T>(
    void Function(T event, BuildContext? context) callback,
    int eventBusHashCode,
  ) {
    // Ensure we have a single broadcast stream for this event type
    if (_exclusiveStreams[eventBusHashCode]![T] == null) {
      _exclusiveStreams[eventBusHashCode]![T] = _internalEventBus.on<T>().asBroadcastStream();
    }

    // Initialize queue if it doesn't exist
    _exclusiveQueue[eventBusHashCode]![T] ??= [];

    // Create listener for the queue
    final exclusiveListener = ExclusiveListener(
      moduleId: _eventBusId,
      callback: callback,
      getContext: () => _navigatorContext,
    );

    // Remove any previous listener from this module for this event type
    _exclusiveQueue[eventBusHashCode]![T]!.removeWhere((listener) => listener.moduleId == _eventBusId);

    // Add to queue
    _exclusiveQueue[eventBusHashCode]![T]!.add(exclusiveListener);

    // If this module was the active listener, deactivate it
    final currentActive = _activeExclusiveListener[eventBusHashCode]![T];
    if (currentActive?.moduleId == _eventBusId) {
      currentActive?.subscription?.cancel();
      _activeExclusiveListener[eventBusHashCode]![T] = null;
    }

    // If no active listener, activate this one
    if (_activeExclusiveListener[eventBusHashCode]![T] == null) {
      _activateNextExclusiveListener<T>(T, eventBusHashCode);
    }

    // Subscription will be stored automatically by _activateNextExclusiveListener
  }

  /// Registers a regular (non-exclusive) event listener.
  ///
  /// **Parameters:**
  /// - `callback`: Function to execute when event is received
  /// - `eventBusHashCode`: Hash code of the EventBus for tracking
  void _registerRegularListener<T>(
    void Function(T event, BuildContext? context) callback,
    int eventBusHashCode,
  ) {
    // Don't register if there's an active exclusive stream for this event type
    if (_exclusiveStreams[eventBusHashCode]?[T] != null) {
      return;
    }

    _eventSubscriptions[_eventBusId]![T] = _internalEventBus.on<T>().listen((event) {
      if (_debugLog) log('🎭 Event received: ${event.runtimeType}', name: 'EVENT GO_ROUTER_MODULAR');
      
      // 🌍 IMPORTANTE: Executar callback SEM contexto de módulo ativo
      // Isso permite busca global de dependências em listen() callbacks
      final previousContext = InjectionManager.instance.currentModuleContext;
      try {
        // Limpar contexto temporariamente para permitir busca global
        if (previousContext != null) {
          InjectionManager.instance.clearModuleContextTemporarily();
        }
        return callback(event, _navigatorContext);
      } finally {
        // Restaurar contexto anterior
        if (previousContext != null) {
          InjectionManager.instance.setModuleContext(previousContext);
        }
      }
    });
  }

  /// Activates the next exclusive listener in the queue.
  ///
  /// This method is called when the current active exclusive listener is disposed
  /// or when the first exclusive listener is registered.
  ///
  /// **Parameters:**
  /// - `eventType`: Type of the event to activate listener for
  /// - `eventBusHashCode`: Hash code of the EventBus for tracking
  void _activateNextExclusiveListener<T>(Type eventType, int eventBusHashCode) {
    final queue = _exclusiveQueue[eventBusHashCode]?[eventType];
    if (queue == null || queue.isEmpty) {
      _activeExclusiveListener[eventBusHashCode]![eventType] = null;
      return;
    }

    // Get the first listener in queue (FIFO)
    final nextListener = queue.first;

    // Cancel previous active listener if it exists
    final currentActive = _activeExclusiveListener[eventBusHashCode]![eventType];
    currentActive?.subscription?.cancel();

    // Activate the next listener
    nextListener.subscription = _exclusiveStreams[eventBusHashCode]![eventType]!.listen((event) {
      if (_debugLog) log('🎭 Event received: ${event.runtimeType}', name: 'EVENT GO_ROUTER_MODULAR');
      return nextListener.callback(event, nextListener.getContext());
    });

    // Mark as active
    _activeExclusiveListener[eventBusHashCode]![eventType] = nextListener;

    // Store subscription in the module's subscription map for proper disposal
    _eventSubscriptions[nextListener.moduleId] ??= {};
    _eventSubscriptions[nextListener.moduleId]![eventType] = nextListener.subscription!;
  }

  @override
  void initState(Injector i) {
    listen();
    super.initState(i);
  }

  @override
  void dispose() {
    final eventBusHashCode = _internalEventBus.hashCode;

    _disposeSubscriptions[_eventBusId]?.forEach((key, value) {
      if (value) {
        _eventSubscriptions[_eventBusId]?[key]?.cancel();
        _eventSubscriptions[_eventBusId]?.remove(key);

        _handleExclusiveListenerDisposal(key, eventBusHashCode);
      }
    });

    _disposeSubscriptions.remove(_eventBusId);
    super.dispose();
  }

  /// Handles disposal of exclusive listeners and queue management.
  ///
  /// This method removes the module from exclusive queues and activates
  /// the next listener if this was the active one.
  ///
  /// **Parameters:**
  /// - `eventType`: Type of the event being disposed
  /// - `eventBusHashCode`: Hash code of the EventBus for tracking
  void _handleExclusiveListenerDisposal(Type eventType, int eventBusHashCode) {
    final queue = _exclusiveQueue[eventBusHashCode]?[eventType];
    if (queue != null) {
      // Remove this module from the queue
      queue.removeWhere((listener) => listener.moduleId == _eventBusId);

      // If this was the active listener, activate the next one
      final activeListener = _activeExclusiveListener[eventBusHashCode]?[eventType];
      if (activeListener?.moduleId == _eventBusId) {
        activeListener?.subscription?.cancel();
        _activeExclusiveListener[eventBusHashCode]![eventType] = null;
        _activateNextExclusiveListener(eventType, eventBusHashCode);
      }
    }

    // Clean up exclusive streams if no more listeners exist
    final remainingQueue = _exclusiveQueue[eventBusHashCode]?[eventType];
    if (remainingQueue == null || remainingQueue.isEmpty) {
      _exclusiveStreams[eventBusHashCode]?.remove(eventType);
      _exclusiveQueue[eventBusHashCode]?.remove(eventType);
      _activeExclusiveListener[eventBusHashCode]?.remove(eventType);
    }
  }
}
