import 'dart:developer' as developer;

import 'package:go_router_modular/src/di/bind.dart';
import 'package:go_router_modular/src/di/bind_storage.dart';
import 'package:go_router_modular/src/di/clean_bind.dart';
import 'package:go_router_modular/src/di/injector.dart';
import 'package:go_router_modular/src/shared/setup.dart';

/// Outcome of resolving a slot conflict in [BindStorage].
///
/// `BindRegistry` chooses the next step from a small, named set instead of
/// returning a raw `bool` whose meaning depended on the call site.
enum _SlotConflictResolution {
  /// No bind currently owns the slot — caller should write the new bind into it.
  empty,

  /// New bind has been routed to its keyed slot — no further action is needed.
  routedToKeyMap,

  /// Slot has been overwritten because the new bind takes precedence — caller
  /// is done.
  replaced,
}

/// Owns every write to [BindStorage].
///
/// Two flows live side-by-side:
///   * **Batch flow** ([registerBatch] + [commitBatch]): used by
///     `InjectionManager` when a module commits its `binds`. Pre-indexes every
///     typed bind in `bindsMap` so factories within the same batch resolve
///     dependencies regardless of declaration order, then materialises
///     singletons exactly once.
///   * **Singular legacy flow** ([register] / [registerTyped]): kept for
///     direct callers (tests, `bind_template`, `modular_test_scope`) that
///     register one bind at a time.
///
/// Both flows respect a single invariant for the dual-map storage:
/// `bindsMap[Type]` only ever holds **unkeyed** binds; keyed binds live
/// exclusively in `bindsMapByKey`. [BindLocator._searchByType] relies on this
/// when an unkeyed `get<T>()` skips keyed slots.
class BindRegistry {
  final BindStorage _storage = BindStorage.instance;

  /// Binds queued by [registerBatch] awaiting [commitBatch].
  final List<Bind<Object>> _uncommittedBatch = [];

  // ==================== PUBLIC API: BATCH FLOW ====================

  /// Queues [binds] for commit and pre-indexes their canonical slots.
  ///
  /// Factories are NOT invoked here — that is [commitBatch]'s job. Pre-indexing
  /// means cross-references inside the batch (e.g. `i.get<Dep>()` from another
  /// factory) resolve regardless of declaration order.
  void registerBatch(List<Bind<Object>> binds) {
    _storage.negativeLookupCache.clear();
    for (final bind in binds) {
      _uncommittedBatch.add(bind);
      _routeKeyedBindToKeyMap(bind);

      if (bind.type == Object) {
        _storage.pendingObjectBinds.add(bind);
        continue;
      }

      if (bind.key != null) continue;

      _indexUnkeyedCanonicalSlot(bind);
    }
  }

  /// Materialises binds queued by [registerBatch] in three phases:
  ///   1. Run the canonical singleton factory once and cache it; index its
  ///      `runtimeType` in `bindsMap` so the compatibility lookup
  ///      (`Injector.get<I>()` against an interface) finds concrete singletons.
  ///   2. Propagate `cachedInstance` to duplicate `Bind` objects produced when
  ///      imports re-execute `module.binds`, so introspection
  ///      (`_mapBindsToIdentifiers`, logging, validation) doesn't re-invoke
  ///      factories.
  ///   3. Resolve `Bind<Object>` registrations via the deferred discovery path.
  void commitBatch(Injector injector) {
    final batch = List<Bind<Object>>.from(_uncommittedBatch);
    _uncommittedBatch.clear();

    _instantiateCanonicalSingletons(batch, injector);
    _propagateCacheToDuplicates(batch);
    _commitObjectBinds(injector);
  }

  // ==================== PUBLIC API: SINGULAR (LEGACY) FLOW ====================

  /// Registers [bind] eagerly, discovering its real type via the factory when
  /// possible. Kept for direct callers; new code should prefer [registerBatch].
  ///
  /// The **canonical slot** is the bind's declared generic type when it is
  /// known (`Bind<T>` with `T != Object`); only untyped binds (`Bind<Object>`)
  /// fall back to the discovered runtime type. Without this, a typed factory
  /// like `Bind.factory<IService>((i) => ServiceImpl())` would be indexed
  /// under `ServiceImpl` and `get<IService>` would miss Strategy 2, forcing
  /// the (now-removed) probe path through compatibility search.
  void register(dynamic bind) {
    if (bind is! Bind) {
      throw ArgumentError('Bind.register expects a Bind, but received ${bind.runtimeType}');
    }
    _storage.negativeLookupCache.clear();

    Type discoveredType = bind.type;

    try {
      final instance = bind.factoryFunction(Injector());
      discoveredType = instance.runtimeType;
      _processInstance(bind, instance);
    } catch (e, s) {
      _swallowError(e, s, context: 'register.factory');
      if (discoveredType == Object) {
        _storage.pendingObjectBinds.add(bind);
      }
    }

    final canonicalType = bind.type != Object ? bind.type : discoveredType;

    if (_isSingletonAlreadyRegistered(canonicalType, bind)) return;
    if (_resolveSlotConflict(canonicalType, bind) != _SlotConflictResolution.empty) return;

    _writeToCanonicalSlot(canonicalType, bind);
    _indexDiscoveredType(discoveredType, bind);
  }

