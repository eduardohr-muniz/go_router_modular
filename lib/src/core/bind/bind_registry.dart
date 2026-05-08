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
  /// `bindsMap[T]` stores **only the unkeyed** bind for a given type; keyed
  /// binds live exclusively in `bindsMapByKey`. This mirrors `BindLocator`'s
  /// expectation that an unkeyed `get<T>()` skips keyed slots.
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

      // Skip type-indexing for keyed binds: their canonical slot is the key map.
      if (bind.key != null) continue;

      _indexCanonicalOrPropagate(declared, bind);
    }
  }

  /// Materializes binds registered in the current batch in three phases:
  ///   1. **Canonical singletons** (eager and lazy): run the factory once,
  ///      cache it, and index `bindsMap[runtimeType]` so the compatibility
  ///      lookup (`Injector.get<I>()` against an interface) keeps working
  ///      when the bind was registered without an explicit generic type.
  ///   2. **Duplicate binds** produced when imports re-run `module.binds`:
  ///      inherit `cachedInstance` from the canonical bind so introspection
  ///      (`_mapBindsToIdentifiers`, `_logRegisteredBinds`,
  ///      `_validateModuleBinds`) does not re-invoke factories.
  ///   3. **Object-typed binds** (no compile-time generic) keep using the
  ///      legacy deferred discovery path via [BindStorage.pendingObjectBinds].
  void commitBatch(Injector injector) {
    final batch = List<Bind<Object>>.from(_pendingBatch);
    _pendingBatch.clear();

    _instantiateCanonicalSingletons(batch, injector);
    _propagateCacheToDuplicates(batch);
    _commitObjectBinds(injector);
  }

  /// Pre-indexes an unkeyed typed [bind] under [declared].
  ///
  /// First registration wins; subsequent duplicates only inherit cache (when
  /// available) so introspection does not re-invoke factories. Caller must
  /// ensure [bind] is unkeyed — keyed binds belong in
  /// [BindStorage.bindsMapByKey] only.
  void _indexCanonicalOrPropagate(Type declared, Bind bind) {
    assert(bind.key == null, 'Keyed binds must not be indexed in bindsMap');

    final existing = _storage.bindsMap[declared];
    if (existing == null) {
      _storage.bindsMap[declared] = bind;
      return;
    }

    if (existing.key == null && existing.isSingleton && existing.cachedInstance != null) {
      bind.cachedInstance ??= existing.cachedInstance;
    }
  }

  void _instantiateCanonicalSingletons(List<Bind<Object>> batch, Injector injector) {
    for (final bind in batch) {
      if (bind.type == Object) continue;
      if (!bind.isSingleton) continue;
      if (bind.cachedInstance != null) continue;
      if (!_isCanonical(bind)) continue;

      try {
        final instance = bind.factoryFunction(injector);
        bind.cachedInstance = instance;

        // Index discovered runtime type so `BindLocator._searchCompatibleBind`
        // can resolve `Injector.get<Interface>()` against concrete singletons
        // — but never displace an unkeyed slot with a keyed one.
        final discovered = instance.runtimeType;
        if (discovered != bind.type && discovered != Object && bind.key == null) {
          _storage.bindsMap.putIfAbsent(discovered, () => bind);
        }
      } catch (_) {
        // Cache stays null; runtime resolution will retry the factory the
        // next time `bind.instance` is read (e.g. through `i.get<T>()`).
      }
    }
  }

  /// A [bind] is canonical when it owns its slot in storage (`bindsMap[type]`
  /// for unkeyed binds, `bindsMapByKey[key]` for keyed binds). Duplicates
  /// produced by re-running `module.binds` from imports are non-canonical and
  /// must reuse the canonical cache instead of running their factory again.
  bool _isCanonical(Bind bind) {
    if (bind.key != null) {
      return identical(_storage.bindsMapByKey[bind.key!], bind);
    }
    return identical(_storage.bindsMap[bind.type], bind);
  }

  void _propagateCacheToDuplicates(List<Bind<Object>> batch) {
    for (final bind in batch) {
      if (bind.type == Object) continue;
      if (bind.cachedInstance != null) continue;

      final canonical = bind.key != null //
          ? _storage.bindsMapByKey[bind.key!]
          : _storage.bindsMap[bind.type];

      if (canonical == null || identical(canonical, bind)) continue;
      if (canonical.key != bind.key) continue;
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
