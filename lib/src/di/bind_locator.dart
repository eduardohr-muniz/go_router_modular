import 'package:flutter/foundation.dart';
import 'package:go_router_modular/src/di/bind.dart';
import 'package:go_router_modular/src/di/bind_search_protection.dart';
import 'package:go_router_modular/src/di/bind_storage.dart';
import 'package:go_router_modular/src/di/injector.dart';
import 'package:go_router_modular/src/shared/exception.dart';

/// Coordinates bind lookup using multiple search strategies.
class BindLocator {
  static const int _maxAbsoluteAttempts = 3;

  final BindSearchProtection _protection = BindSearchProtection.instance;
  final BindStorage _storage = BindStorage.instance;

  // ==================== PUBLIC API ====================

  T get<T>({String? key}) {
    // Fast path: no factory executing — re-entrancy and circular deps impossible.
    if (key == null && !_protection.hasBlockedBinds) {
      final bind = _storage.bindsMap[T];
      if (bind != null && bind.key == null && bind.isSingleton) {
        final cached = bind.cachedInstance;
        if (cached != null) {
          _validateChangeNotifier(cached);
          return cached as T;
        }
      }
      // Negative cache: T was already searched through all strategies and not
      // found. Skip tracking + strategy walk and go straight to the throw.
      if (bind == null && _storage.negativeLookupCache.contains(T)) {
        _throwNotFound(T, null);
      }
    }
    final instance = _find<T>(key: key);
    if (key == null) _validateChangeNotifier(instance);
    return instance;
  }

  T? tryGet<T>({String? key}) {
    // Fast path: return null without throwing when T is known-not-found.
    if (key == null && !_protection.hasBlockedBinds) {
      final bind = _storage.bindsMap[T];
      if (bind != null && bind.key == null && bind.isSingleton) {
        final cached = bind.cachedInstance;
        if (cached != null) {
          _validateChangeNotifier(cached);
          return cached as T;
        }
      }
      if (bind == null && _storage.negativeLookupCache.contains(T)) {
        return null;
      }
    }
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
      throw ModularException(
        'Too many search attempts ($currentAttempts) for type "${type.toString()}". '
        'Possible infinite loop detected. Please ensure the bind is registered before use.',
      );
    }

    if (_protection.currentlySearching.contains(type)) {
      // Bypass `currentlySearching` ONLY when the topmost in-flight factory
      // is producing this exact type. That covers the legitimate
      // self-reference `addFactory<I>((i) => i.get())`: the inferred
      // `i.get<I>()` re-enters here from inside the I-producing factory, and
      // we want compatibility search to find a different bind that produces I.
      //
      // Every other re-entry is a cross-type circular dependency (e.g.
      // `A` whose factory needs `B`, whose factory needs `A`) and must
      // surface as a clear error instead of being silently rerouted.
      if (_protection.isTopInvocationFor(type)) return;

      final chain = _protection.searchStack.map((t) => t.toString()).join(' -> ');
      throw ModularException(
        'Circular dependency detected while resolving type "${type.toString()}".\n'
        'Dependency chain: $chain -> ${type.toString()}\n'
        'Break the cycle by injecting an abstraction, using a lazy factory, '
        'or refactoring one of the participants to not depend on the other at construction time.',
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
      throw ModularException('Bind not found for type "${type.toString()}" with key: $key');
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

    // Skip a bind whose factory is currently on the invocation stack —
    // re-invoking it would loop (the recursive call originated from inside
    // its own factory).
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

      final matched = _probeAs<T>(testBind, (instance) {
        if (objectBinds.length == 1) _storage.bindsMap.remove(Object);
        if (testBind.key != null) {
          _storage.bindsMapByKey[testBind.key!] = testBind;
        } else {
          _storage.bindsMap[instance.runtimeType] = testBind;
        }
      });
      if (matched) return testBind;
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

      final matched = _probeAs<T>(pendingBind, (instance) {
        if (pendingBind.key != null) {
          _storage.bindsMapByKey[pendingBind.key!] = pendingBind;
        } else {
          _storage.bindsMap[instance.runtimeType] = pendingBind;
        }
        pendingToRemove.add(pendingBind);
      });
      if (matched) return pendingBind;
    }

    for (var b in pendingToRemove) {
      _storage.pendingObjectBinds.remove(b);
    }

    return null;
  }

  // ==================== COMPATIBILITY SEARCH ====================

  /// Last-resort: walks `bindsMap` looking for a bind whose declared type is
  /// a subtype of `T`. Uses Dart's reified generics (`<DeclaredType>[] is List<T>`)
  /// to check compatibility WITHOUT invoking the factory — avoiding phantom instances.
  /// On miss, records `T` in the negative cache so future lookups skip this walk.
  Bind? _searchCompatibleBind<T>(Type type) {
    // Iterate a snapshot — this method writes to `bindsMap`, so walking the
    // live entries view raises ConcurrentModificationError.
    final snapshot = List<MapEntry<Type, Bind>>.of(_storage.bindsMap.entries);

    for (final entry in snapshot) {
      if (entry.key == Object) continue;
      final candidate = entry.value;
      if (candidate.key != null) continue;
      if (_protection.isBlocked(candidate)) continue;

      if (!candidate.isCompatibleWith<T>()) continue;

      _storage.bindsMap[type] = candidate;
      return candidate;
    }

    // All strategies exhausted — cache this negative result so the next lookup
    // skips tracking + strategy walk entirely.
    _storage.negativeLookupCache.add(type);
    return null;
  }

  /// Probes an `Object`-typed bind (used by [_discoverFromObjectBinds] and
  /// [_discoverFromPendingBinds]). Unlike the compatibility search, these
  /// paths must invoke even factory bind factories — `Bind<Object>` has no
  /// declared type, so the only way to discover what it produces is to
  /// build an instance. On match, [onMatch] is run with the built instance.
  bool _probeAs<T>(Bind testBind, void Function(dynamic instance) onMatch) {
    return _withInvocation<bool>(testBind, T, () {
      try {
        final instance = testBind.factoryFunction(Injector());
        if (instance is T) {
          onMatch(instance);
          return true;
        }
      } catch (_) {}
      return false;
    });
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
  /// factory invocation producing T." A recursive `i.get<T>()` from inside
  /// the factory will skip this bind in [_searchByType] and
  /// [_searchCompatibleBind] and bypass the `currentlySearching` check via
  /// [BindSearchProtection.isTopInvocationFor]. Nested invocations push/pop
  /// their own entry so the guard handles arbitrary depth.
  T _invokeFactoryWithSelfRefGuard<T>(Bind bind, {bool cacheOnSingleton = false}) {
    return _withInvocation<T>(bind, T, () {
      final value = bind.factoryFunction(Injector()) as T;
      if (cacheOnSingleton && bind.isSingleton && bind.cachedInstance == null) {
        bind.cachedInstance = value;
      }
      return value;
    });
  }

  /// Runs [action] while [bind] is marked as invoking its factory for
  /// [requestedType]. Single place that pairs `pushInvocation` /
  /// `popInvocation` — every factory invocation in this file goes through
  /// here so the invocation stack stays balanced.
  R _withInvocation<R>(Bind bind, Type requestedType, R Function() action) {
    _protection.pushInvocation(bind, requestedType);
    try {
      return action();
    } finally {
      _protection.popInvocation(bind);
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

    throw ModularException(message);
  }
}
