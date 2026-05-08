import 'package:go_router_modular/src/core/bind/bind.dart';
import 'package:go_router_modular/src/core/bind/bind_storage.dart';
import 'package:go_router_modular/src/di/clean_bind.dart';
import 'package:go_router_modular/src/di/injector.dart';

/// Handles bind registration logic.
class BindRegistry {
  final BindStorage _storage = BindStorage.instance;

  /// Binds queued by [registerBatch] awaiting [commitBatch].
  ///
  /// Holding a per-batch list lets [commitBatch] propagate the canonical
  /// `cachedInstance` to duplicate `Bind` objects (created when imports re-run
  /// `module.binds`) without re-invoking factories.
  final List<Bind<Object>> _pendingBatch = [];

  bool _isSingletonAlreadyRegistered(Type type, Bind bind) {
    if (!bind.isSingleton) return false;
    final existing = _storage.bindsMap[type];
    return existing != null && existing.key == bind.key;
  }

  /// Handles existing bind with different keys. Returns true if handled.
  bool _handleExistingBind(Type type, Bind bind) {
    final existingBind = _storage.bindsMap[type];
    if (existingBind == null) return false;

    if (existingBind.key == bind.key) {
      existingBind.clearCache();
      return false;
    }

    if (bind.key != null) {
      _storage.bindsMapByKey[bind.key!] = bind;
      return true;
    }

    _storage.bindsMap.remove(type);
    _storage.bindsMap[type] = bind;
    return true;
  }

  void _registerInStorage(Type type, Bind bind) {
    if (bind.key != null) {
      _storage.bindsMapByKey[bind.key!] = bind;
      return;
    }
    _storage.bindsMap[type] = bind;
  }

  /// Registers [bind] under its declared generic type ([Bind.type]) when not [Object].
  ///
  /// Alias binds (e.g. `Bind<IAddressAutocompleteDatasource>` returning `ApiSearchAddressDatasource`)
  /// must stay keyed by the interface so `Injector.get<I>()` resolves without relying on
  /// compatibility search (which can fail when the factory delegates to `get<Impl>()`).
  void _registerDeclaredType(Bind bind) {
    final declared = bind.type;
    if (declared == Object) return;

    final existingDeclared = _storage.bindsMap[declared];
    if (identical(existingDeclared, bind)) return;

    if (_handleExistingBind(declared, bind)) return;

    final stillExisting = _storage.bindsMap[declared];
    if (stillExisting != null && !identical(stillExisting, bind)) return;

    _registerInStorage(declared, bind);
  }

  /// Registers under [discoveredType] unless another bind already owns that implementation key.
  ///
  /// Avoids replacing a concrete singleton (e.g. `ApiSearchAddressDatasource`) with an alias
  /// factory registered only for an interface type.
  void _registerDiscoveredType(Type discoveredType, Bind bind) {
    final existing = _storage.bindsMap[discoveredType];
    if (identical(existing, bind)) return;
    if (existing != null && !identical(existing, bind)) return;

    if (_handleExistingBind(discoveredType, bind)) return;

    _registerInStorage(discoveredType, bind);
  }

  /// Caches singleton instances; disposes factory temp instances.
  void _processInstance(Bind bind, dynamic instance) {
    if (bind.isSingleton && bind.cachedInstance == null) {
      bind.cachedInstance = instance;
      return;
    }

    if (!bind.isSingleton) {
      try {
        CleanBind.fromInstance(instance);
      } catch (_) {}
    }
  }

  /// Registers a bind, discovering the real type immediately if possible.
  void register(dynamic bind) {
    if (bind is! Bind) {
      throw ArgumentError('Bind.register expects a Bind, but received ${bind.runtimeType}');
    }

    Type registrationType = bind.type;

    try {
      final instance = bind.factoryFunction(Injector());
      registrationType = instance.runtimeType;
      _processInstance(bind, instance);
    } catch (_) {
      if (registrationType == Object) {
        _storage.pendingObjectBinds.add(bind);
      }
    }

    if (_isSingletonAlreadyRegistered(registrationType, bind)) return;
    if (_handleExistingBind(registrationType, bind)) return;

    _registerDeclaredType(bind);
    _registerDiscoveredType(registrationType, bind);
  }

