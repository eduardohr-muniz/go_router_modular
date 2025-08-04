import 'package:go_router_modular/src/utils/exception.dart';
import 'package:go_router_modular/src/utils/injector.dart';

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

    // Registrar por tipo
    _bindsMap[type] = bind;

    // Registrar por key se fornecida
    if (bind.key != null) {
      _bindsMapByKey[bind.key!] = bind;
    }
  }

  static void dispose<T>() {
    if (T == Object) {
      return;
    }

    final removed = _bindsMap.remove(T);
    if (removed != null) {
      if (removed.key != null) {
        _bindsMapByKey.remove(removed.key);
      }
    }
  }

  static void disposeByKey(String key) {
    final bind = _bindsMapByKey.remove(key);
    if (bind != null) {
      _bindsMap.remove(bind.instance.runtimeType);
    }
  }

  static void disposeByType(Type type) {
    // Remove por tipo
    _bindsMap.remove(type);

    // Remove todas as keys associadas a este tipo
    final keysToRemove = <String>[];
    for (var entry in _bindsMapByKey.entries) {
      // Verifica se o tipo é compatível (pode ser o mesmo tipo ou um subtipo)
      final instance = entry.value.instance;

      // Verifica se é o mesmo tipo
      bool isCompatible = instance.runtimeType == type;

      if (isCompatible) {
        keysToRemove.add(entry.key);
      }
    }

    // Remove as keys marcadas
    for (var key in keysToRemove) {
      _bindsMapByKey.remove(key);
    }

    // Remove também os binds do mapa por tipo que são compatíveis com o tipo base
    final typesToRemove = <Type>[];
    for (var entry in _bindsMap.entries) {
      final instance = entry.value.instance;

      if (instance.runtimeType == type) {
        typesToRemove.add(entry.key);
      }
    }

    for (var typeToRemove in typesToRemove) {
      _bindsMap.remove(typeToRemove);
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
      throw GoRouterModularException('Circular dependency detected for type ${type.toString()}');
    }

    // Controle de tentativas para evitar loops infinitos
    _searchAttempts[type] = (_searchAttempts[type] ?? 0) + 1;
    final isLastAttempt = _searchAttempts[type]! >= _maxSearchAttempts;

    if (_searchAttempts[type]! > _maxSearchAttempts) {
      _searchAttempts.remove(type);
      throw GoRouterModularException('Too many search attempts for type ${type.toString()}. Possible infinite loop detected.');
    }

    _currentlySearching.add(type);

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
              return instance;
            } else {
              // Para singleton, usa a instância já criada
              final instance = bind.instance as T;
              _searchAttempts.remove(type);
              return instance;
            }
          } else {
            bind = null;
          }
        } else {
          // Se uma key foi fornecida mas não encontrada, falha imediatamente
          final errorMessage = 'Bind not found for type ${type.toString()} with key: $key';
          throw GoRouterModularException(errorMessage);
        }
      }

      // Se não encontrou por key ou não foi fornecida, busca por tipo
      if (bind == null) {
        bind = _bindsMap[type];
        if (bind != null) {
          // Para factory, executa a função a cada chamada
          if (!bind.isSingleton) {
            final instance = bind.factoryFunction(Injector()) as T;
            _searchAttempts.remove(type);
            return instance;
          } else {
            // Para singleton, usa a instância já criada
            final instance = bind.instance as T;
            _searchAttempts.remove(type);
            return instance;
          }
        } else {
          // Se não foi fornecida uma key, busca por um bind que não tenha key explícita
          for (var entry in _bindsMap.entries) {
            if (entry.value.instance is T && entry.value.key == null) {
              bind = Bind<T>((injector) => entry.value.instance as T, isSingleton: entry.value.isSingleton, isLazy: entry.value.isLazy, key: entry.value.key);
              _bindsMap[type] = bind;
              break;
            }
          }

          // Se ainda não encontrou e não foi especificada uma key, busca por qualquer bind compatível
          if (bind == null && key == null) {
            for (var entry in _bindsMap.entries) {
              if (entry.value.instance is T) {
                bind = Bind<T>((injector) => entry.value.instance as T, isSingleton: entry.value.isSingleton, isLazy: entry.value.isLazy, key: entry.value.key);
                _bindsMap[type] = bind;
                break;
              }
            }
          }
        }
      }

      if (bind == null) {
        // Se uma key específica foi solicitada e não foi encontrada, falha imediatamente
        if (key != null) {
          final errorMessage = 'Bind not found for type ${type.toString()} with key: $key';
          throw GoRouterModularException(errorMessage);
        }

        // Só loga erro detalhado se for a última tentativa ou se atingir limite
        if (isLastAttempt) {
          final errorMessage = 'Bind not found for type ${type.toString()}';
          throw GoRouterModularException(errorMessage);
        } else {
          // Para tentativas intermediárias, só log discreto
        }
      }

      final instance = bind?.instance as T;

      // Sucesso: limpar contador de tentativas
      _searchAttempts.remove(type);

      return instance;
    } finally {
      _currentlySearching.remove(type);
    }
  }

  static T get<T>({String? key}) {
    // Se não foi passada uma key, busca por tipo (sem key)
    if (key == null) {
      return _find<T>(key: null);
    }

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
    _bindsMap.clear();
    _bindsMapByKey.clear();
    _searchAttempts.clear();
    _currentlySearching.clear();
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
