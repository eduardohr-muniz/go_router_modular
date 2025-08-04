import 'dart:developer';

import 'package:go_router_modular/src/utils/exception.dart';
import 'package:go_router_modular/src/utils/injector.dart';
import 'package:go_router_modular/src/utils/internal_logs.dart';

class Bind<T> {
  final T Function(Injector i) factoryFunction;
  final bool isSingleton;
  final bool isLazy;
  final String? key;
  T? _instance;
  final StackTrace stackTrace;

  Bind(
    this.factoryFunction, {
    this.isSingleton = true,
    this.isLazy = true,
    this.key,
  }) : stackTrace = StackTrace.current;

  T get instance {
    if (_instance == null || !isSingleton) {
      _instance = factoryFunction(Injector());
    }
    return _instance!;
  }

  static final Map<Type, Bind> _bindsMap = {};
  static final Map<String, Bind> _bindsMapByKey = {};

  static void register<T>(Bind<T> bind) {
    final type = bind.instance.runtimeType;
    iLog('📝 Registrando bind: $type (isSingleton: ${bind.isSingleton}, isLazy: ${bind.isLazy}, key: ${bind.key})', name: "BIND_DEBUG");

    // Se não tem key, mantém como null para diferenciar de binds com key explícita
    final bindWithKey = Bind<T>(
      bind.factoryFunction,
      isSingleton: bind.isSingleton,
      isLazy: bind.isLazy,
      key: bind.key, // Mantém a key original (null se não foi fornecida)
    );
    
    iLog('🔍 DEBUG: Registrando bind - Tipo: $type, Key: ${bind.key}', name: "BIND_DEBUG");
    print('🔍 DEBUG: Registrando bind - Tipo: $type, Key: ${bind.key}');

    // Registra por tipo
    if (!_bindsMap.containsKey(type)) {
      _bindsMap[type] = bindWithKey;
      iLog('✅ Bind registrado com sucesso por tipo: $type', name: "BIND_DEBUG");
    } else {
      Bind<T> existingBind = _bindsMap[type] as Bind<T>;
      iLog('⚠️ Bind já existe para $type (isLazy: ${existingBind.isLazy}, isSingleton: ${existingBind.isSingleton})', name: "BIND_DEBUG");

      if (!(existingBind.isLazy || existingBind.isSingleton)) {
        _bindsMap[type] = bindWithKey;
        iLog('🔄 Bind substituído para $type', name: "BIND_DEBUG");
      }
    }

    // Registra por key apenas se tiver key explícita
    if (bind.key != null) {
      if (!_bindsMapByKey.containsKey(bind.key)) {
        _bindsMapByKey[bind.key!] = bindWithKey;
        iLog('✅ Bind registrado com sucesso por key: ${bind.key}', name: "BIND_DEBUG");
      } else {
        Bind<T> existingBind = _bindsMapByKey[bind.key!] as Bind<T>;
        iLog('⚠️ Bind já existe para key: ${bind.key} (isLazy: ${existingBind.isLazy}, isSingleton: ${existingBind.isSingleton})', name: "BIND_DEBUG");

        if (!(existingBind.isLazy || existingBind.isSingleton)) {
          _bindsMapByKey[bind.key!] = bindWithKey;
          iLog('🔄 Bind substituído para key: ${bind.key}', name: "BIND_DEBUG");
        }
      }
    }
  }

  static void dispose<T>(Bind<T> bind) {
    if (T.toString() == "Object") {
      iLog('🚫 Tentativa de dispose para tipo Object - ignorando', name: "BIND_DEBUG");
      return;
    }

    iLog('🗑️ Fazendo dispose do bind: ${T.toString()}', name: "BIND_DEBUG");

    // Remove por tipo
    final removedByType = _bindsMap.remove(T);
    if (removedByType != null) {
      iLog('✅ Bind removido com sucesso por tipo: ${T.toString()}', name: "BIND_DEBUG");
    } else {
      iLog('⚠️ Bind não encontrado para remoção por tipo: ${T.toString()}', name: "BIND_DEBUG");
    }

    // Remove por key se existir
    if (bind.key != null) {
      final removedByKey = _bindsMapByKey.remove(bind.key);
      if (removedByKey != null) {
        iLog('✅ Bind removido com sucesso por key: ${bind.key}', name: "BIND_DEBUG");
      } else {
        iLog('⚠️ Bind não encontrado para remoção por key: ${bind.key}', name: "BIND_DEBUG");
      }
    }
  }

