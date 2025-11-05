import 'package:flutter/foundation.dart';
import 'package:go_router_modular/src/core/bind/bind.dart';
import 'package:go_router_modular/src/core/bind/bind_storage.dart';
import 'package:go_router_modular/src/di/injector.dart';
import 'package:go_router_modular/src/exceptions/exception.dart';

/// Responsável APENAS por buscar binds por key
/// Responsabilidade única: Busca de binds usando chave
class BindKeySearcher {
  final BindStorage _storage = BindStorage.instance;

  /// Busca um bind por key
  /// Retorna o bind se encontrado e compatível, null caso contrário
  /// Lança exceção se key fornecida não encontrar bind
  Bind? searchByKey<T>(Type type, String key) {
    final bind = _storage.bindsMapByKey[key];

    if (bind == null) {
      throw GoRouterModularException('❌ Bind not found for type "${type.toString()}" with key: $key');
    }

    // Verifica se o bind encontrado é compatível com o tipo solicitado
    if (bind.instance is! T) {
      return null;
    }

    return bind;
  }

  /// Cria instância do bind encontrado por key
  T createInstanceFromKeyBind<T>(Bind bind) {
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
