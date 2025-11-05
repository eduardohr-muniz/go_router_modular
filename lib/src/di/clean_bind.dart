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

      // 3. Se tem método dispose() (detecta por tentar chamar)
      try {
        (instance as dynamic).dispose();
        return true;
      } catch (e) {}

      // 4. Se tem método close() (detecta por tentar chamar)
      try {
        (instance as dynamic).close();
        return true;
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

  /// Verifica se uma instância tem um método específico SEM executá-lo
  /// IMPORTANTE: Este método NÃO executa o método, apenas verifica a existência
  @visibleForTesting
  static bool hasMethod(dynamic instance, String methodName) {
    try {
      // Cria uma cópia temporária para tentar chamar o método
      // Se der erro NoSuchMethodError, o método não existe
      // Se der qualquer outro erro ou sucesso, o método existe
      final dynamic dynamicInstance = instance;
      
      // Usa um try-catch para verificar se o método existe
      // sem de fato executá-lo em produção
      switch (methodName) {
        case 'dispose':
          // Verifica se o tipo tem o método dispose
          return dynamicInstance.runtimeType.toString().toLowerCase().contains('dispos') ||
                 _tryHasMethod(dynamicInstance, 'dispose');
        case 'close':
          // Verifica se o tipo tem o método close
          return _tryHasMethod(dynamicInstance, 'close');
        case 'cancel':
          // Verifica se o tipo tem o método cancel
          return _tryHasMethod(dynamicInstance, 'cancel');
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Helper interno para verificar método sem executá-lo
  static bool _tryHasMethod(dynamic instance, String methodName) {
    try {
      // Tenta acessar o método como uma propriedade
      // Se não existir, lança NoSuchMethodError
      switch (methodName) {
        case 'dispose':
          instance.dispose;
          return true;
        case 'close':
          instance.close;
          return true;
        case 'cancel':
          instance.cancel;
          return true;
        default:
          return false;
      }
    } catch (e) {
      // Se lançar NoSuchMethodError, o método não existe
      return e.toString().contains('NoSuchMethod') ? false : true;
    }
  }
}