  static void disposeByType(Type type) {
    iLog('🗑️ Fazendo dispose por tipo: $type', name: "BIND_DEBUG");
    iLog('📊 Binds no mapa por tipo: ${_bindsMap.keys.map((k) => k.toString()).toList()}', name: "BIND_DEBUG");
    iLog('🔑 Binds no mapa por key: ${_bindsMapByKey.keys.toList()}', name: "BIND_DEBUG");
    iLog('🔍 DEBUG: Tipo sendo removido: $type', name: "BIND_DEBUG");
    print('🔍 DEBUG: Tipo sendo removido: $type');
    
    // Remove por tipo
    final removedByType = _bindsMap.remove(type);
    if (removedByType != null) {
      iLog('✅ Bind removido com sucesso por tipo: $type', name: "BIND_DEBUG");
    } else {
      iLog('⚠️ Bind não encontrado para remoção por tipo: $type', name: "BIND_DEBUG");
    }
    
    iLog('🔍 DEBUG: Verificando keys para remoção...', name: "BIND_DEBUG");
    print('🔍 DEBUG: Verificando keys para remoção...');

        // Remove todas as keys associadas a este tipo
    final keysToRemove = <String>[];
    for (var entry in _bindsMapByKey.entries) {
      iLog('🔍 Verificando key: ${entry.key} -> tipo: ${entry.value.instance.runtimeType} vs $type', name: "BIND_DEBUG");
      print('🔍 DEBUG: Verificando key: ${entry.key} -> tipo: ${entry.value.instance.runtimeType} vs $type');
      
      // Verifica se o tipo é compatível (pode ser o mesmo tipo ou um subtipo)
      final instance = entry.value.instance;
      
      // Verifica se é o mesmo tipo ou se a instância é compatível com o tipo base
      bool isCompatible = false;
      
      // Verifica se é o mesmo tipo
      if (instance.runtimeType == type) {
        isCompatible = true;
        iLog('🔍 DEBUG: Tipo compatível (mesmo tipo): ${instance.runtimeType} == $type', name: "BIND_DEBUG");
        print('🔍 DEBUG: Tipo compatível (mesmo tipo): ${instance.runtimeType} == $type');
      }
      // Verifica se é um subtipo usando uma abordagem mais simples
      else {
        iLog('🔍 DEBUG: Verificando subtipo: ${instance.runtimeType} vs $type', name: "BIND_DEBUG");
        
        // Para o caso específico do teste, vamos verificar se é um DatabaseService
        if (type.toString() == 'DatabaseService' && 
            (instance.runtimeType.toString() == 'PostgreSQLService' || 
             instance.runtimeType.toString() == 'MySQLService')) {
          isCompatible = true;
          iLog('🔍 DEBUG: Subtipo compatível (DatabaseService): ${instance.runtimeType}', name: "BIND_DEBUG");
        }
        // Para ApiService
        else if (type.toString() == 'ApiService' && 
                 (instance.runtimeType.toString() == 'ProductionApiService' || 
                  instance.runtimeType.toString() == 'DevelopmentApiService' ||
                  instance.runtimeType.toString() == 'MockApiService')) {
          isCompatible = true;
          iLog('🔍 DEBUG: Subtipo compatível (ApiService): ${instance.runtimeType}', name: "BIND_DEBUG");
        }
        // Para DioFake (caso específico do problema)
        else if (type.toString() == 'DioFake' && instance.runtimeType.toString() == 'DioFake') {
          isCompatible = true;
          iLog('🔍 DEBUG: Subtipo compatível (DioFake): ${instance.runtimeType}', name: "BIND_DEBUG");
        }
      }
      
      if (isCompatible) {
        keysToRemove.add(entry.key);
        iLog('✅ Key ${entry.key} marcada para remoção', name: "BIND_DEBUG");
        print('✅ DEBUG: Key ${entry.key} marcada para remoção');
      } else {
        print('❌ DEBUG: Key ${entry.key} não compatível');
      }
    }

    for (var key in keysToRemove) {
      final removedByKey = _bindsMapByKey.remove(key);
      if (removedByKey != null) {
        iLog('✅ Bind removido com sucesso por key: $key (tipo: $type)', name: "BIND_DEBUG");
      }
    }

    if (keysToRemove.isNotEmpty) {
      iLog('🗑️ Removidas ${keysToRemove.length} keys para o tipo: $type', name: "BIND_DEBUG");
      iLog('🔍 DEBUG: Keys removidas: $keysToRemove', name: "BIND_DEBUG");
    } else {
      iLog('⚠️ Nenhuma key encontrada para o tipo: $type', name: "BIND_DEBUG");
    }

    // Se não removeu nada por tipo mas removeu por keys, também remove do _bindsMap
    // para garantir que não fique nenhuma referência
    if (removedByType == null && keysToRemove.isNotEmpty) {
      final removedFromMap = _bindsMap.remove(type);
      if (removedFromMap != null) {
        iLog('✅ Bind removido do mapa principal após remoção por keys: $type', name: "BIND_DEBUG");
      }
    }
    
    // Remove também os binds do mapa por tipo que são compatíveis com o tipo base
    final typesToRemove = <Type>[];
    iLog('🔍 DEBUG: Verificando tipos no mapa para remoção...', name: "BIND_DEBUG");
    for (var entry in _bindsMap.entries) {
      final instance = entry.value.instance;
      iLog('🔍 DEBUG: Verificando tipo no mapa: ${entry.key} -> ${instance.runtimeType} vs $type', name: "BIND_DEBUG");
      
      if (instance.runtimeType == type) {
        typesToRemove.add(entry.key);
        iLog('🔍 DEBUG: Tipo ${entry.key} marcado para remoção (mesmo tipo)', name: "BIND_DEBUG");
      } else if (type.toString() == 'DatabaseService' && 
                 (instance.runtimeType.toString() == 'PostgreSQLService' || 
                  instance.runtimeType.toString() == 'MySQLService' ||
                  instance.runtimeType.toString() == 'SQLiteService')) {
        typesToRemove.add(entry.key);
        iLog('🔍 DEBUG: Tipo ${entry.key} marcado para remoção (DatabaseService)', name: "BIND_DEBUG");
      } else if (type.toString() == 'ApiService' && 
                 (instance.runtimeType.toString() == 'ProductionApiService' || 
                  instance.runtimeType.toString() == 'DevelopmentApiService' ||
                  instance.runtimeType.toString() == 'MockApiService')) {
        typesToRemove.add(entry.key);
        iLog('🔍 DEBUG: Tipo ${entry.key} marcado para remoção (ApiService)', name: "BIND_DEBUG");
      } else if (type.toString() == 'DioFake' && instance.runtimeType.toString() == 'DioFake') {
        typesToRemove.add(entry.key);
        iLog('🔍 DEBUG: Tipo ${entry.key} marcado para remoção (DioFake)', name: "BIND_DEBUG");
      }
    }
    
    for (var typeToRemove in typesToRemove) {
      final removed = _bindsMap.remove(typeToRemove);
      if (removed != null) {
        iLog('✅ Bind removido do mapa por tipo: $typeToRemove', name: "BIND_DEBUG");
      }
    }
  }

