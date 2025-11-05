import 'package:go_router_modular/src/core/bind/bind.dart';
import 'package:go_router_modular/src/core/bind/bind_storage.dart';
import 'package:go_router_modular/src/di/injector.dart';

/// Responsável APENAS por buscar binds compatíveis
/// Responsabilidade única: Busca de binds por compatibilidade de tipo
class BindCompatibilitySearcher {
  final BindStorage _storage = BindStorage.instance;

  /// Busca bind compatível verificando instâncias
  /// Retorna bind compatível ou null
  Bind? searchCompatibleBind<T>(Type type) {
    for (var entry in _storage.bindsMap.entries) {
      if (entry.key == Object) continue; // Já processado antes

      // Verifica compatibilidade normal (para binds que não são Object)
      // Tenta criar instância para verificar compatibilidade
      if (entry.value.key == null) {
        try {
          final testInstance = entry.value.factoryFunction(Injector());
          if (testInstance is T) {
            final compatibleBind = Bind<T>(
              (injector) => entry.value.factoryFunction(injector) as T,
              isSingleton: entry.value.isSingleton,
              isLazy: entry.value.isLazy,
              key: entry.value.key,
            );
            _storage.bindsMap[type] = compatibleBind;
            return compatibleBind;
          }
        } catch (e) {
          // Se falhar ao criar instância, continua procurando
        }
      }
    }

    return null;
  }

  /// Cria instância do bind compatível
  T createInstanceFromCompatibleBind<T>(Bind bind) {
    if (!bind.isSingleton) {
      return bind.factoryFunction(Injector()) as T;
    }
    
    return bind.instance as T;
  }
}
