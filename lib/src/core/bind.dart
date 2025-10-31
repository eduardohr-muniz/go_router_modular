import 'dart:developer';

import 'package:go_router_modular/src/di/clean_bind.dart';
import 'package:go_router_modular/src/exceptions/exception.dart';
import 'package:go_router_modular/src/di/injector.dart';
import 'package:go_router_modular/src/internal/internal_logs.dart';
import 'package:go_router_modular/src/core/dependency_analyzer.dart';

class Bind<T> {
  final T Function(Injector i) factoryFunction;
  final bool isSingleton;
  final bool isLazy;
  final String? key;
  final StackTrace stackTrace;
  T? _cachedInstance;

  Bind(this.factoryFunction, {this.isSingleton = true, this.isLazy = false, this.key}) : stackTrace = StackTrace.current;

  T get instance {
    if (_cachedInstance == null || !isSingleton) {
      _cachedInstance = factoryFunction(Injector());
    }
    return _cachedInstance!;
  }

  static final Map<Type, Bind> _bindsMap = {};
  static final Map<String, Bind> _bindsMapByKey = {};

  static void register<T>(Bind<T> bind) {
    final type = bind.instance.runtimeType;
    iLog('📝 REGISTER: Tentando registrar bind para tipo: $type, key: ${bind.key}', name: 'BIND_REGISTER');

    if (bind.isSingleton) {
      final singleton = _bindsMap[type];
      if (singleton != null && singleton.key == bind.key) {
        iLog('⏭️ REGISTER: Bind já existe para tipo $type com mesma key, ignorando', name: 'BIND_REGISTER');
        return;
      }
    }

    _bindsMap[type] = bind;
    iLog('✅ REGISTER: Bind registrado com sucesso para tipo: $type', name: 'BIND_REGISTER');

    // Registrar por key se fornecida
    if (bind.key != null) {
      _bindsMapByKey[bind.key!] = bind;
      iLog('🔑 REGISTER: Bind também registrado por key: ${bind.key}', name: 'BIND_REGISTER');
    }
  }

  static void dispose<T>() {
    if (T == Object) {
      return;
    }

    iLog('🗑️ DISPOSE: Tentando dispor bind para tipo: $T', name: 'BIND_DISPOSE');
    final bind = _bindsMap[T];
    if (bind != null) {
      CleanBind.fromInstance(bind.instance);

      // Remove do _bindsMap
      _bindsMap.remove(T);
      iLog('🗑️ DISPOSE: Bind removido do _bindsMap para tipo: $T', name: 'BIND_DISPOSE');

      // Remove do _bindsMapByKey se tiver key
      if (bind.key != null) {
        _bindsMapByKey.remove(bind.key);
        iLog('🗑️ DISPOSE: Bind removido do _bindsMapByKey para key: ${bind.key}', name: 'BIND_DISPOSE');
      }
    } else {
      iLog('⚠️ DISPOSE: Bind não encontrado no _bindsMap para tipo: $T', name: 'BIND_DISPOSE');
    }

    // Limpar estado de busca usando análise probabilística
    final searchProbability = DependencyAnalyzer.calculateSuccessProbability(T);
    final wasSearching = _currentlySearching.contains(T);
    final hadAttempts = _searchAttempts.containsKey(T);
    final shouldCleanState = searchProbability < 0.5 || wasSearching || hadAttempts;

    _currentlySearching.remove(T);
    _searchAttempts.remove(T);
    DependencyAnalyzer.clearTypeHistory(T);

    if (shouldCleanState) {
      iLog('🧹 DISPOSE: Estado de busca limpo para tipo: $T (probabilidade: ${(searchProbability * 100).toStringAsFixed(1)}%)', name: 'BIND_DISPOSE');
    }
  }

