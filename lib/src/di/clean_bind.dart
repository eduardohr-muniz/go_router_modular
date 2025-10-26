import 'package:flutter/foundation.dart';

class CleanBind {
  static bool fromInstance(dynamic instance) {
    try {
      // 1. Se implementa Disposable (interface personalizada) - PRIORIDADE MÁXIMA
      if (instance is Disposable) {
        try {
          instance.dispose();
          return true;
        } catch (e) {
          // Log mas não falha
          if (kDebugMode) {
            print('⚠️ Failed to dispose Disposable instance: $e');
          }
        }
      }

      // 2. Tentar chamar dispose() diretamente
      try {
        (instance as dynamic).dispose();
        return true;
      } catch (e) {
        // Método não existe ou falhou, tentar próximo
      }

      // 3. Tentar chamar close() diretamente
      try {
        (instance as dynamic).close();
        return true;
      } catch (e) {
        // Método não existe ou falhou, tentar próximo
      }

      // 4. Tentar chamar cancel() para Timers
      try {
        (instance as dynamic).cancel();
        return true;
      } catch (e) {
        // Método não existe ou falhou
      }

      // 5. Se não encontrou nenhum método de cleanup conhecido
      return false;
    } catch (e) {
      // Log mas não falha - cleanup é opcional
      if (kDebugMode) {
        print('⚠️ CleanBind failed for ${instance.runtimeType}: $e');
      }
      return false;
    }
  }
}

/// Interface Disposable para permitir cleanup automático
/// Seguindo a abordagem do flutter_modular
abstract class Disposable {
  void dispose();
}
