import 'package:flutter/foundation.dart';
import 'package:go_router_modular/src/core/bind/bind.dart';
import 'package:go_router_modular/src/core/bind/bind_storage.dart';
import 'package:go_router_modular/src/core/bind/bind_search_protection.dart';
import 'package:go_router_modular/src/core/dependency_analyzer/dependency_analyzer.dart';
import 'package:go_router_modular/src/di/injector.dart';
import 'package:go_router_modular/src/exceptions/exception.dart';

/// Responsável APENAS por buscar e obter binds
/// Responsabilidade única: Localização e recuperação de binds
class BindLocator {
  final BindStorage _storage = BindStorage.instance;
  final BindSearchProtection _protection = BindSearchProtection.instance;

  T find<T>({String? key}) {
    final type = T;

    // Verifica limite ANTES de qualquer coisa para evitar loops infinitos
    final currentAttempts = _protection.searchAttempts[type] ?? 0;
    const maxAbsoluteAttempts = 3; // Limite rigoroso reduzido para 3

    if (currentAttempts >= maxAbsoluteAttempts) {
      // Limpa estado e lança exceção imediatamente SEM adicionar ao _currentlySearching
      _protection.searchAttempts.remove(type);
      _protection.currentlySearching.remove(type);
      DependencyAnalyzer.recordSearchAttempt(type, false);
      DependencyAnalyzer.endSearch(type);
      throw GoRouterModularException('❌ Too many search attempts ($currentAttempts) for type "${type.toString()}". Possible infinite loop detected. Please ensure the bind is registered before use.');
    }

    // Proteção contra múltiplas buscas simultâneas do mesmo tipo
    if (_protection.currentlySearching.contains(type)) {
      throw GoRouterModularException('❌ Type "${type.toString()}" is already being searched. Possible infinite loop detected. Please ensure the bind is registered before use.');
    }

    // Incrementa contador de tentativas ANTES de adicionar ao _currentlySearching
    _protection.searchAttempts[type] = currentAttempts + 1;
    final attemptCount = _protection.searchAttempts[type]!;

    // Adiciona ao _currentlySearching APENAS APÓS incrementar tentativas
    _protection.currentlySearching.add(type);
    DependencyAnalyzer.startSearch(type);

    try {
      Bind? bind;

      // Se uma key foi fornecida, busca primeiro por key
      if (key != null) {
        bind = _storage.bindsMapByKey[key];
        if (bind != null) {
          // Verifica se o bind encontrado é compatível com o tipo solicitado
          if (bind.instance is T) {
            // Para factory, executa a função a cada chamada
            if (!bind.isSingleton) {
              final instance = bind.factoryFunction(Injector()) as T;
              _protection.searchAttempts.remove(type);
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
              _protection.searchAttempts.remove(type);
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
          bind = _storage.bindsMap[type];
          // Verifica se o bind encontrado realmente não tem key
          if (bind != null && bind.key != null) {
            // Bind encontrado tem key, mas estamos buscando sem key
            // Não pode retornar este bind
            bind = null;
          }
        } else {
          // Se key não é null, busca normalmente (mas já foi feito acima)
          bind = _storage.bindsMap[type];
        }

        if (bind != null) {
          // Para factory, executa a função a cada chamada
          if (!bind.isSingleton) {
            final instance = bind.factoryFunction(Injector()) as T;
            _protection.searchAttempts.remove(type);
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
            _protection.searchAttempts.remove(type);
            return instance;
          }
        } else {
          // Se não foi fornecida uma key, busca por binds que possam ser compatíveis
          // Primeiro tenta criar instância de binds registrados como Object para descobrir tipo real
          final objectBinds = <MapEntry<Type, Bind>>[];
          for (var entry in _storage.bindsMap.entries) {
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
                  _storage.bindsMap.remove(Object);
                }
                // REGRA: Só registra no _bindsMap se não tem key
                if (testBind.key == null) {
                  _storage.bindsMap[realType] = testBind;
                } else {
                  // Bind com key: só registra no _bindsMapByKey
                  _storage.bindsMapByKey[testBind.key!] = testBind;
                }

                if (!testBind.isSingleton) {
                  final instance = testBind.factoryFunction(Injector()) as T;
                  _protection.searchAttempts.remove(type);
                  DependencyAnalyzer.recordSearchAttempt(type, true);
                  DependencyAnalyzer.endSearch(type);
                  return instance;
                } else {
                  // Para singleton, tentar acessar instance com proteção contra Stack Overflow
                  try {
                    final instance = testBind.instance as T;
                    _protection.searchAttempts.remove(type);
                    DependencyAnalyzer.recordSearchAttempt(type, true);
                    DependencyAnalyzer.endSearch(type);
                    return instance;
                  } catch (e) {
                    // Se falhar ao acessar instance (possível Stack Overflow), tentar criar nova instância
                    final instance = testBind.factoryFunction(Injector()) as T;
                    _protection.searchAttempts.remove(type);
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
          for (var pendingBind in _storage.pendingObjectBinds) {
            try {
              final instance = pendingBind.factoryFunction(Injector());
              final realType = instance.runtimeType;

              // Se o tipo real é compatível com T, registra e retorna
              if (instance is T) {
                // REGRA: Só registra no _bindsMap se não tem key
                if (pendingBind.key == null) {
                  _storage.bindsMap[realType] = pendingBind;
                } else {
                  // Bind com key: só registra no _bindsMapByKey
                  _storage.bindsMapByKey[pendingBind.key!] = pendingBind;
                }
                pendingToRemove.add(pendingBind);

                if (!pendingBind.isSingleton) {
                  final instance = pendingBind.factoryFunction(Injector()) as T;
                  _protection.searchAttempts.remove(type);
                  DependencyAnalyzer.recordSearchAttempt(type, true);
                  DependencyAnalyzer.endSearch(type);
                  return instance;
                } else {
                  // Para singleton, tentar acessar instance com proteção contra Stack Overflow
                  try {
                    final instance = pendingBind.instance as T;
                    _protection.searchAttempts.remove(type);
                    DependencyAnalyzer.recordSearchAttempt(type, true);
                    DependencyAnalyzer.endSearch(type);
                    return instance;
                  } catch (e) {
                    // Se falhar ao acessar instance (possível Stack Overflow), tentar criar nova instância
                    final instance = pendingBind.factoryFunction(Injector()) as T;
                    _protection.searchAttempts.remove(type);
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
            _storage.pendingObjectBinds.remove(bindToRemove);
          }

          // Depois verifica binds não-Object por compatibilidade
          for (var entry in _storage.bindsMap.entries) {
            if (entry.key == Object) continue; // Já processamos acima

            // Verifica compatibilidade normal (para binds que não são Object)
            // Tenta criar instância para verificar compatibilidade
            if (entry.value.key == null) {
              try {
                final testInstance = entry.value.factoryFunction(Injector());
                if (testInstance is T) {
                  bind = Bind<T>((injector) => entry.value.factoryFunction(injector) as T, isSingleton: entry.value.isSingleton, isLazy: entry.value.isLazy, key: entry.value.key);
                  _storage.bindsMap[type] = bind;

                  // Retorna a instância
                  if (!bind.isSingleton) {
                    final instance = bind.factoryFunction(Injector()) as T;
                    _protection.searchAttempts.remove(type);
                    DependencyAnalyzer.recordSearchAttempt(type, true);
                    DependencyAnalyzer.endSearch(type);
                    return instance;
                  } else {
                    final instance = bind.instance as T;
                    _protection.searchAttempts.remove(type);
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
        _protection.searchAttempts.remove(type);
        _protection.currentlySearching.remove(type);
        DependencyAnalyzer.recordSearchAttempt(type, false);
        DependencyAnalyzer.endSearch(type);

        // Se uma key específica foi solicitada e não foi encontrada, falha imediatamente
        if (key != null) {
          final errorMessage = '❌ Bind not found for type "${type.toString()}" with key: $key';
          throw GoRouterModularException(errorMessage);
        }

        // Se não há binds pendentes e já tentamos algumas vezes, falha imediatamente
        if (_storage.pendingObjectBinds.isEmpty && attemptCount >= 2) {
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
      _protection.searchAttempts.remove(type);
      DependencyAnalyzer.recordSearchAttempt(type, true);
      DependencyAnalyzer.endSearch(type);

      return instance;
    } catch (e) {
      // Garantir que o estado seja limpo mesmo se já foi limpo antes
      _protection.searchAttempts.remove(type);
      DependencyAnalyzer.recordSearchAttempt(type, false);
      DependencyAnalyzer.endSearch(type);
      rethrow;
    } finally {
      // Sempre garantir que o tipo seja removido do _currentlySearching
      _protection.currentlySearching.remove(type);
      DependencyAnalyzer.endSearch(type);
    }
  }

  T get<T>({String? key}) {
    // Se não foi passada uma key, busca por tipo (sem key)
    if (key == null) {
      final instance = find<T>(key: null);
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

    final instance = find<T>(key: key);
    return instance;
  }

  /// Tenta obter uma instância sem lançar exceção se não encontrar
  T? tryGet<T>({String? key}) {
    try {
      return get<T>(key: key);
    } catch (e) {
      return null;
    }
  }

  /// Verifica se um bind está registrado para o tipo especificado
  bool isRegistered<T>({String? key}) {
    if (key != null) {
      return _storage.bindsMapByKey.containsKey(key);
    }
    // Verifica se está diretamente no mapa (mais confiável)
    return _storage.bindsMap.containsKey(T);
  }
}