  static void disposeByKey(String key) {
    final bind = _bindsMapByKey[key];
    if (bind != null) {
      CleanBind.fromInstance(bind.instance);
    }

    final removed = _bindsMapByKey.remove(key);
    if (removed != null) {
      final type = removed.instance.runtimeType;
      _bindsMap.remove(type);

      // Limpar estado de busca usando análise probabilística
      final searchProbability = DependencyAnalyzer.calculateSuccessProbability(type);
      final shouldCleanState = searchProbability < 0.5 || _currentlySearching.contains(type) || _searchAttempts.containsKey(type);

      _currentlySearching.remove(type);
      _searchAttempts.remove(type);
      DependencyAnalyzer.clearTypeHistory(type);

      if (shouldCleanState) {
        iLog('🧹 DISPOSE_BY_KEY: Estado limpo para tipo: $type (probabilidade: ${(searchProbability * 100).toStringAsFixed(1)}%)', name: 'BIND_DISPOSE');
      }
    }
  }

  static void disposeByType(Type type) {
    iLog('🗑️ DISPOSE_BY_TYPE: Tentando dispor bind para tipo: $type', name: 'BIND_DISPOSE');

    // Remove por tipo - chama CleanBind para a instância principal
    final bind = _bindsMap[type];
    if (bind != null) {
      CleanBind.fromInstance(bind.instance);
      iLog('🗑️ DISPOSE_BY_TYPE: CleanBind chamado para tipo: $type', name: 'BIND_DISPOSE');
    }

    _bindsMap.remove(type);
    iLog('🗑️ DISPOSE_BY_TYPE: Tipo removido do _bindsMap: $type', name: 'BIND_DISPOSE');

    // Remove todas as keys associadas a este tipo
    final keysToRemove = <String>[];
    for (var entry in _bindsMapByKey.entries) {
      // Verifica se o tipo é compatível (pode ser o mesmo tipo ou um subtipo)
      final instance = entry.value.instance;

      // Verifica se é o mesmo tipo
      bool isCompatible = instance.runtimeType == type;

      if (isCompatible) {
        keysToRemove.add(entry.key);
        // Chama CleanBind para cada instância que será removida
        CleanBind.fromInstance(instance);
      }
    }

    // Remove as keys marcadas
    for (var key in keysToRemove) {
      _bindsMapByKey.remove(key);
      iLog('🗑️ DISPOSE_BY_TYPE: Key removida: $key', name: 'BIND_DISPOSE');
    }

    // Remove também os binds do mapa por tipo que são compatíveis com o tipo base
    final typesToRemove = <Type>[];
    for (var entry in _bindsMap.entries) {
      final instance = entry.value.instance;

      if (instance.runtimeType == type) {
        typesToRemove.add(entry.key);
        // Chama CleanBind para cada instância que será removida
        CleanBind.fromInstance(instance);
      }
    }

    for (var typeToRemove in typesToRemove) {
      _bindsMap.remove(typeToRemove);
      iLog('🗑️ DISPOSE_BY_TYPE: Tipo compatível removido: $typeToRemove', name: 'BIND_DISPOSE');
    }

    // Limpar estado de busca usando análise probabilística
    final searchProbability = DependencyAnalyzer.calculateSuccessProbability(type);
    final wasSearching = _currentlySearching.contains(type);
    final hadAttempts = _searchAttempts.containsKey(type);
    final shouldCleanState = searchProbability < 0.5 || wasSearching || hadAttempts;

    _currentlySearching.remove(type);
    _searchAttempts.remove(type);
    DependencyAnalyzer.clearTypeHistory(type);

    if (shouldCleanState) {
      iLog('🧹 DISPOSE_BY_TYPE: Estado de busca limpo para tipo: $type (probabilidade: ${(searchProbability * 100).toStringAsFixed(1)}%)', name: 'BIND_DISPOSE');
    }

    // Limpar também os tipos relacionados que foram removidos
    for (var typeToRemove in typesToRemove) {
      _currentlySearching.remove(typeToRemove);
      _searchAttempts.remove(typeToRemove);
      iLog('🧹 DISPOSE_BY_TYPE: Estado limpo para tipo relacionado: $typeToRemove', name: 'BIND_DISPOSE');
    }
  }

