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
  // Armazena binds temporários registrados como Object até descobrir seus tipos reais
  static final List<Bind> _pendingObjectBinds = [];

  /// Registra um bind preservando seu tipo genérico original
  /// Este método descobre o tipo através da análise da função factory ou tentativa de criação
  static void register(dynamic bind) {
    if (bind is! Bind) {
      throw ArgumentError('Bind.register espera um Bind, mas recebeu ${bind.runtimeType}');
    }

    Type registrationType = Object;

    iLog('📝 REGISTER: Tentando registrar bind - bind.runtimeType=${bind.runtimeType}', name: 'BIND_REGISTER');

    // Primeiro, tenta descobrir o tipo através da análise da função factory
    // Analisa a string da função para encontrar o tipo de retorno
    final factoryString = bind.factoryFunction.toString();

    // Tenta extrair tipo de retorno da factory function
    // Padrões: => TypeName( ou => new TypeName(
    final returnTypePatterns = [
      RegExp(r'=>\s*(\w+)\s*\('),
      RegExp(r'=>\s*new\s+(\w+)\s*\('),
      RegExp(r'=>\s*(\w+)\s*\.'),
    ];

    String? potentialTypeName;
    for (final pattern in returnTypePatterns) {
      final match = pattern.firstMatch(factoryString);
      if (match != null && match.groupCount > 0) {
        potentialTypeName = match.group(1);
        // Verifica se não é uma palavra reservada
        const excludedWords = {'i', 'Injector', 'null', 'return', 'get', 'set', 'if', 'else'};
        if (potentialTypeName != null && !excludedWords.contains(potentialTypeName) && potentialTypeName[0].toUpperCase() == potentialTypeName[0]) {
          break;
        }
        potentialTypeName = null;
      }
    }

    // Se encontrou um tipo potencial, tenta criar instância para confirmar
    // Se não encontrou ou falhou, tenta criar instância diretamente
    try {
      final instance = bind.factoryFunction(Injector());
      registrationType = instance.runtimeType;
      iLog('✅ REGISTER: Tipo real descoberto via instância: $registrationType', name: 'BIND_REGISTER');
    } catch (e) {
      // Se falhar ao criar instância, registra como Object temporariamente
      // Mas adiciona à lista de pending para descoberta posterior
      registrationType = Object;
      _pendingObjectBinds.add(bind);
      iLog('⚠️ REGISTER: Não foi possível criar instância (dependências não disponíveis). Registrando como Object temporariamente. Erro: $e', name: 'BIND_REGISTER');
      iLog('📋 REGISTER: Bind adicionado à lista de pending (total: ${_pendingObjectBinds.length})', name: 'BIND_REGISTER');
    }

    if (bind.isSingleton) {
      final singleton = _bindsMap[registrationType];
      if (singleton != null && singleton.key == bind.key) {
        iLog('⏭️ REGISTER: Bind já existe para tipo $registrationType com mesma key, ignorando', name: 'BIND_REGISTER');
        return;
      }
    }

    _bindsMap[registrationType] = bind;
    iLog('✅ REGISTER: Bind registrado com sucesso para tipo: $registrationType', name: 'BIND_REGISTER');

    // Registrar por key se fornecida
    if (bind.key != null) {
      _bindsMapByKey[bind.key!] = bind;
      iLog('🔑 REGISTER: Bind também registrado por key: ${bind.key}', name: 'BIND_REGISTER');
    }
  }

  /// Versão genérica para compatibilidade (usa o tipo genérico se fornecido)
  static void registerTyped<T>(Bind<T> bind) {
    if (T != Object) {
      // Se T não é Object, usa T diretamente
      if (bind.isSingleton) {
        final singleton = _bindsMap[T];
        if (singleton != null && singleton.key == bind.key) {
          iLog('⏭️ REGISTER: Bind já existe para tipo $T com mesma key, ignorando', name: 'BIND_REGISTER');
          return;
        }
      }
      _bindsMap[T] = bind;
      iLog('✅ REGISTER: Bind registrado com sucesso para tipo: $T', name: 'BIND_REGISTER');
      if (bind.key != null) {
        _bindsMapByKey[bind.key!] = bind;
        iLog('🔑 REGISTER: Bind também registrado por key: ${bind.key}', name: 'BIND_REGISTER');
      }
    } else {
      // Se T é Object, usa o método não genérico
      register(bind);
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

  static void cleanSearchAttempts() {
    _searchAttempts.clear();
    _currentlySearching.clear();
  }

  /// Limpa estado de busca para um tipo específico
  /// Útil quando um módulo é desregistrado para evitar loops infinitos
  static void cleanSearchAttemptsForType(Type type) {
    _searchAttempts.remove(type);
    _currentlySearching.remove(type);
    DependencyAnalyzer.clearTypeHistory(type);
    iLog('🧹 CLEAN_SEARCH: Estado de busca limpo para tipo: $type', name: 'BIND_CLEAN');
  }

  static T _find<T>({String? key}) {
    final type = T;
    iLog('🔍 _FIND: Iniciando busca para tipo: $type, key: $key', name: 'BIND_FIND');

    // Verifica limite ANTES de qualquer coisa para evitar loops infinitos
    final currentAttempts = _searchAttempts[type] ?? 0;
    const maxAbsoluteAttempts = 3; // Limite rigoroso reduzido para 3

    if (currentAttempts >= maxAbsoluteAttempts) {
      // Limpa estado e lança exceção imediatamente SEM adicionar ao _currentlySearching
      _searchAttempts.remove(type);
      _currentlySearching.remove(type);
      DependencyAnalyzer.recordSearchAttempt(type, false);
      DependencyAnalyzer.endSearch(type);
      iLog('❌ _FIND: Limite máximo de tentativas ($maxAbsoluteAttempts) já atingido para tipo: $type - BLOQUEANDO nova tentativa', name: 'BIND_FIND');
      throw GoRouterModularException('❌ Too many search attempts ($currentAttempts) for type "${type.toString()}". Possible infinite loop detected. Please ensure the bind is registered before use.');
    }

    // Proteção contra múltiplas buscas simultâneas do mesmo tipo
    if (_currentlySearching.contains(type)) {
      iLog('❌ _FIND: Tipo $type já está sendo buscado simultaneamente - BLOQUEANDO para evitar loop infinito', name: 'BIND_FIND');
      throw GoRouterModularException('❌ Type "${type.toString()}" is already being searched. Possible infinite loop detected. Please ensure the bind is registered before use.');
    }

    // Incrementa contador de tentativas ANTES de adicionar ao _currentlySearching
    _searchAttempts[type] = currentAttempts + 1;
    final attemptCount = _searchAttempts[type]!;

    // Adiciona ao _currentlySearching APENAS APÓS incrementar tentativas
    _currentlySearching.add(type);
    DependencyAnalyzer.startSearch(type);
    iLog('🔢 _FIND: Tentativa #$attemptCount/$maxAbsoluteAttempts para tipo: $type', name: 'BIND_FIND');

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
          // Se não foi fornecida uma key, busca por binds que possam ser compatíveis
          // Primeiro tenta criar instância de binds registrados como Object para descobrir tipo real
          final objectBinds = <MapEntry<Type, Bind>>[];
          for (var entry in _bindsMap.entries) {
            if (entry.key == Object) {
              objectBinds.add(entry);
            }
          }

          // Primeiro processa binds Object do mapa
          for (var entry in objectBinds) {
            Bind testBind = entry.value;
            try {
              final instance = testBind.factoryFunction(Injector());
              final realType = instance.runtimeType;

              iLog('🔍 _FIND: Tipo real descoberto de Object bind: $realType, buscando $type', name: 'BIND_FIND');

              // Se o tipo real é compatível com T, atualiza o registro e retorna
              if (instance is T) {
                // Remove Object e adiciona com tipo real
                if (objectBinds.length == 1) {
                  _bindsMap.remove(Object);
                }
                _bindsMap[realType] = testBind;
                iLog('✅ _FIND: Tipo real descoberto: $realType (era Object), atualizando registro', name: 'BIND_FIND');

                if (!testBind.isSingleton) {
                  final instance = testBind.factoryFunction(Injector()) as T;
                  _searchAttempts.remove(type);
                  DependencyAnalyzer.recordSearchAttempt(type, true);
                  DependencyAnalyzer.endSearch(type);
                  iLog('✅ _FIND: Retornando instância factory descoberta para tipo: $type', name: 'BIND_FIND');
                  return instance;
                } else {
                  // Para singleton, tentar acessar instance com proteção contra Stack Overflow
                  try {
                    final instance = testBind.instance as T;
                    _searchAttempts.remove(type);
                    DependencyAnalyzer.recordSearchAttempt(type, true);
                    DependencyAnalyzer.endSearch(type);
                    iLog('✅ _FIND: Retornando instância singleton descoberta para tipo: $type', name: 'BIND_FIND');
                    return instance;
                  } catch (e) {
                    // Se falhar ao acessar instance (possível Stack Overflow), tentar criar nova instância
                    iLog('⚠️ _FIND: Erro ao acessar instance singleton, tentando criar nova: $e', name: 'BIND_FIND');
                    final instance = testBind.factoryFunction(Injector()) as T;
                    _searchAttempts.remove(type);
                    DependencyAnalyzer.recordSearchAttempt(type, true);
                    DependencyAnalyzer.endSearch(type);
                    iLog('✅ _FIND: Retornando instância singleton criada para tipo: $type', name: 'BIND_FIND');
                    return instance;
                  }
                }
              } else {
                iLog('⚠️ _FIND: Tipo real $realType não é compatível com $type', name: 'BIND_FIND');
              }
            } catch (e) {
              // Se falhar ao criar instância, continua procurando
              iLog('⚠️ _FIND: Erro ao criar instância de Object bind: $e', name: 'BIND_FIND');
            }
          }

          // Depois processa binds pendentes (que foram registrados como Object mas não estão no mapa)
          final pendingToRemove = <Bind>[];
          for (var pendingBind in _pendingObjectBinds) {
            try {
              final instance = pendingBind.factoryFunction(Injector());
              final realType = instance.runtimeType;

              iLog('🔍 _FIND: Tipo real descoberto de bind pendente: $realType, buscando $type', name: 'BIND_FIND');

              // Se o tipo real é compatível com T, registra e retorna
              if (instance is T) {
                _bindsMap[realType] = pendingBind;
                pendingToRemove.add(pendingBind);
                iLog('✅ _FIND: Tipo real descoberto de bind pendente: $realType, registrando', name: 'BIND_FIND');

                if (!pendingBind.isSingleton) {
                  final instance = pendingBind.factoryFunction(Injector()) as T;
                  _searchAttempts.remove(type);
                  DependencyAnalyzer.recordSearchAttempt(type, true);
                  DependencyAnalyzer.endSearch(type);
                  iLog('✅ _FIND: Retornando instância factory de bind pendente para tipo: $type', name: 'BIND_FIND');
                  return instance;
                } else {
                  // Para singleton, tentar acessar instance com proteção contra Stack Overflow
                  try {
                    final instance = pendingBind.instance as T;
                    _searchAttempts.remove(type);
                    DependencyAnalyzer.recordSearchAttempt(type, true);
                    DependencyAnalyzer.endSearch(type);
                    iLog('✅ _FIND: Retornando instância singleton de bind pendente para tipo: $type', name: 'BIND_FIND');
                    return instance;
                  } catch (e) {
                    // Se falhar ao acessar instance (possível Stack Overflow), tentar criar nova instância
                    iLog('⚠️ _FIND: Erro ao acessar instance singleton pendente, tentando criar nova: $e', name: 'BIND_FIND');
                    final instance = pendingBind.factoryFunction(Injector()) as T;
                    _searchAttempts.remove(type);
                    DependencyAnalyzer.recordSearchAttempt(type, true);
                    DependencyAnalyzer.endSearch(type);
                    iLog('✅ _FIND: Retornando instância singleton criada de bind pendente para tipo: $type', name: 'BIND_FIND');
                    return instance;
                  }
                }
              }
            } catch (e) {
              // Se falhar, mantém na lista pendente
              iLog('⚠️ _FIND: Erro ao criar instância de bind pendente: $e', name: 'BIND_FIND');
            }
          }

          // Remove binds que foram registrados com sucesso
          for (var bindToRemove in pendingToRemove) {
            _pendingObjectBinds.remove(bindToRemove);
          }

          // Depois verifica binds não-Object por compatibilidade
          for (var entry in _bindsMap.entries) {
            if (entry.key == Object) continue; // Já processamos acima

            // Verifica compatibilidade normal (para binds que não são Object)
            // Tenta criar instância para verificar compatibilidade
            if (entry.value.key == null) {
              try {
                final testInstance = entry.value.factoryFunction(Injector());
                if (testInstance is T) {
                  iLog('✅ _FIND: Bind compatível encontrado: ${entry.key} -> $type', name: 'BIND_FIND');
                  bind = Bind<T>((injector) => entry.value.factoryFunction(injector) as T, isSingleton: entry.value.isSingleton, isLazy: entry.value.isLazy, key: entry.value.key);
                  _bindsMap[type] = bind;

                  // Retorna a instância
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
              } catch (e) {
                // Se falhar ao criar instância, continua procurando
                iLog('⚠️ _FIND: Erro ao verificar compatibilidade: $e', name: 'BIND_FIND');
              }
            }
          }
        }
      }

      // Se chegou aqui e bind ainda é null, não encontrou
      if (bind == null) {
        iLog('❌ _FIND: Bind não encontrado para tipo: $type (tentativa $attemptCount/$maxAbsoluteAttempts)', name: 'BIND_FIND');

        // Limpar estado ANTES de lançar exceção para evitar loop infinito
        _searchAttempts.remove(type);
        _currentlySearching.remove(type);
        DependencyAnalyzer.recordSearchAttempt(type, false);
        DependencyAnalyzer.endSearch(type);

        // Se uma key específica foi solicitada e não foi encontrada, falha imediatamente
        if (key != null) {
          final errorMessage = '❌ Bind not found for type "${type.toString()}" with key: $key';
          throw GoRouterModularException(errorMessage);
        }

        // Log detalhado com informações sobre binds disponíveis (apenas na primeira tentativa para evitar spam)
        if (attemptCount == 1) {
          log('[GO_ROUTER_MODULAR] ❌ Bind not found for type: "${type.toString()}"');
          log('[GO_ROUTER_MODULAR] 📊 Available binds: ${_bindsMap.keys.map((k) => k.toString()).join(', ')}');
        }

        // Se não há binds pendentes e já tentamos algumas vezes, falha imediatamente
        if (_pendingObjectBinds.isEmpty && attemptCount >= 2) {
          log('[GO_ROUTER_MODULAR] ⚠️ Nenhum bind pendente encontrado após $attemptCount tentativas - falhando imediatamente');
          final errorMessage = '❌ Bind not found for type "${type.toString()}". No pending binds available after $attemptCount attempts.';
          throw GoRouterModularException(errorMessage);
        }

        final errorMessage = '❌ Bind not found for type "${type.toString()}"';
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
      // Garantir que o estado seja limpo mesmo se já foi limpo antes
      _searchAttempts.remove(type);
      DependencyAnalyzer.recordSearchAttempt(type, false);
      DependencyAnalyzer.endSearch(type);
      iLog('❌ _FIND: Erro ao buscar tipo $type: $e', name: 'BIND_FIND');
      rethrow;
    } finally {
      // Sempre garantir que o tipo seja removido do _currentlySearching
      _currentlySearching.remove(type);
      DependencyAnalyzer.endSearch(type);
      iLog('🧹 _FIND: Removendo tipo $type do _currentlySearching (finally)', name: 'BIND_FIND');
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

  /// Tenta obter uma instância sem lançar exceção se não encontrar
  /// Retorna null se o bind não estiver registrado
  static T? tryGet<T>({String? key}) {
    try {
      return get<T>(key: key);
    } catch (e) {
      return null;
    }
  }

  /// Verifica se um bind está registrado para o tipo especificado
  static bool isRegistered<T>({String? key}) {
    if (key != null) {
      return _bindsMapByKey.containsKey(key);
    }
    // Verifica se está diretamente no mapa (mais confiável)
    return _bindsMap.containsKey(T);
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
    // Limpa estado de busca PRIMEIRO para evitar modificações concorrentes
    _searchAttempts.clear();
    _currentlySearching.clear();
    DependencyAnalyzer.clearAll();

    // Faz cópia dos binds para evitar modificações durante iteração
    final bindsToClean = List<Bind>.from(_bindsMap.values);
    final bindsByKeyToClean = List<Bind>.from(_bindsMapByKey.values);

    // Limpa os maps ANTES de chamar CleanBind para evitar modificações concorrentes
    _bindsMap.clear();
    _bindsMapByKey.clear();
    _pendingObjectBinds.clear();

    // Chama CleanBind para todas as instâncias depois de limpar os maps
    for (var bind in bindsToClean) {
      try {
        CleanBind.fromInstance(bind.instance);
      } catch (_) {
        // Ignora erros ao limpar instâncias (pode ter sido disposto)
      }
    }

    for (var bind in bindsByKeyToClean) {
      try {
        CleanBind.fromInstance(bind.instance);
      } catch (_) {
        // Ignora erros ao limpar instâncias (pode ter sido disposto)
      }
    }
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
