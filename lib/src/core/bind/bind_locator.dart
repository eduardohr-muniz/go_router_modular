import 'package:flutter/foundation.dart';
import 'package:go_router_modular/src/core/bind/bind.dart';
import 'package:go_router_modular/src/core/bind/bind_search_protection.dart';
import 'package:go_router_modular/src/core/bind/bind_storage.dart';
import 'package:go_router_modular/src/di/injector.dart';
import 'package:go_router_modular/src/exceptions/exception.dart';

/// Coordinates bind lookup using multiple search strategies.
class BindLocator {
  static const int _maxAbsoluteAttempts = 3;

  final BindSearchProtection _protection = BindSearchProtection.instance;
  final BindStorage _storage = BindStorage.instance;

  // ==================== PUBLIC API ====================

  T get<T>({String? key}) {
    final instance = _find<T>(key: key);
    if (key == null) _validateChangeNotifier(instance);
    return instance;
  }

  T? tryGet<T>({String? key}) {
    try {
      return get<T>(key: key);
    } catch (_) {
      return null;
    }
  }

  bool isRegistered<T>({String? key}) {
    if (key != null) return _storage.bindsMapByKey.containsKey(key);
    return _storage.bindsMap.containsKey(T);
  }

  // ==================== SEARCH ORCHESTRATION ====================

  T _find<T>({String? key}) {
    final type = T;

    _validateCanStartSearch(type);
    _startSearchTracking(type);

    try {
      final instance = _locateBind<T>(type, key);
      _protection.searchAttempts.remove(type);
      return instance;
    } catch (e) {
      _protection.searchAttempts.remove(type);
      rethrow;
    } finally {
      _protection.currentlySearching.remove(type);
      if (_protection.searchStack.isNotEmpty && _protection.searchStack.last == type) {
        _protection.searchStack.removeLast();
      }
    }
  }

  T _locateBind<T>(Type type, String? key) {
    // Strategy 1: Search by key
    if (key != null) {
      final instance = _searchByKey<T>(type, key);
      if (instance != null) return instance;
    }

    // Strategy 2: Direct type search
    final bind = _searchByType<T>(type, key);
    if (bind != null) return _createInstance<T>(bind);

    // Strategy 3: Discover from Object binds
    final fromObject = _discoverFromObjectBinds<T>(type);
    if (fromObject != null) return _createInstance<T>(fromObject);

    // Strategy 4: Discover from pending binds
    final fromPending = _discoverFromPendingBinds<T>(type);
    if (fromPending != null) return _createInstance<T>(fromPending);

    // Strategy 5: Compatibility search
    final compatible = _searchCompatibleBind<T>(type);
    if (compatible != null) return _createInstance<T>(compatible);

    _throwNotFound(type, key);
  }

  // ==================== SEARCH VALIDATION ====================

  void _validateCanStartSearch(Type type) {
    final currentAttempts = _protection.searchAttempts[type] ?? 0;

    if (currentAttempts >= _maxAbsoluteAttempts) {
      _protection.searchAttempts.remove(type);
      _protection.currentlySearching.remove(type);
      throw GoRouterModularException(
        'Too many search attempts ($currentAttempts) for type "${type.toString()}". '
        'Possible infinite loop detected. Please ensure the bind is registered before use.',
      );
    }

    if (_protection.currentlySearching.contains(type)) {
      throw GoRouterModularException(
        'Type "${type.toString()}" is already being searched. '
        'Possible infinite loop detected. Please ensure the bind is registered before use.',
      );
    }
  }

  void _startSearchTracking(Type type) {
    final currentAttempts = _protection.searchAttempts[type] ?? 0;
    _protection.searchAttempts[type] = currentAttempts + 1;
    _protection.currentlySearching.add(type);
    _protection.searchStack.add(type);
  }

  // ==================== KEY SEARCH ====================