  /// Generic version of [register] used when the type is statically known.
  void registerTyped<T>(Bind<T> bind) {
    if (T == Object) {
      register(bind);
      return;
    }

    try {
      final instance = bind.factoryFunction(Injector());
      _processInstance(bind, instance);
    } catch (e, s) {
      _swallowError(e, s, context: 'registerTyped.factory');
    }

    if (_isSingletonAlreadyRegistered(T, bind)) return;
    if (_resolveSlotConflict(T, bind) != _SlotConflictResolution.empty) return;

    _writeToCanonicalSlot(T, bind);
  }

  // ==================== BATCH PHASES ====================

  void _instantiateCanonicalSingletons(List<Bind<Object>> batch, Injector injector) {
    for (final bind in batch) {
      if (bind.type == Object) continue;
      if (!bind.isSingleton) continue;
      if (bind.cachedInstance != null) continue;
      if (!_ownsCanonicalSlot(bind)) continue;

      try {
        final instance = bind.factoryFunction(injector);
        bind.cachedInstance = instance;
        _indexDiscoveredType(instance.runtimeType, bind);
      } catch (e, s) {
        _swallowError(e, s, context: 'commitBatch.singleton<${bind.type}>');
      }
    }
  }

  void _propagateCacheToDuplicates(List<Bind<Object>> batch) {
    for (final bind in batch) {
      if (bind.type == Object) continue;
      if (bind.cachedInstance != null) continue;

      final canonical = _canonicalBindFor(bind);
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

        if (_resolveSlotConflict(discovered, bind) != _SlotConflictResolution.empty) continue;

        _writeToCanonicalSlot(discovered, bind);
      } catch (e, s) {
        _swallowError(e, s, context: 'commitObjectBinds.factory');
        _storage.pendingObjectBinds.add(bind);
      }
    }
  }

  // ==================== CANONICAL SLOT POLICY ====================

  /// Returns the bind that currently owns [bind]'s canonical slot, or null.
  Bind? _canonicalBindFor(Bind bind) {
    if (bind.key != null) return _storage.bindsMapByKey[bind.key!];
    return _storage.bindsMap[bind.type];
  }

  /// `true` when [bind] is the storage owner of its canonical slot.
  bool _ownsCanonicalSlot(Bind bind) => identical(_canonicalBindFor(bind), bind);

  /// Writes [bind] into its canonical slot.
  ///
  /// Keyed binds always go to `bindsMapByKey`; unkeyed binds go to
  /// `bindsMap[type]`. Routing through here is the single point that enforces
  /// the invariant relied upon by [BindLocator].
  void _writeToCanonicalSlot(Type type, Bind bind) {
    if (bind.key != null) {
      _storage.bindsMapByKey[bind.key!] = bind;
      return;
    }
    _storage.bindsMap[type] = bind;
  }

  /// Pre-indexes an unkeyed [bind] under its declared type.
  ///
  /// First registration wins; later duplicates only inherit cache. Caller must
  /// ensure [bind] is unkeyed.
  void _indexUnkeyedCanonicalSlot(Bind bind) {
    assert(bind.key == null, 'Keyed binds must not be indexed in bindsMap');

    final declared = bind.type;
    final existing = _storage.bindsMap[declared];
    if (existing == null) {
      _storage.bindsMap[declared] = bind;
      return;
    }

    if (existing.key == null && existing.isSingleton && existing.cachedInstance != null) {
      bind.cachedInstance ??= existing.cachedInstance;
    }
  }

  /// Indexes [bind] under its discovered runtime type, never displacing an
  /// existing slot. Allows `BindLocator._searchCompatibleBind` to resolve
  /// `Injector.get<Interface>()` against concrete singletons.
  void _indexDiscoveredType(Type discovered, Bind bind) {
    if (discovered == Object) return;
    if (discovered == bind.type) return;
    if (bind.key != null) return;
    _storage.bindsMap.putIfAbsent(discovered, () => bind);
  }

  /// Routes a keyed [bind] to `bindsMapByKey`. No-op when [bind] is unkeyed.
  void _routeKeyedBindToKeyMap(Bind bind) {
    final key = bind.key;
    if (key == null) return;
    _storage.bindsMapByKey[key] = bind;
  }

  // ==================== LEGACY FLOW HELPERS ====================

  bool _isSingletonAlreadyRegistered(Type type, Bind bind) {
    if (!bind.isSingleton) return false;
    final existing = _storage.bindsMap[type];
    return existing != null && existing.key == bind.key;
  }

  _SlotConflictResolution _resolveSlotConflict(Type type, Bind bind) {
    final existing = _storage.bindsMap[type];
    if (existing == null) return _SlotConflictResolution.empty;

    if (existing.key == bind.key) {
      existing.clearCache();
      return _SlotConflictResolution.empty;
    }

    if (bind.key != null) {
      _storage.bindsMapByKey[bind.key!] = bind;
      return _SlotConflictResolution.routedToKeyMap;
    }

    _storage.bindsMap[type] = bind;
    return _SlotConflictResolution.replaced;
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
      } catch (e, s) {
        _swallowError(e, s, context: 'processInstance.cleanFactoryTemp');
      }
    }
  }

  // ==================== ERROR HANDLING ====================

  /// Logs swallowed errors when `debugLogGoRouterModular` is enabled. Keeps
  /// silent in release builds.
  void _swallowError(Object error, StackTrace stack, {required String context}) {
    if (!SetupModular.instance.debugLogGoRouterModular) return;
    developer.log(
      'Swallowed error in $context: $error',
      name: 'GO_ROUTER_MODULAR',
      error: error,
      stackTrace: stack,
    );
  }
}
