import 'dart:async';
import 'dart:collection';
import 'package:go_router_modular/src/shared/exception.dart';

/// Sequential operation queue to ensure deterministic ordering.
class OperationQueue {
  final Queue<Future<void> Function()> _queue = Queue<Future<void> Function()>();
  bool _isProcessing = false;

  Future<T> enqueue<T>(Future<T> Function() operation) async {
    final completer = Completer<T>();

    _queue.add(() async {
      try {
        final result = await operation();
        completer.complete(result);
      } catch (e) {
        completer.completeError(e);
      }
    });

    _processQueue();
    return completer.future;
  }

  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;

    try {
      while (_queue.isNotEmpty) {
        final operation = _queue.removeFirst();
        try {
          await operation();
        } catch (e) {
          if (e is GoRouterModularException) rethrow;
        }
      }
    } finally {
      _isProcessing = false;
    }
  }
}
