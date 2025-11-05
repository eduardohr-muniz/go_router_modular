import 'package:go_router_modular/src/core/bind/bind.dart';
import 'package:go_router_modular/src/core/bind/bind_storage.dart';
import 'package:go_router_modular/src/di/injector.dart';

/// Responsável APENAS por descobrir tipos de Object e pending binds
/// Responsabilidade única: Descoberta de tipos não resolvidos
class BindTypeDiscoverer {
  final BindStorage _storage = BindStorage.instance;

  /// Descobre tipo de binds registrados como Object
  /// Retorna o bind se encontrado e compatível
  Bind? discoverFromObjectBinds<T>(Type type) {
    final objectBinds = <MapEntry<Type, Bind>>[];
    for (var entry in _storage.bindsMap.entries) {
      if (entry.key == Object) {
        objectBinds.add(entry);
      }
    }

    for (var entry in objectBinds) {
      Bind testBind = entry.value;
      try {
        final instance = testBind.factoryFunction(Injector());
        final realType = instance.runtimeType;

        // Se o tipo real é compatível com T, atualiza o registro e retorna
        if (instance is T) {
          // Remove Object e adiciona com tipo real
          if (objectBinds.length == 1) {
            _storage.bindsMap.remove(Object);
          }

          // REGRA: Só registra no _bindsMap se não tem key
          if (testBind.key != null) {
            // Bind com key: só registra no _bindsMapByKey
            _storage.bindsMapByKey[testBind.key!] = testBind;
            return testBind;
          }

          _storage.bindsMap[realType] = testBind;
          return testBind;
        }
      } catch (e) {
        // Se falhar ao criar instância, continua procurando
      }
    }

    return null;
  }

  /// Descobre tipo de binds pendentes
  /// Retorna o bind se encontrado e compatível
  Bind? discoverFromPendingBinds<T>(Type type) {
    final pendingToRemove = <Bind>[];

    for (var pendingBind in _storage.pendingObjectBinds) {
      try {
        final instance = pendingBind.factoryFunction(Injector());
        final realType = instance.runtimeType;

        // Se o tipo real é compatível com T, registra e retorna
        if (instance is T) {
          // REGRA: Só registra no _bindsMap se não tem key
          if (pendingBind.key != null) {
            // Bind com key: só registra no _bindsMapByKey
            _storage.bindsMapByKey[pendingBind.key!] = pendingBind;
            pendingToRemove.add(pendingBind);
            return pendingBind;
          }

          _storage.bindsMap[realType] = pendingBind;
          pendingToRemove.add(pendingBind);
          return pendingBind;
        }
      } catch (e) {
        // Se falhar, mantém na lista pendente
      }
    }

    // Remove binds que foram registrados com sucesso
    for (var bindToRemove in pendingToRemove) {
      _storage.pendingObjectBinds.remove(bindToRemove);
    }

    return null;
  }

  /// Cria instância do bind descoberto
  T createInstanceFromDiscoveredBind<T>(Bind bind) {
    if (!bind.isSingleton) {
      return bind.factoryFunction(Injector()) as T;
    }

    // Para singleton, tentar acessar instance com proteção contra Stack Overflow
    try {
      return bind.instance as T;
    } catch (e) {
      // Se falhar ao acessar instance (possível Stack Overflow), tentar criar nova instância
      return bind.factoryFunction(Injector()) as T;
    }
  }
}
