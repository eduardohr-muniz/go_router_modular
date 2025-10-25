import 'package:flutter/foundation.dart';

class CleanBind {
  static bool fromInstance(dynamic instance) {
    try {
      final typeName = instance.runtimeType.toString().toLowerCase();

      // 1. Se implementa Disposable (interface personalizada)
      if (instance.runtimeType.toString().contains('Disposable')) {
        try {
          (instance as dynamic).dispose();
          return true;
        } catch (e) {}
      }

      // 2. Se é Cubit/Bloc (detecta por nome da classe)
      if (typeName.contains('cubit') || typeName.contains('bloc')) {
        try {
          (instance as dynamic).close();
          return true;
        } catch (e) {}
      }

      // 3. Se tem método dispose() (detecta por reflection)
      try {
        final disposeMethod = instance.runtimeType.toString();
        if (disposeMethod.contains('dispose') || hasMethod(instance, 'dispose')) {
          (instance as dynamic).dispose();
          return true;
        }
      } catch (e) {}

      // 4. Se tem método close() (detecta por reflection)
      try {
        if (hasMethod(instance, 'close')) {
          (instance as dynamic).close();
          return true;
        }
      } catch (e) {}

      // 5. Se é StreamController ou similar
      if (typeName.contains('streamcontroller') || typeName.contains('stream')) {
        try {
          (instance as dynamic).close();
          return true;
        } catch (e) {}
      }

      // 6. Se é Timer ou similar
      if (typeName.contains('timer')) {
        try {
          (instance as dynamic).cancel();
          return true;
        } catch (e) {}
      }

      // 7. Se não encontrou nenhum método de cleanup conhecido
      return false;
    } catch (e) {
      // Log mas não falha - cleanup é opcional
      return false;
    }
  }

  /// Verifica se uma instância tem um método específico
  @visibleForTesting
  static bool hasMethod(dynamic instance, String methodName) {
    try {
      // Tenta chamar o método diretamente usando dynamic
      final dynamic dynamicInstance = instance;
      switch (methodName) {
        case 'dispose':
          dynamicInstance.dispose();
          return true;
        case 'close':
          dynamicInstance.close();
          return true;
        case 'cancel':
          dynamicInstance.cancel();
          return true;
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }
}
