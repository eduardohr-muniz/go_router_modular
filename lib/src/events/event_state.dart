import 'dart:async';
import 'package:flutter/material.dart';

/// Centralized storage for all event system state.
class EventState {
  static final EventState _instance = EventState._();
  EventState._();
  static EventState get instance => _instance;

  /// Active subscriptions: Map<EventBusId, Map<EventType, StreamSubscription>>
  final Map<int, Map<Type, StreamSubscription<dynamic>>> subscriptions = {};

  /// Broadcast streams for exclusive listeners: Map<EventBusHashCode, Map<EventType, Stream>>
  final Map<int, Map<Type, Stream<dynamic>>> exclusiveStreams = {};

  /// FIFO queue of exclusive listeners: Map<EventBusHashCode, Map<EventType, List<ExclusiveListener>>>
  final Map<int, Map<Type, List<ExclusiveListener>>> exclusiveQueue = {};

  /// Currently active exclusive listener per event type
  final Map<int, Map<Type, ExclusiveListener?>> activeExclusiveListener = {};

  /// Auto-dispose tracking for EventModule listeners
  final Map<int, Map<Type, bool>> disposeSubscriptions = {};

  void clearAll() {
    subscriptions.values.forEach((subs) {
      subs.values.forEach((sub) => sub.cancel());
    });
    subscriptions.clear();
    exclusiveStreams.clear();
    exclusiveQueue.clear();
    activeExclusiveListener.clear();
    disposeSubscriptions.clear();
  }
}

/// Represents an exclusive event listener in the queue system.
class ExclusiveListener {
  final int moduleId;
  final Function callback;
  final BuildContext? Function() getContext;
  StreamSubscription<dynamic>? subscription;

  ExclusiveListener({
    required this.moduleId,
    required this.callback,
    required this.getContext,
  });
}
