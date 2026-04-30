import 'package:flutter/foundation.dart';

class CleanBind {
  static bool fromInstance(dynamic instance) {
    try {
      // Try dispose() first (ChangeNotifier, custom Disposable, etc.)
      if (_tryCall(instance, 'dispose')) return true;

      // Try close() (Bloc, Cubit, StreamController, etc.)
      if (_tryCall(instance, 'close')) return true;

      // Try cancel() (Timer, StreamSubscription, etc.)
      if (_tryCall(instance, 'cancel')) return true;

      return false;
    } catch (_) {
      return false;
    }
  }

  static bool _tryCall(dynamic instance, String method) {
    try {
      switch (method) {
        case 'dispose':
          (instance as dynamic).dispose();
          return true;
        case 'close':
          (instance as dynamic).close();
          return true;
        case 'cancel':
          (instance as dynamic).cancel();
          return true;
        default:
          return false;
      }
    } on NoSuchMethodError {
      return false;
    } catch (_) {
      // Method exists but threw - consider cleanup attempted
      return false;
    }
  }

  @visibleForTesting
  static bool hasMethod(dynamic instance, String methodName) {
    return _tryCall(instance, methodName);
  }
}