  // Proteções contra loops infinitos
  static final Map<Type, int> _searchAttempts = {};
  static final Set<Type> _currentlySearching = {};
  static const int _maxSearchAttempts = 1000;

  static void cleanSearchAttempts() {
    _searchAttempts.clear();
    _currentlySearching.clear();
  }

  static T _find<T>({String? key}) {
    final type = T;
    iLog('🔍 _FIND: Iniciando busca para tipo: $type, key: $key', name: 'BIND_FIND');

    // Proteção contra múltiplas buscas simultâneas do mesmo tipo
    if (_currentlySearching.contains(type)) {
      iLog('❌ _FIND: Tipo $type já está sendo buscado simultaneamente - possível loop infinito!', name: 'BIND_FIND');
      iLog('📊 _FIND: Estado atual - _currentlySearching: ${_currentlySearching.map((t) => t.toString()).join(", ")}', name: 'BIND_FIND');
      iLog('📊 _FIND: Tentativas para $type: ${_searchAttempts[type] ?? 0}', name: 'BIND_FIND');

      // Verifica se o bind realmente existe no mapa para dar mensagem mais útil
      bool bindExists = false;
      if (key != null) {
        bindExists = _bindsMapByKey.containsKey(key);
      }
      if (!bindExists) {
        bindExists = _bindsMap.containsKey(type);
      }
      if (!bindExists) {
        bindExists = _bindsMap.values.any((bind) => bind.instance is T && bind.key == null);
      }

      if (!bindExists) {
        iLog('⚠️ _FIND: Bind não existe no mapa - pode ter sido disposto durante busca anterior', name: 'BIND_FIND');
        // Se o bind não existe mais, limpa o estado e permite nova busca
        _currentlySearching.remove(type);
        _searchAttempts.remove(type);
        iLog('🧹 _FIND: Estado limpo para permitir nova busca', name: 'BIND_FIND');
        // Continua a busca normalmente abaixo
      } else {
        // Bind existe mas está sendo buscado simultaneamente - loop infinito
        throw GoRouterModularException('❌ Oops! I couldn\'t find a compatible bind for "${type.toString()}". Please add the bind before trying to use it.');
      }
    }

    // Controle de tentativas usando análise probabilística
    _searchAttempts[type] = (_searchAttempts[type] ?? 0) + 1;
    final attemptCount = _searchAttempts[type]!;
    final successProbability = DependencyAnalyzer.calculateSuccessProbability(type);
    final shouldAllowRetry = DependencyAnalyzer.shouldAllowRetry(type, attemptCount);

    iLog('🔢 _FIND: Tentativa #$attemptCount para tipo: $type (probabilidade: ${(successProbability * 100).toStringAsFixed(1)}%, permitir retry: $shouldAllowRetry)', name: 'BIND_FIND');

    if (!shouldAllowRetry) {
      _searchAttempts.remove(type);
      DependencyAnalyzer.recordSearchAttempt(type, false);
      iLog('❌ _FIND: Probabilidade muito baixa para tipo: $type (${(successProbability * 100).toStringAsFixed(1)}%) - possível loop infinito', name: 'BIND_FIND');
      throw GoRouterModularException('❌ Too many search attempts for type "${type.toString()}". Possible infinite loop detected. Success probability: ${(successProbability * 100).toStringAsFixed(1)}%');
    }

    _currentlySearching.add(type);
    DependencyAnalyzer.startSearch(type);
    iLog('➕ _FIND: Tipo $type adicionado ao _currentlySearching', name: 'BIND_FIND');

    try {
      Bind? bind;

      // Se uma key foi fornecida, busca primeiro por key
      if (key != null) {
        iLog('🔑 _FIND: Buscando por key: $key', name: 'BIND_FIND');
        bind = _bindsMapByKey[key];
        if (bind != null) {
          iLog('✅ _FIND: Bind encontrado por key: $key', name: 'BIND_FIND');
          // Verifica se o bind encontrado é compatível com o tipo solicitado
          if (bind.instance is T) {
            // Para factory, executa a função a cada chamada
            if (!bind.isSingleton) {
              final instance = bind.factoryFunction(Injector()) as T;
              _searchAttempts.remove(type);
              DependencyAnalyzer.recordSearchAttempt(type, true);
              DependencyAnalyzer.endSearch(type);
              iLog('✅ _FIND: Retornando instância factory para tipo: $type', name: 'BIND_FIND');
              return instance;
            } else {
              // Para singleton, usa a instância já criada
              final instance = bind.instance as T;
              _searchAttempts.remove(type);
              DependencyAnalyzer.recordSearchAttempt(type, true);
              DependencyAnalyzer.endSearch(type);
              iLog('✅ _FIND: Retornando instância singleton para tipo: $type', name: 'BIND_FIND');
              return instance;
            }
          } else {
            iLog('⚠️ _FIND: Bind encontrado por key mas não é compatível com tipo $type', name: 'BIND_FIND');
            bind = null;
          }
        } else {
          // Se uma key foi fornecida mas não encontrada, falha imediatamente
          iLog('❌ _FIND: Bind não encontrado por key: $key', name: 'BIND_FIND');
          final errorMessage = '❌ Bind not found for type "${type.toString()}" with key: $key';
          throw GoRouterModularException(errorMessage);
        }
      }

      // Se não encontrou por key ou não foi fornecida, busca por tipo
      if (bind == null) {
        iLog('🔍 _FIND: Buscando por tipo direto: $type', name: 'BIND_FIND');
        bind = _bindsMap[type];
        if (bind != null) {
          iLog('✅ _FIND: Bind encontrado por tipo direto: $type', name: 'BIND_FIND');
          // Para factory, executa a função a cada chamada
          if (!bind.isSingleton) {
            final instance = bind.factoryFunction(Injector()) as T;
            _searchAttempts.remove(type);
            iLog('✅ _FIND: Retornando instância factory para tipo: $type', name: 'BIND_FIND');
            return instance;
          } else {
            // Para singleton, usa a instância já criada
            final instance = bind.instance as T;
            _searchAttempts.remove(type);
            iLog('✅ _FIND: Retornando instância singleton para tipo: $type', name: 'BIND_FIND');
            return instance;
          }
        } else {
          iLog('🔍 _FIND: Não encontrado por tipo direto, buscando por compatibilidade...', name: 'BIND_FIND');
          // Se não foi fornecida uma key, busca APENAS por binds que não tenham key explícita
          for (var entry in _bindsMap.entries) {
            if (entry.value.instance is T && entry.value.key == null) {
              iLog('✅ _FIND: Bind compatível encontrado: ${entry.key} -> $type', name: 'BIND_FIND');
              bind = Bind<T>((injector) => entry.value.instance as T, isSingleton: entry.value.isSingleton, isLazy: entry.value.isLazy, key: entry.value.key);
              _bindsMap[type] = bind;

              // Retorna a instância após criar o bind
              if (!bind.isSingleton) {
                final instance = bind.factoryFunction(Injector()) as T;
                _searchAttempts.remove(type);
                DependencyAnalyzer.recordSearchAttempt(type, true);
                DependencyAnalyzer.endSearch(type);
                iLog('✅ _FIND: Retornando instância factory compatível para tipo: $type', name: 'BIND_FIND');
                return instance;
              } else {
                final instance = bind.instance as T;
                _searchAttempts.remove(type);
                DependencyAnalyzer.recordSearchAttempt(type, true);
                DependencyAnalyzer.endSearch(type);
                iLog('✅ _FIND: Retornando instância singleton compatível para tipo: $type', name: 'BIND_FIND');
                return instance;
              }
            }
          }
        }
      }

      // Se chegou aqui e bind ainda é null, não encontrou
      if (bind == null) {
        iLog('❌ _FIND: Bind não encontrado para tipo: $type (tentativa $attemptCount/$_maxSearchAttempts)', name: 'BIND_FIND');

        // Se uma key específica foi solicitada e não foi encontrada, falha imediatamente
        if (key != null) {
          final errorMessage = '❌ Bind not found for type "${type.toString()}" with key: $key';
          throw GoRouterModularException(errorMessage);
        }

        // Log detalhado com informações sobre binds disponíveis
        log('[GO_ROUTER_MODULAR] ❌ Bind not found for type: "${type.toString()}"');
        log('[GO_ROUTER_MODULAR] 📊 Available binds: ${_bindsMap.keys.map((k) => k.toString()).join(', ')}');

        // Log detalhado de cada bind disponível
        log('[GO_ROUTER_MODULAR] 🔍 Detailed bind analysis:');
        for (var entry in _bindsMap.entries) {
          log('[GO_ROUTER_MODULAR]   - Type: ${entry.key}');
          log('[GO_ROUTER_MODULAR]   - Instance: ${entry.value.instance.runtimeType}');
          log('[GO_ROUTER_MODULAR]   - Key: ${entry.value.key}');
          log('[GO_ROUTER_MODULAR]   - IsSingleton: ${entry.value.isSingleton}');
          log('[GO_ROUTER_MODULAR]   - IsLazy: ${entry.value.isLazy}');
          log('[GO_ROUTER_MODULAR]   ---');
        }

        final errorMessage = 'Bind not found for type ${type.toString()}';
        throw GoRouterModularException(errorMessage);
      }

      // Se chegou aqui, bind não é null
      final instance = bind.instance as T;

      // Sucesso: limpar contador de tentativas
      _searchAttempts.remove(type);
      DependencyAnalyzer.recordSearchAttempt(type, true);
      DependencyAnalyzer.endSearch(type);
      iLog('✅ _FIND: Sucesso! Retornando instância para tipo: $type', name: 'BIND_FIND');

      return instance;
    } catch (e) {
      DependencyAnalyzer.recordSearchAttempt(type, false);
      DependencyAnalyzer.endSearch(type);
      rethrow;
    } finally {
      _currentlySearching.remove(type);
      DependencyAnalyzer.endSearch(type);
      iLog('🧹 _FIND: Removendo tipo $type do _currentlySearching', name: 'BIND_FIND');
    }
  }