  /// Registers multiple binds, indexing them by their declared type up front.
  ///
  /// `Bind<T>` already carries `T` at compile time (`bind.type`), so we can
  /// populate `bindsMap` immediately. Factories are NOT invoked here — that is
  /// [commitBatch]'s job. Pre-indexing means cross-references inside the batch
  /// (e.g. `i.get<Dep>()` from another factory) resolve regardless of
  /// declaration order.
  ///
  /// Object-typed binds (no static type information) fall back to the legacy
  /// deferred-discovery path via [BindStorage.pendingObjectBinds].
  void registerBatch(List<Bind<Object>> binds) {
    for (final bind in binds) {
      _pendingBatch.add(bind);

      if (bind.key != null) {
        _storage.bindsMapByKey[bind.key!] = bind;
      }

      final declared = bind.type;
      if (declared == Object) {
        _storage.pendingObjectBinds.add(bind);
        continue;
      }

      _indexCanonicalOrPropagate(declared, bind);
    }
  }

  /// Materializes singletons registered in the current batch.
  ///
  /// Two passes:
  ///   1. Instantiate canonical eager singletons (no ordering concerns: every
  ///      typed bind is already in `bindsMap`, so `i.get<T>()` resolves via
  ///      lazy `bind.instance`).
  ///   2. Propagate `cachedInstance` to duplicate binds (same type, different
  ///      `Bind` object — created when imports re-run `module.binds`). Avoids
  ///      redundant factory calls in downstream introspection.
  ///
  /// Object-typed binds are resolved via the legacy deferred path.
  void commitBatch(Injector injector) {
    final batch = List<Bind<Object>>.from(_pendingBatch);
    _pendingBatch.clear();

    _instantiateCanonicalSingletons(batch, injector);
    _propagateCacheToDuplicates(batch);
    _commitObjectBinds(injector);
  }

  /// Pre-indexes a typed [bind] under [declared].
  ///
  /// First registration wins; subsequent duplicates only inherit cache (when
  /// available) and otherwise sit in [_pendingBatch] for phase 2 propagation.
  /// A duplicate carrying a distinct [Bind.key] gets its own slot in
  /// [BindStorage.bindsMapByKey] but does not displace the canonical type slot.
  void _indexCanonicalOrPropagate(Type declared, Bind bind) {
    final existing = _storage.bindsMap[declared];
    if (existing == null) {
      _storage.bindsMap[declared] = bind;
      return;
    }

    if (existing.key == bind.key) {
      if (existing.isSingleton && existing.cachedInstance != null) {
        bind.cachedInstance ??= existing.cachedInstance;
      }
      return;
    }
  }

  void _instantiateCanonicalSingletons(List<Bind<Object>> batch, Injector injector) {
    for (final bind in batch) {
      if (bind.type == Object) continue;
      if (!bind.isSingleton || bind.isLazy) continue;
      if (bind.cachedInstance != null) continue;

      final canonical = _storage.bindsMap[bind.type];
      if (canonical == null || !identical(canonical, bind)) continue;

      try {
        final instance = bind.factoryFunction(injector);
        bind.cachedInstance = instance;

        final discovered = instance.runtimeType;
        if (discovered != bind.type && discovered != Object) {
          _storage.bindsMap.putIfAbsent(discovered, () => bind);
        }
      } catch (_) {
        // Resolution will retry lazily via i.get<T>() (cachedInstance still null).
      }
    }
  }

  void _propagateCacheToDuplicates(List<Bind<Object>> batch) {
    for (final bind in batch) {
      if (bind.type == Object) continue;
      if (bind.cachedInstance != null) continue;

      final canonical = _storage.bindsMap[bind.type];
      if (canonical == null || identical(canonical, bind)) continue;
      if (canonical.cachedInstance == null) continue;

      bind.cachedInstance = canonical.cachedInstance;
    }
  }

  void _commitObjectBinds(Injector injector) {
    if (_storage.pendingObjectBinds.isEmpty) return;

    final pending = List<Bind<Object>>.from(_storage.pendingObjectBinds);
    _storage.pendingObjectBinds.clear();

    for (final bind in pending) {
      try {
        final instance = bind.factoryFunction(injector);
        final discovered = instance.runtimeType;

        if (discovered == Object) {
          _storage.pendingObjectBinds.add(bind);
          continue;
        }

        if (_isSingletonAlreadyRegistered(discovered, bind)) {
          bind.cachedInstance ??= _storage.bindsMap[discovered]?.cachedInstance;
          continue;
        }

        _processInstance(bind, instance);

        if (_handleExistingBind(discovered, bind)) continue;

        _registerInStorage(discovered, bind);
      } catch (_) {
        _storage.pendingObjectBinds.add(bind);
      }
    }
  }

  /// Generic version for typed registration.
  void registerTyped<T>(Bind<T> bind) {
    if (T == Object) {
      register(bind);
      return;
    }

    try {
      final instance = bind.factoryFunction(Injector());
      _processInstance(bind, instance);
    } catch (_) {}

    if (_isSingletonAlreadyRegistered(T, bind)) return;
    if (_handleExistingBind(T, bind)) return;

    _registerInStorage(T, bind);
  }
}
