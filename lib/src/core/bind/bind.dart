import 'package:flutter/foundation.dart';
import 'package:go_router_modular/src/di/clean_bind.dart';
import 'package:go_router_modular/src/exceptions/exception.dart';
import 'package:go_router_modular/src/di/injector.dart';
import 'package:go_router_modular/src/core/dependency_analyzer/dependency_analyzer.dart';

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

    // Verifica se a instância foi disposta (para ChangeNotifier e similares)
    if (_cachedInstance != null) {
      try {
        // Tenta verificar se é um ChangeNotifier disposto
        if (_cachedInstance is ChangeNotifier) {
          final notifier = _cachedInstance as ChangeNotifier;
          // Tenta usar um método que lança exceção se disposto
          // Apenas testa se o objeto ainda está válido sem acessar propriedades protegidas
          try {
            // Se conseguir adicionar um listener temporário (que será removido imediatamente),
            // o objeto ainda está válido. Se não conseguir, foi disposto.
            final testListener = () {};
            notifier.addListener(testListener);
            notifier.removeListener(testListener);
          } catch (e) {
            // Se lançar exceção, o objeto foi disposto - cria nova instância
            if (isSingleton) {
              _cachedInstance = factoryFunction(Injector());
            } else {
              final newInstance = factoryFunction(Injector());
              return newInstance;
            }
          }
        }
      } catch (e) {
        // Se falhar ao verificar, assume que está válido
      }
    }

    return _cachedInstance!;
  }

  /// Limpa a instância cacheada (usado quando o bind é disposto)
  void clearCache() {
    _cachedInstance = null;
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
      
      // Se for singleton, armazena a instância criada no cache
      // para evitar instâncias órfãs
      if (bind.isSingleton && bind._cachedInstance == null) {
        bind._cachedInstance = instance;
      } else if (!bind.isSingleton) {
        // Para factory, dispõe a instância temporária criada
        try {
          CleanBind.fromInstance(instance);
        } catch (_) {
          // Ignora erros ao dispor instância temporária
        }
      }
    } catch (e) {
      // Se falhar ao criar instância, registra como Object temporariamente
      // Mas adiciona à lista de pending para descoberta posterior
      registrationType = Object;
      _pendingObjectBinds.add(bind);
    }

    if (bind.isSingleton) {
      final singleton = _bindsMap[registrationType];
      if (singleton != null && singleton.key == bind.key) {
        return;
      }
    }

    // Verifica se já existe um bind deste tipo antes de substituir
    final existingBind = _bindsMap[registrationType];
    if (existingBind != null) {
      // REGRA: Bind com key só pode ser chamado com key
      // Bind sem key só pode ser chamado sem key
      // Se o bind existente tem key diferente do novo, não substitui
      // Se ambos têm key ou ambos não têm key, substitui
      if (existingBind.key != bind.key) {
        // Se um tem key e outro não, não substitui - mantém ambos
        // O bind com key fica apenas no _bindsMapByKey
        // O bind sem key fica no _bindsMap
        if (bind.key != null) {
          // Novo bind tem key, existente não tem - mantém existente no _bindsMap
          _bindsMapByKey[bind.key!] = bind;
          return;
        } else {
          // Novo bind não tem key, existente tem - REMOVE o existente do _bindsMap e coloca o sem key
          // Remove o bind com key do _bindsMap (mas mantém no _bindsMapByKey)
          _bindsMap.remove(registrationType);
          // Registra o bind sem key no _bindsMap
          _bindsMap[registrationType] = bind;
          return;
        }
      }

      // Se chegar aqui, ambos têm a mesma key (ou ambos não têm key)
      // Limpa o cache do bind antigo antes de substituir
      existingBind.clearCache();
    }

    // Só registra no _bindsMap se não tem key
    // Se tem key, será registrado apenas no _bindsMapByKey
    if (bind.key == null) {
      _bindsMap[registrationType] = bind;
    } else {
      // Bind com key: só registra no _bindsMapByKey, NÃO no _bindsMap
      // Isso garante que get<T>() sem key não pegue binds com key
      _bindsMapByKey[bind.key!] = bind;
    }
  }

  /// Versão genérica para compatibilidade (usa o tipo genérico se fornecido)
  static void registerTyped<T>(Bind<T> bind) {
    if (T != Object) {
      // Se T não é Object, usa T diretamente
      if (bind.isSingleton) {
        final singleton = _bindsMap[T];
        if (singleton != null && singleton.key == bind.key) {
          return;
        }
      }

      // Verifica se já existe um bind deste tipo
      final existingBind = _bindsMap[T];
      if (existingBind != null) {
        // REGRA: Bind com key só pode ser chamado com key
        // Bind sem key só pode ser chamado sem key
        if (existingBind.key != bind.key) {
          if (bind.key != null) {
            // Novo bind tem key, existente não tem - mantém existente no _bindsMap
            _bindsMapByKey[bind.key!] = bind;
            return;
          } else {
            // Novo bind não tem key, existente tem - REMOVE o existente do _bindsMap
            _bindsMap.remove(T);
            _bindsMap[T] = bind;
            return;
          }
        }
      }

      // Só registra no _bindsMap se não tem key
      if (bind.key == null) {
        _bindsMap[T] = bind;
      } else {
        // Bind com key: só registra no _bindsMapByKey, NÃO no _bindsMap
        _bindsMapByKey[bind.key!] = bind;
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

    final bind = _bindsMap[T];
    if (bind != null) {
      try {
        // Só dispõe se houver instância cacheada
        // Não cria nova instância durante dispose
        if (bind._cachedInstance != null) {
          CleanBind.fromInstance(bind._cachedInstance!);
        }
      } catch (e) {
        // Ignora erros ao acessar/dispor instance
      }

      // Limpa o cache para evitar retornar instância disposta
      bind.clearCache();

      // Remove do _bindsMap
      _bindsMap.remove(T);

      // Remove do _bindsMapByKey se tiver key
      if (bind.key != null) {
        _bindsMapByKey.remove(bind.key);
      }
    }

    // Também procura no _bindsMapByKey por binds deste tipo
    final keysToRemove = <String>[];
    for (var entry in _bindsMapByKey.entries) {
      try {
        if (entry.value._cachedInstance is T) {
          keysToRemove.add(entry.key);
          if (entry.value._cachedInstance != null) {
            CleanBind.fromInstance(entry.value._cachedInstance!);
          }
          entry.value.clearCache();
        }
      } catch (_) {
        // Ignora erros
      }
    }

    for (var key in keysToRemove) {
      _bindsMapByKey.remove(key);
    }

    // Limpar estado de busca
    _currentlySearching.remove(T);
    _searchAttempts.remove(T);
    DependencyAnalyzer.clearTypeHistory(T);
  }

  static void disposeByKey(String key) {
    final bind = _bindsMapByKey[key];
    if (bind != null) {
      // Só dispõe se houver instância cacheada
      if (bind._cachedInstance != null) {
        CleanBind.fromInstance(bind._cachedInstance!);
        
        // Obtém o tipo do cache para não criar nova instância
        final type = bind._cachedInstance!.runtimeType;
        _bindsMap.remove(type);
        
        // Limpar estado de busca
        _currentlySearching.remove(type);
        _searchAttempts.remove(type);
        DependencyAnalyzer.clearTypeHistory(type);
      }
      
      bind.clearCache();
    }

    _bindsMapByKey.remove(key);
  }

  static void disposeByType(Type type) {
    // Remove por tipo - chama CleanBind para a instância principal
    final bind = _bindsMap[type];
    if (bind != null) {
      try {
        // Só dispõe se houver instância cacheada
        if (bind._cachedInstance != null) {
          CleanBind.fromInstance(bind._cachedInstance!);
        }
      } catch (e) {
        // Ignora erros ao acessar/dispor instance
      }

      // Limpa o cache para evitar retornar instância disposta
      bind.clearCache();
    }

    _bindsMap.remove(type);

    // Remove todas as keys associadas a este tipo
    final keysToRemove = <String>[];
    for (var entry in _bindsMapByKey.entries) {
      // Verifica se o tipo é compatível (pode ser o mesmo tipo ou um subtipo)
      final bindValue = entry.value;
      try {
        // Só verifica se houver instância cacheada
        if (bindValue._cachedInstance != null) {
          // Verifica se é o mesmo tipo
          bool isCompatible = bindValue._cachedInstance!.runtimeType == type;

          if (isCompatible) {
            keysToRemove.add(entry.key);
            // Chama CleanBind para cada instância que será removida
            CleanBind.fromInstance(bindValue._cachedInstance!);
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
      _bindsMapByKey.remove(key);
    }

    // Remove também os binds do mapa por tipo que são compatíveis com o tipo base
    final typesToRemove = <Type>[];
    for (var entry in _bindsMap.entries) {
      try {
        final bindValue = entry.value;
        // Só verifica se houver instância cacheada
        if (bindValue._cachedInstance != null) {
          if (bindValue._cachedInstance!.runtimeType == type) {
            typesToRemove.add(entry.key);
            // Chama CleanBind para cada instância que será removida
            CleanBind.fromInstance(bindValue._cachedInstance!);
            // Limpa o cache para evitar retornar instância disposta
            bindValue.clearCache();
          }
        }
      } catch (_) {
        // Se falhar ao acessar instance, continua
      }
    }

    for (var typeToRemove in typesToRemove) {
      _bindsMap.remove(typeToRemove);
    }

    // Limpar estado de busca
    _currentlySearching.remove(type);
    _searchAttempts.remove(type);
    DependencyAnalyzer.clearTypeHistory(type);

    // Limpar também os tipos relacionados que foram removidos
    for (var typeToRemove in typesToRemove) {
      _currentlySearching.remove(typeToRemove);
      _searchAttempts.remove(typeToRemove);
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
  }

  static T _find<T>({String? key}) {
    final type = T;

    // Verifica limite ANTES de qualquer coisa para evitar loops infinitos
    final currentAttempts = _searchAttempts[type] ?? 0;
    const maxAbsoluteAttempts = 3; // Limite rigoroso reduzido para 3

    if (currentAttempts >= maxAbsoluteAttempts) {
      // Limpa estado e lança exceção imediatamente SEM adicionar ao _currentlySearching
      _searchAttempts.remove(type);
      _currentlySearching.remove(type);
      DependencyAnalyzer.recordSearchAttempt(type, false);
      DependencyAnalyzer.endSearch(type);
      throw GoRouterModularException('❌ Too many search attempts ($currentAttempts) for type "${type.toString()}". Possible infinite loop detected. Please ensure the bind is registered before use.');
    }

    // Proteção contra múltiplas buscas simultâneas do mesmo tipo
    if (_currentlySearching.contains(type)) {
      throw GoRouterModularException('❌ Type "${type.toString()}" is already being searched. Possible infinite loop detected. Please ensure the bind is registered before use.');
    }

    // Incrementa contador de tentativas ANTES de adicionar ao _currentlySearching
    _searchAttempts[type] = currentAttempts + 1;
    final attemptCount = _searchAttempts[type]!;

    // Adiciona ao _currentlySearching APENAS APÓS incrementar tentativas
    _currentlySearching.add(type);
    DependencyAnalyzer.startSearch(type);

    try {
      Bind? bind;

      // Se uma key foi fornecida, busca primeiro por key
      if (key != null) {
        bind = _bindsMapByKey[key];
        if (bind != null) {
          // Verifica se o bind encontrado é compatível com o tipo solicitado
          if (bind.instance is T) {
            // Para factory, executa a função a cada chamada
            if (!bind.isSingleton) {
              final instance = bind.factoryFunction(Injector()) as T;
              _searchAttempts.remove(type);
              DependencyAnalyzer.recordSearchAttempt(type, true);
              DependencyAnalyzer.endSearch(type);
              return instance;
            } else {
              // Para singleton, usa a instância já criada
              final instance = bind.instance as T;
              if (instance is ChangeNotifier) {
                try {
                  final testListener = () {};
                  instance.addListener(testListener);
                  instance.removeListener(testListener);
                } catch (e) {
                  // ChangeNotifier disposto
                }
              }
              _searchAttempts.remove(type);
              DependencyAnalyzer.recordSearchAttempt(type, true);
              DependencyAnalyzer.endSearch(type);
              return instance;
            }
          } else {
            bind = null;
          }
        } else {
          // Se uma key foi fornecida mas não encontrada, falha imediatamente
          final errorMessage = '❌ Bind not found for type "${type.toString()}" with key: $key';
          throw GoRouterModularException(errorMessage);
        }
      }

      // Se não encontrou por key ou não foi fornecida, busca por tipo
      if (bind == null) {
        // REGRA: Se key é null, busca apenas binds que não têm key
        // Isso garante que get<T>() sem key não pegue binds com key
        if (key == null) {
          bind = _bindsMap[type];
          // Verifica se o bind encontrado realmente não tem key
          if (bind != null && bind.key != null) {
            // Bind encontrado tem key, mas estamos buscando sem key
            // Não pode retornar este bind
            bind = null;
          }
        } else {
          // Se key não é null, busca normalmente (mas já foi feito acima)
          bind = _bindsMap[type];
        }

        if (bind != null) {
          // Para factory, executa a função a cada chamada
          if (!bind.isSingleton) {
            final instance = bind.factoryFunction(Injector()) as T;
            _searchAttempts.remove(type);
            return instance;
          } else {
            // Para singleton, usa a instância já criada
            final instance = bind.instance as T;
            if (instance is ChangeNotifier) {
              try {
                final testListener = () {};
                instance.addListener(testListener);
                instance.removeListener(testListener);
              } catch (e) {
                // ChangeNotifier disposto
              }
            }
            _searchAttempts.remove(type);
            return instance;
          }
        } else {
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

              // Se o tipo real é compatível com T, atualiza o registro e retorna
              if (instance is T) {
                // Remove Object e adiciona com tipo real
                if (objectBinds.length == 1) {
                  _bindsMap.remove(Object);
                }
                // REGRA: Só registra no _bindsMap se não tem key
                if (testBind.key == null) {
                  _bindsMap[realType] = testBind;
                } else {
                  // Bind com key: só registra no _bindsMapByKey
                  _bindsMapByKey[testBind.key!] = testBind;
                }

                if (!testBind.isSingleton) {
                  final instance = testBind.factoryFunction(Injector()) as T;
                  _searchAttempts.remove(type);
                  DependencyAnalyzer.recordSearchAttempt(type, true);
                  DependencyAnalyzer.endSearch(type);
                  return instance;
                } else {
                  // Para singleton, tentar acessar instance com proteção contra Stack Overflow
                  try {
                    final instance = testBind.instance as T;
                    _searchAttempts.remove(type);
                    DependencyAnalyzer.recordSearchAttempt(type, true);
                    DependencyAnalyzer.endSearch(type);
                    return instance;
                  } catch (e) {
                    // Se falhar ao acessar instance (possível Stack Overflow), tentar criar nova instância
                    final instance = testBind.factoryFunction(Injector()) as T;
                    _searchAttempts.remove(type);
                    DependencyAnalyzer.recordSearchAttempt(type, true);
                    DependencyAnalyzer.endSearch(type);
                    return instance;
                  }
                }
              }
            } catch (e) {
              // Se falhar ao criar instância, continua procurando
            }
          }

          // Depois processa binds pendentes (que foram registrados como Object mas não estão no mapa)
          final pendingToRemove = <Bind>[];
          for (var pendingBind in _pendingObjectBinds) {
            try {
              final instance = pendingBind.factoryFunction(Injector());
              final realType = instance.runtimeType;

              // Se o tipo real é compatível com T, registra e retorna
              if (instance is T) {
                // REGRA: Só registra no _bindsMap se não tem key
                if (pendingBind.key == null) {
                  _bindsMap[realType] = pendingBind;
                } else {
                  // Bind com key: só registra no _bindsMapByKey
                  _bindsMapByKey[pendingBind.key!] = pendingBind;
                }
                pendingToRemove.add(pendingBind);

                if (!pendingBind.isSingleton) {
                  final instance = pendingBind.factoryFunction(Injector()) as T;
                  _searchAttempts.remove(type);
                  DependencyAnalyzer.recordSearchAttempt(type, true);
                  DependencyAnalyzer.endSearch(type);
                  return instance;
                } else {
                  // Para singleton, tentar acessar instance com proteção contra Stack Overflow
                  try {
                    final instance = pendingBind.instance as T;
                    _searchAttempts.remove(type);
                    DependencyAnalyzer.recordSearchAttempt(type, true);
                    DependencyAnalyzer.endSearch(type);
                    return instance;
                  } catch (e) {
                    // Se falhar ao acessar instance (possível Stack Overflow), tentar criar nova instância
                    final instance = pendingBind.factoryFunction(Injector()) as T;
                    _searchAttempts.remove(type);
                    DependencyAnalyzer.recordSearchAttempt(type, true);
                    DependencyAnalyzer.endSearch(type);
                    return instance;
                  }
                }
              }
            } catch (e) {
              // Se falhar, mantém na lista pendente
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
                  bind = Bind<T>((injector) => entry.value.factoryFunction(injector) as T, isSingleton: entry.value.isSingleton, isLazy: entry.value.isLazy, key: entry.value.key);
                  _bindsMap[type] = bind;

                  // Retorna a instância
                  if (!bind.isSingleton) {
                    final instance = bind.factoryFunction(Injector()) as T;
                    _searchAttempts.remove(type);
                    DependencyAnalyzer.recordSearchAttempt(type, true);
                    DependencyAnalyzer.endSearch(type);
                    return instance;
                  } else {
                    final instance = bind.instance as T;
                    _searchAttempts.remove(type);
                    DependencyAnalyzer.recordSearchAttempt(type, true);
                    DependencyAnalyzer.endSearch(type);
                    return instance;
                  }
                }
              } catch (e) {
                // Se falhar ao criar instância, continua procurando
              }
            }
          }
        }
      }

      // Se chegou aqui e bind ainda é null, não encontrou
      if (bind == null) {
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

        // Se não há binds pendentes e já tentamos algumas vezes, falha imediatamente
        if (_pendingObjectBinds.isEmpty && attemptCount >= 2) {
          final errorMessage = '❌ Bind not found for type "${type.toString()}". No pending binds available after $attemptCount attempts.';
          throw GoRouterModularException(errorMessage);
        }

        final errorMessage = '❌ Bind not found for type "${type.toString()}"';
        throw GoRouterModularException(errorMessage);
      }

      // Se chegou aqui, bind não é null
      final instance = bind.instance as T;

      if (instance is ChangeNotifier) {
        try {
          final testListener = () {};
          instance.addListener(testListener);
          instance.removeListener(testListener);
        } catch (e) {
          // ChangeNotifier disposto
        }
      }

      // Sucesso: limpar contador de tentativas
      _searchAttempts.remove(type);
      DependencyAnalyzer.recordSearchAttempt(type, true);
      DependencyAnalyzer.endSearch(type);

      return instance;
    } catch (e) {
      // Garantir que o estado seja limpo mesmo se já foi limpo antes
      _searchAttempts.remove(type);
      DependencyAnalyzer.recordSearchAttempt(type, false);
      DependencyAnalyzer.endSearch(type);
      rethrow;
    } finally {
      // Sempre garantir que o tipo seja removido do _currentlySearching
      _currentlySearching.remove(type);
      DependencyAnalyzer.endSearch(type);
    }
  }

  static T get<T>({String? key}) {
    // Se não foi passada uma key, busca por tipo (sem key)
    if (key == null) {
      final instance = _find<T>(key: null);
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

    final instance = _find<T>(key: key);
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
        // Só dispõe se houver instância cacheada
        if (bind._cachedInstance != null) {
          CleanBind.fromInstance(bind._cachedInstance!);
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
        if (bind._cachedInstance != null) {
          CleanBind.fromInstance(bind._cachedInstance!);
        }
        // Limpa o cache para evitar retornar instância disposta
        bind.clearCache();
      } catch (_) {
        // Ignora erros ao limpar instâncias (pode ter sido disposto)
      }
    }
  }

  static Bind<T> singleton<T>(T Function(Injector i) builder, {String? key}) {
    final bind = Bind<T>(builder, isSingleton: true, isLazy: false, key: key);
    return bind;
  }

  static Bind<T> lazySingleton<T>(T Function(Injector i) builder, {String? key}) {
    final bind = Bind<T>(builder, isSingleton: true, isLazy: true, key: key);
    return bind;
  }

  @Deprecated('Use Bind.add instead')
  static Bind<T> factory<T>(T Function(Injector i) builder, {String? key}) {
    final bind = Bind<T>(builder, isSingleton: false, isLazy: false, key: key);
    return bind;
  }

  static Bind<T> add<T>(T Function(Injector i) builder, {String? key}) {
    final bind = Bind<T>(builder, isSingleton: false, isLazy: false, key: key);
    return bind;
  }
}
