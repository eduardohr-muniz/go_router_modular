import 'package:go_router_modular/src/core/bind/bind.dart';
import 'package:go_router_modular/src/core/bind/bind_storage.dart';
import 'package:go_router_modular/src/core/bind/bind_search_protection.dart';
import 'package:go_router_modular/src/core/dependency_analyzer/dependency_analyzer.dart';
import 'package:go_router_modular/src/di/clean_bind.dart';

/// Responsável APENAS por dispose de binds
/// Responsabilidade única: Limpar e fazer dispose de binds
class BindDisposer {
  final BindStorage _storage = BindStorage.instance;
  final BindSearchProtection _protection = BindSearchProtection.instance;

  void dispose<T>() {
    if (T == Object) {
      return;
    }

    final bind = _storage.bindsMap[T];
    if (bind != null) {
      try {
        // Só dispõe se houver instância cacheada
        // Não cria nova instância durante dispose
        if (bind.cachedInstance != null) {
          CleanBind.fromInstance(bind.cachedInstance!);
        }
      } catch (e) {
        // Ignora erros ao acessar/dispor instance
      }

      // Limpa o cache para evitar retornar instância disposta
      bind.clearCache();

      // Remove do _bindsMap
      _storage.bindsMap.remove(T);

      // Remove do _bindsMapByKey se tiver key
      if (bind.key != null) {
        _storage.bindsMapByKey.remove(bind.key);
      }
    }

    // Também procura no _bindsMapByKey por binds deste tipo
    final keysToRemove = <String>[];
    for (var entry in _storage.bindsMapByKey.entries) {
      try {
        if (entry.value.cachedInstance is T) {
          keysToRemove.add(entry.key);
          if (entry.value.cachedInstance != null) {
            CleanBind.fromInstance(entry.value.cachedInstance!);
          }
          entry.value.clearCache();
        }
      } catch (_) {
        // Ignora erros
      }
    }

    for (var key in keysToRemove) {
      _storage.bindsMapByKey.remove(key);
    }

    // Limpar estado de busca
    _protection.currentlySearching.remove(T);
    _protection.searchAttempts.remove(T);
    DependencyAnalyzer.clearTypeHistory(T);
  }

  void disposeByKey(String key) {
    final bind = _storage.bindsMapByKey[key];
    if (bind != null) {
      // Só dispõe se houver instância cacheada
      if (bind.cachedInstance != null) {
        CleanBind.fromInstance(bind.cachedInstance!);

        // Obtém o tipo do cache para não criar nova instância
        final type = bind.cachedInstance!.runtimeType;
        _storage.bindsMap.remove(type);

        // Limpar estado de busca
        _protection.currentlySearching.remove(type);
        _protection.searchAttempts.remove(type);
        DependencyAnalyzer.clearTypeHistory(type);
      }

      bind.clearCache();
    }

    _storage.bindsMapByKey.remove(key);
  }

  void disposeByType(Type type) {
    // Remove por tipo - chama CleanBind para a instância principal
    final bind = _storage.bindsMap[type];
    if (bind != null) {
      try {
        // Só dispõe se houver instância cacheada
        if (bind.cachedInstance != null) {
          CleanBind.fromInstance(bind.cachedInstance!);
        }
      } catch (e) {
        // Ignora erros ao acessar/dispor instance
      }

      // Limpa o cache para evitar retornar instância disposta
      bind.clearCache();
    }

    _storage.bindsMap.remove(type);

    // Remove todas as keys associadas a este tipo
    final keysToRemove = <String>[];
    for (var entry in _storage.bindsMapByKey.entries) {
      // Verifica se o tipo é compatível (pode ser o mesmo tipo ou um subtipo)
      final bindValue = entry.value;
      try {
        // Só verifica se houver instância cacheada
        if (bindValue.cachedInstance != null) {
          // Verifica se é o mesmo tipo
          bool isCompatible = bindValue.cachedInstance!.runtimeType == type;

          if (isCompatible) {
            keysToRemove.add(entry.key);
            // Chama CleanBind para cada instância que será removida
            CleanBind.fromInstance(bindValue.cachedInstance!);
            // Limpa o cache para evitar retornar instância disposta
            bindValue.clearCache();
          }
        }
      } catch (_) {
        // Se falhar ao acessar instance, continua
      }
    }

    // Remove as keys marcadas
    for (var key in keysToRemove) {
      _storage.bindsMapByKey.remove(key);
    }

    // Remove também os binds do mapa por tipo que são compatíveis com o tipo base
    final typesToRemove = <Type>[];
    for (var entry in _storage.bindsMap.entries) {
      try {
        final bindValue = entry.value;
        // Só verifica se houver instância cacheada
        if (bindValue.cachedInstance != null) {
          if (bindValue.cachedInstance!.runtimeType == type) {
            typesToRemove.add(entry.key);
            // Chama CleanBind para cada instância que será removida
            CleanBind.fromInstance(bindValue.cachedInstance!);
            // Limpa o cache para evitar retornar instância disposta
            bindValue.clearCache();
          }
        }
      } catch (_) {
        // Se falhar ao acessar instance, continua
      }
    }

    for (var typeToRemove in typesToRemove) {
      _storage.bindsMap.remove(typeToRemove);
    }

    // Limpar estado de busca
    _protection.currentlySearching.remove(type);
    _protection.searchAttempts.remove(type);
    DependencyAnalyzer.clearTypeHistory(type);

    // Limpar também os tipos relacionados que foram removidos
    for (var typeToRemove in typesToRemove) {
      _protection.currentlySearching.remove(typeToRemove);
      _protection.searchAttempts.remove(typeToRemove);
    }
  }

  void clearAll() {
    // Limpa estado de busca PRIMEIRO para evitar modificações concorrentes
    _protection.clearAll();
    DependencyAnalyzer.clearAll();

    // Faz cópia dos binds para evitar modificações durante iteração
    final bindsToClean = List<Bind>.from(_storage.bindsMap.values);
    final bindsByKeyToClean = List<Bind>.from(_storage.bindsMapByKey.values);

    // Limpa os maps ANTES de chamar CleanBind para evitar modificações concorrentes
    _storage.bindsMap.clear();
    _storage.bindsMapByKey.clear();
    _storage.pendingObjectBinds.clear();

    // Chama CleanBind para todas as instâncias depois de limpar os maps
    for (var bind in bindsToClean) {
      try {
        // Só dispõe se houver instância cacheada
        if (bind.cachedInstance != null) {
          CleanBind.fromInstance(bind.cachedInstance!);
        }
        // Limpa o cache para evitar retornar instância disposta
        bind.clearCache();
      } catch (_) {
        // Ignora erros ao limpar instâncias (pode ter sido disposto)
      }
    }

    for (var bind in bindsByKeyToClean) {
      try {
        // Só dispõe se houver instância cacheada
        if (bind.cachedInstance != null) {
          CleanBind.fromInstance(bind.cachedInstance!);
        }
        // Limpa o cache para evitar retornar instância disposta
        bind.clearCache();
      } catch (_) {
        // Ignora erros ao limpar instâncias (pode ter sido disposto)
      }
    }
  }
}
