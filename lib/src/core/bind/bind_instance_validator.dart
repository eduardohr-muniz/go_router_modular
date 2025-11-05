import 'package:flutter/foundation.dart';

/// Responsável APENAS por validar instâncias
/// Responsabilidade única: Validação de ChangeNotifier
class BindInstanceValidator {
  /// Valida se ChangeNotifier está válido (não foi disposto)
  void validateChangeNotifier(dynamic instance) {
    if (instance is! ChangeNotifier) return;

    try {
      final testListener = () {};
      instance.addListener(testListener);
      instance.removeListener(testListener);
    } catch (e) {
      // ChangeNotifier disposto
    }
  }
}