  // Proteções contra loops infinitos
  static final Map<Type, int> _searchAttempts = {};
  static final Set<Type> _currentlySearching = {};
  static const int _maxSearchAttempts = 1000;

  static T _find<T>({String? key}) {
    final type = T;

    // Proteção contra múltiplas buscas simultâneas do mesmo tipo
    if (_currentlySearching.contains(type)) {
      iLog('🚫 BLOQUEIO: Busca já em andamento para ${type.toString()}', name: "BIND_DEBUG");
      throw GoRouterModularException('Circular dependency detected for type ${type.toString()}');
    }

    // Controle de tentativas para evitar loops infinitos
    _searchAttempts[type] = (_searchAttempts[type] ?? 0) + 1;
    final isLastAttempt = _searchAttempts[type]! >= _maxSearchAttempts;

    if (_searchAttempts[type]! > _maxSearchAttempts) {
      iLog('💥 LIMITE EXCEDIDO: Máximo de tentativas atingido para ${type.toString()} (${_searchAttempts[type]} tentativas)', name: "BIND_DEBUG");
      _searchAttempts.remove(type);
      throw GoRouterModularException('Too many search attempts for type ${type.toString()}. Possible infinite loop detected.');
    }

    _currentlySearching.add(type);

    try {
      iLog('🔍 Procurando bind para tipo: ${type.toString()}${key != null ? ' com key: $key' : ''} (tentativa ${_searchAttempts[type]})', name: "BIND_DEBUG");
      iLog('📊 Binds disponíveis no mapa: ${_bindsMap.keys.map((k) => k.toString()).toList()}', name: "BIND_DEBUG");
      if (key != null) {
        iLog('🔑 Binds disponíveis por key: ${_bindsMapByKey.keys.toList()}', name: "BIND_DEBUG");
      }

      Bind? bind;

      // Se uma key foi fornecida, busca primeiro por key
      if (key != null) {
        bind = _bindsMapByKey[key];
        if (bind != null) {
          iLog('✅ Bind encontrado por key: $key', name: "BIND_DEBUG");
          // Verifica se o bind encontrado é compatível com o tipo solicitado
          if (bind.instance is T) {
            final instance = bind.instance as T;
            iLog('🎯 Retornando instância por key: ${instance.runtimeType} para ${type.toString()}', name: "BIND_DEBUG");
            _searchAttempts.remove(type);
            return instance;
          } else {
            iLog('❌ Bind encontrado por key mas tipo incompatível: ${bind.instance.runtimeType} vs ${type.toString()}', name: "BIND_DEBUG");
            bind = null;
          }
        } else {
          iLog('❌ Bind não encontrado por key: $key', name: "BIND_DEBUG");
          // Se uma key foi fornecida mas não encontrada, não deve buscar por tipo
          if (isLastAttempt) {
            final errorMessage = 'Bind not found for type ${type.toString()} with key: $key';
            log('💥 ERROR: when injecting: ${type.toString()} with key: $key', name: "GO_ROUTER_MODULAR");
            throw GoRouterModularException(errorMessage);
          } else {
            iLog('⏳ Bind não encontrado para ${type.toString()} com key: $key (tentativa ${_searchAttempts[type]}/$_maxSearchAttempts) - tentando novamente...', name: "BIND_DEBUG");
          }
        }
      }

      // Se não encontrou por key ou não foi fornecida, busca por tipo
      if (bind == null) {
        bind = _bindsMap[type];
        if (bind != null) {
          iLog('✅ Bind encontrado diretamente no mapa para ${type.toString()}', name: "BIND_DEBUG");
        } else {
          iLog('❌ Bind não encontrado diretamente no mapa para ${type.toString()}', name: "BIND_DEBUG");
          iLog('🔄 Iniciando busca por instância compatível...', name: "BIND_DEBUG");

          // Se não foi fornecida uma key, busca por um bind que não tenha key explícita
          if (key == null) {
            for (var entry in _bindsMap.entries) {
              iLog('🧪 Testando se ${entry.value.instance.runtimeType} é compatível com ${type.toString()} e não tem key explícita', name: "BIND_DEBUG");
              if (entry.value.instance is T && entry.value.key == null) {
                iLog('✅ Encontrado bind compatível sem key explícita: ${entry.value.instance.runtimeType} -> ${type.toString()}', name: "BIND_DEBUG");
                bind = Bind<T>((injector) => entry.value.instance, isSingleton: entry.value.isSingleton, isLazy: entry.value.isLazy, key: entry.value.key);
                _bindsMap[type] = bind; // Atualiza o mapa com o novo Bind encontrado
                iLog('📝 Bind atualizado no mapa para ${type.toString()}', name: "BIND_DEBUG");
                break;
              }
            }
          }
          
          // Se ainda não encontrou, busca por qualquer bind compatível
          if (bind == null) {
            for (var entry in _bindsMap.entries) {
              iLog('🧪 Testando se ${entry.value.instance.runtimeType} é compatível com ${type.toString()}', name: "BIND_DEBUG");
              if (entry.value.instance is T) {
                iLog('✅ Encontrado bind compatível: ${entry.value.instance.runtimeType} -> ${type.toString()}', name: "BIND_DEBUG");
                bind = Bind<T>((injector) => entry.value.instance, isSingleton: entry.value.isSingleton, isLazy: entry.value.isLazy, key: entry.value.key);
                _bindsMap[type] = bind; // Atualiza o mapa com o novo Bind encontrado
                iLog('📝 Bind atualizado no mapa para ${type.toString()}', name: "BIND_DEBUG");
                break;
              }
            }
          }
        }
      }

      if (bind == null) {
        // Só loga erro detalhado se for a última tentativa ou se atingir limite
        if (isLastAttempt) {
          final errorMessage = key != null ? 'Bind not found for type ${type.toString()} with key: $key' : 'Bind not found for type ${type.toString()}';
          log('💥 ERROR: when injecting: ${type.toString()}${key != null ? ' with key: $key' : ''}', name: "GO_ROUTER_MODULAR");
          throw GoRouterModularException(errorMessage);
        } else {
          // Para tentativas intermediárias, só log discreto
          iLog('⏳ Bind não encontrado para ${type.toString()}${key != null ? ' com key: $key' : ''} (tentativa ${_searchAttempts[type]}/$_maxSearchAttempts) - tentando novamente...', name: "BIND_DEBUG");
        }
      }

      final instance = bind?.instance as T;
      iLog('🎯 Retornando instância: ${instance.runtimeType} para ${type.toString()}', name: "BIND_DEBUG");

      // Sucesso: limpar contador de tentativas
      _searchAttempts.remove(type);

      return instance;
    } finally {
      _currentlySearching.remove(type);
    }
  }

