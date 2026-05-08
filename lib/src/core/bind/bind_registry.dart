import 'package:go_router_modular/src/core/bind/bind.dart';
import 'package:go_router_modular/src/core/bind/bind_storage.dart';
import 'package:go_router_modular/src/di/clean_bind.dart';
import 'package:go_router_modular/src/di/injector.dart';

/// Handles bind registration logic.
class BindRegistry {
  final BindStorage _storage = BindStorage.instance;

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

  /// Registers multiple binds without creating instances.
  /// Real types are discovered later in [commitBatch].
  void registerBatch(List<Bind<Object>> binds) {
    for (final bind in binds) {
      _storage.pendingObjectBinds.add(bind);

      if (bind.key != null) {
        _storage.bindsMapByKey[bind.key!] = bind;
      }
    }
  }

  /// Commits pending binds by discovering their real types.
  void commitBatch(Injector injector) {
    final pendingBinds = List<Bind<Object>>.from(_storage.pendingObjectBinds);
    _storage.pendingObjectBinds.clear();

    for (final bind in pendingBinds) {
      if (bind.type != Object && _isSingletonAlreadyRegistered(bind.type, bind)) {
        bind.cachedInstance ??= _storage.bindsMap[bind.type]?.cachedInstance;
        continue;
      }

      try {
        final instance = bind.factoryFunction(injector);
        final discoveredType = instance.runtimeType;

        if (discoveredType == Object) {
          _storage.pendingObjectBinds.add(bind);
          continue;
        }

        if (_isSingletonAlreadyRegistered(discoveredType, bind)) {
          bind.cachedInstance ??= instance;
          _registerDeclaredType(bind);
          continue;
        }

        _processInstance(bind, instance);

        if (_handleExistingBind(discoveredType, bind)) {
          _registerDeclaredType(bind);
          continue;
        }

        _registerDeclaredType(bind);
        _registerDiscoveredType(discoveredType, bind);
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