  static T get<T>({String? key}) {
    iLog('📥 GET: Chamado para tipo: $T, key: $key', name: 'BIND_GET');

    // Se não foi passada uma key, busca por tipo (sem key)
    if (key == null) {
      final instance = _find<T>(key: null);
      iLog('📤 GET: Retornando instância para tipo: $T (sem key)', name: 'BIND_GET');
      return instance;
    }

    final instance = _find<T>(key: key);
    iLog('📤 GET: Retornando instância para tipo: $T (com key: $key)', name: 'BIND_GET');
    return instance;
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
    // Chama CleanBind para todas as instâncias antes de limpar
    for (var bind in _bindsMap.values) {
      CleanBind.fromInstance(bind.instance);
    }

    for (var bind in _bindsMapByKey.values) {
      CleanBind.fromInstance(bind.instance);
    }

    _bindsMap.clear();
    _bindsMapByKey.clear();
    _searchAttempts.clear();
    _currentlySearching.clear();
    DependencyAnalyzer.clearAll();
  }

  static Bind<T> singleton<T>(T Function(Injector i) builder, {String? key}) {
    final bind = Bind<T>(builder, isSingleton: true, isLazy: false, key: key);
    return bind;
  }

  static Bind<T> factory<T>(T Function(Injector i) builder, {String? key}) {
    final bind = Bind<T>(builder, isSingleton: false, isLazy: false, key: key);
    return bind;
  }
}