  T? _searchByKey<T>(Type type, String key) {
    final bind = _storage.bindsMapByKey[key];

    if (bind == null) {
      throw GoRouterModularException('Bind not found for type "${type.toString()}" with key: $key');
    }

    if (bind.instance is! T) return null;
    return _createInstance<T>(bind);
  }

  // ==================== TYPE SEARCH ====================

  Bind? _searchByType<T>(Type type, String? key) {
    if (key != null) return _storage.bindsMap[type];

    // When searching without key, skip binds that have a key
    final bind = _storage.bindsMap[type];
    if (bind != null && bind.key != null) return null;
    return bind;
  }

  // ==================== TYPE DISCOVERY ====================

  Bind? _discoverFromObjectBinds<T>(Type type) {
    final objectBinds = <MapEntry<Type, Bind>>[];
    for (var entry in _storage.bindsMap.entries) {
      if (entry.key == Object) objectBinds.add(entry);
    }

    for (var entry in objectBinds) {
      Bind testBind = entry.value;

      if (testBind is Bind<T> && testBind.type != Object) {
        final realType = testBind.type;
        _storage.bindsMap[realType] = testBind;
        if (objectBinds.length == 1) _storage.bindsMap.remove(Object);
        return testBind;
      }

      try {
        final instance = testBind.factoryFunction(Injector());
        if (instance is T) {
          if (objectBinds.length == 1) _storage.bindsMap.remove(Object);

          if (testBind.key != null) {
            _storage.bindsMapByKey[testBind.key!] = testBind;
          } else {
            _storage.bindsMap[instance.runtimeType] = testBind;
          }
          return testBind;
        }
      } catch (_) {}
    }

    return null;
  }

  Bind? _discoverFromPendingBinds<T>(Type type) {
    final pendingToRemove = <Bind>[];

    for (var pendingBind in _storage.pendingObjectBinds) {
      if (pendingBind is Bind<T> && pendingBind.type != Object) {
        final realType = pendingBind.type;
        _storage.bindsMap[realType] = pendingBind;
        pendingToRemove.add(pendingBind);

        for (var b in pendingToRemove) {
          _storage.pendingObjectBinds.remove(b);
        }
        return pendingBind;
      }

      try {
        final instance = pendingBind.factoryFunction(Injector());
        if (instance is T) {
          if (pendingBind.key != null) {
            _storage.bindsMapByKey[pendingBind.key!] = pendingBind;
          } else {
            _storage.bindsMap[instance.runtimeType] = pendingBind;
          }
          pendingToRemove.add(pendingBind);
          return pendingBind;
        }
      } catch (_) {}
    }

    for (var b in pendingToRemove) {
      _storage.pendingObjectBinds.remove(b);
    }

    return null;
  }

  // ==================== COMPATIBILITY SEARCH ====================

  Bind? _searchCompatibleBind<T>(Type type) {
    for (var entry in _storage.bindsMap.entries) {
      if (entry.key == Object) continue;
      if (entry.value.key != null) continue;

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
      } catch (_) {}
    }

    return null;
  }

  // ==================== HELPERS ====================

  T _createInstance<T>(Bind bind) {
    if (!bind.isSingleton) return bind.factoryFunction(Injector()) as T;

    try {
      return bind.instance as T;
    } catch (_) {
      return bind.factoryFunction(Injector()) as T;
    }
  }

  void _validateChangeNotifier(dynamic instance) {
    if (instance is! ChangeNotifier) return;
    try {
      final testListener = () {};
      instance.addListener(testListener);
      instance.removeListener(testListener);
    } catch (_) {}
  }

  Never _throwNotFound(Type type, String? key) {
    final stack = _protection.searchStack;
    String message = 'Bind not found for type "${type.toString()}"';

    if (key != null) message += ' with key: "$key"';

    if (stack.length > 1) {
      final requester = stack[stack.length - 2];
      message += '\n\nRequested by: "$requester"';
      final path = stack.map((t) => t.toString()).join(' -> ');
      message += '\nDependency chain: $path';
    }

    throw GoRouterModularException(message);
  }
}