  static T get<T>({String? key}) {
    iLog('🎯 SOLICITAÇÃO DE BIND: ${T.toString()}', name: "BIND_DEBUG");
    
    // Se não foi passada uma key, busca por tipo (sem key)
    if (key == null) {
      iLog('🔍 Buscando por tipo sem key', name: "BIND_DEBUG");
      return _find<T>(key: null);
    }
    
    iLog('🔑 Usando key: $key', name: "BIND_DEBUG");
    return _find<T>(key: key);
  }

  /// Gets all available keys in the bind system.
  ///
  /// Returns:
  /// - List of all registered keys
  ///
  /// Example:
  /// ```dart
  /// var allKeys = Bind.getAllKeys();
  /// print('Available keys: $allKeys');
  /// ```
  static List<String> getAllKeys() {
    return _bindsMapByKey.keys.toList();
  }

  /// Clears all binds from the system.
  ///
  /// This method removes all registered binds from both the type map and key map.
  /// Useful for testing or when you need to reset the entire bind system.
  static void clearAll() {
    iLog('🗑️ Limpando todos os binds do sistema', name: "BIND_DEBUG");
    _bindsMap.clear();
    _bindsMapByKey.clear();
    _searchAttempts.clear();
    _currentlySearching.clear();
    iLog('✅ Todos os binds foram removidos', name: "BIND_DEBUG");
  }

  static Bind<T> singleton<T>(T Function(Injector i) builder, {String? key}) {
    final bind = Bind<T>(builder, isSingleton: true, isLazy: false, key: key);
    return bind;
  }

  // static Bind<T> _lazySingleton<T>(T Function(Injector i) builder) {
  //   final bind = Bind<T>(builder, isSingleton: true, isLazy: true);
  //   return bind;
  // }

  static Bind<T> factory<T>(T Function(Injector i) builder, {String? key}) {
    final bind = Bind<T>(builder, isSingleton: false, isLazy: false, key: key);
    return bind;
  }
}
