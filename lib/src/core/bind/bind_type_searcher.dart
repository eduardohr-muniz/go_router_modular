import 'package:flutter/foundation.dart';
import 'package:go_router_modular/src/core/bind/bind.dart';
import 'package:go_router_modular/src/core/bind/bind_storage.dart';
import 'package:go_router_modular/src/di/injector.dart';

/// Responsável APENAS por buscar binds por tipo direto
/// Responsabilidade única: Busca direta de binds por tipo
class BindTypeSearcher {
  final BindStorage _storage = BindStorage.instance;

  /// Busca um bind por tipo direto
  /// Retorna null se não encontrar ou se encontrar bind com key quando buscou sem key
  Bind? searchByType<T>(Type type, String? key) {
    // Se key não é null, busca normalmente
    if (key != null) {
      return _storage.bindsMap[type];
    }

    // Se key é null, busca apenas binds que não têm key
    // Isso garante que get<T>() sem key não pegue binds com key
    final bind = _storage.bindsMap[type];
    if (bind != null && bind.key != null) {
      // Bind encontrado tem key, mas estamos buscando sem key
      return null;
    }

    return bind;
  }

  /// Cria instância do bind encontrado por tipo
  T createInstanceFromTypeBind<T>(Bind bind) {
    // Para factory, executa a função a cada chamada
    if (!bind.isSingleton) {
      return bind.factoryFunction(Injector()) as T;
    }
    
    // Para singleton, usa a instância já criada
    final instance = bind.instance as T;
    
    // Valida ChangeNotifier
    if (instance is ChangeNotifier) {
      try {
        final testListener = () {};
        instance.addListener(testListener);
        instance.removeListener(testListener);
      } catch (e) {
        // ChangeNotifier disposto
      }
    }
    
    return instance;
  }
}
