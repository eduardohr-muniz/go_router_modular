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
      // Re-entry from a factory that self-references its own type
      // (`addFactory<I>((i) => i.get())`). The recursive lookup will skip
      // any bind currently inside a factory invocation and fall through
      // to compatibility search to find a different bind that produces `T`.
      if (_protection.hasBlockedBinds) return;

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
    if (bind == null) return null;
    if (bind.key != null) return null;

    // Skip a bind that is currently inside its own factory invocation
    // (self-referential `addFactory<I>((i) => i.get())`). The caller must
    // continue searching for a different bind that produces `T`.
    if (_protection.isBlocked(bind)) return null;

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

      _protection.blockBind(testBind);
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
      } catch (_) {
      } finally {
        _protection.unblockBind(testBind);
      }
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

      _protection.blockBind(pendingBind);
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
      } catch (_) {
      } finally {
        _protection.unblockBind(pendingBind);
      }
    }

    for (var b in pendingToRemove) {
      _storage.pendingObjectBinds.remove(b);
    }

    return null;
  }

  // ==================== COMPATIBILITY SEARCH ====================

  /// Last-resort: walks `bindsMap` looking for a bind whose instance satisfies
  /// `T` (e.g. a concrete singleton registered under the implementation type
  /// while the caller asked for the interface).
  ///
  /// Singletons reuse their **cached** instance via `bind.instance` to avoid
  /// silently breaking singleton identity (every call would otherwise build a
  /// fresh instance through `factoryFunction`). For factory binds, a typed
  /// delegate is created since each call must build a new instance anyway.
  Bind? _searchCompatibleBind<T>(Type type) {
    // Iterate a snapshot — this method writes to `bindsMap` (and the factory
    // probes can recursively trigger the registry to mutate it as well), so
    // walking the live entries view raises ConcurrentModificationError.
    final snapshot = List<MapEntry<Type, Bind>>.of(_storage.bindsMap.entries);

    for (final entry in snapshot) {
      if (entry.key == Object) continue;
      final candidate = entry.value;
      if (candidate.key != null) continue;

      // Skip a self-referential bind currently inside its own factory.
      // Probing it would re-invoke the same factory and loop.
      if (_protection.isBlocked(candidate)) continue;

      if (!_candidateProducesT<T>(candidate)) continue;

      if (candidate.isSingleton) {
        _storage.bindsMap[type] = candidate;
        return candidate;
      }

      final delegate = Bind<T>(
        (injector) => candidate.factoryFunction(injector) as T,
        isSingleton: false,
        isLazy: candidate.isLazy,
        key: candidate.key,
      );
      _storage.bindsMap[type] = delegate;
      return delegate;
    }

    return null;
  }

  bool _candidateProducesT<T>(Bind candidate) {
    final cached = candidate.cachedInstance;
    if (cached is T) return true;
    if (cached != null) return false;

    // Block candidate during the factory probe: a recursive `i.get<T>()`
    // from inside this factory must skip *this* bind in both `_searchByType`
    // and `_searchCompatibleBind` — otherwise compatibility search would
    // re-probe the same candidate, re-invoke its factory, and loop. Each
    // re-invocation also re-runs the candidate's side effects (stream
    // subscriptions, event listeners), which is visible as a UI freeze.
    _protection.blockBind(candidate);
    try {
      return candidate.factoryFunction(Injector()) is T;
    } catch (_) {
      return false;
    } finally {
      _protection.unblockBind(candidate);
    }
  }

  // ==================== HELPERS ====================

  T _createInstance<T>(Bind bind) {
    if (!bind.isSingleton) return _invokeFactoryWithSelfRefGuard<T>(bind);

    // Singleton with a cached instance is a pure value lookup — no factory
    // call, no risk of self-reference, so the guard is unnecessary.
    if (bind.cachedInstance != null) {
      try {
        return bind.instance as T;
      } catch (_) {}
    }
    return _invokeFactoryWithSelfRefGuard<T>(bind, cacheOnSingleton: true);
  }

  /// Invokes [bind]'s factory while marking it as "currently inside a
  /// factory invocation." A recursive `i.get<T>()` from inside the factory
  /// will skip this bind (see [_searchByType] / [_searchCompatibleBind])
  /// and fall through to compatibility search. Nested invocations
  /// push/pop their own bind, so the guard handles arbitrary depth.
  T _invokeFactoryWithSelfRefGuard<T>(Bind bind, {bool cacheOnSingleton = false}) {
    _protection.blockBind(bind);
    try {
      final value = bind.factoryFunction(Injector()) as T;
      if (cacheOnSingleton && bind.isSingleton && bind.cachedInstance == null) {
        bind.cachedInstance = value;
      }
      return value;
    } finally {
      _protection.unblockBind(bind);
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
