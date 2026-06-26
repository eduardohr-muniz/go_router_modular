import 'package:go_router_modular/src/core/bind/bind.dart';
import 'package:go_router_modular/src/core/bind/bind_storage.dart';
import 'package:go_router_modular/src/core/bind/bind_search_protection.dart';
import 'package:go_router_modular/src/di/clean_bind.dart';

/// Handles bind disposal and cleanup.
class BindDisposer {
  final BindStorage _storage = BindStorage.instance;
  final BindSearchProtection _protection = BindSearchProtection.instance;

  void dispose<T>() {
    if (T == Object) return;

    _storage.negativeLookupCache.clear();

    final bind = _storage.bindsMap[T];
    if (bind != null) {
      _disposeBindInstance(bind);
      _storage.bindsMap.remove(T);

      if (bind.key != null) {
        _storage.bindsMapByKey.remove(bind.key);
      }
    }

    // Search bindsMapByKey for binds of this type
    final keysToRemove = <String>[];
    for (final entry in _storage.bindsMapByKey.entries) {
      final bindByKey = entry.value;
      bool isCompatible = bindByKey.isType<T>() || bindByKey.type == T;

      if (!isCompatible && bindByKey.cachedInstance != null) {
        isCompatible = bindByKey.cachedInstance is T;
      }

      if (isCompatible) {
        keysToRemove.add(entry.key);
        _disposeBindInstance(bindByKey);
      }
    }

    for (final key in keysToRemove) {
      _storage.bindsMapByKey.remove(key);
    }

    _clearSearchState(T);
  }

  void disposeByKey(String key) {
    _storage.negativeLookupCache.clear();
    final bind = _storage.bindsMapByKey[key];
    if (bind != null) {
      if (bind.cachedInstance != null) {
        final type = bind.cachedInstance!.runtimeType;
        CleanBind.fromInstance(bind.cachedInstance!);
        _storage.bindsMap.remove(type);
        _clearSearchState(type);
      }
      bind.clearCache();
    }
    _storage.bindsMapByKey.remove(key);
  }

  void disposeByType(Type type) {
    _storage.negativeLookupCache.clear();
    final bind = _storage.bindsMap[type];
    if (bind != null) _disposeBindInstance(bind);
    _storage.bindsMap.remove(type);

    // Remove all keys associated with this type
    final keysToRemove = <String>[];
    for (final entry in _storage.bindsMapByKey.entries) {
      final b = entry.value;
      bool isMatch = b.type == type;
      if (!isMatch && b.cachedInstance != null) {
        isMatch = b.cachedInstance!.runtimeType == type;
      }
      if (isMatch) {
        keysToRemove.add(entry.key);
        _disposeBindInstance(b);
      }
    }

    for (final key in keysToRemove) {
      _storage.bindsMapByKey.remove(key);
    }

    // Remove compatible types from the map
    final typesToRemove = <Type>[];
    for (final entry in _storage.bindsMap.entries) {
      final b = entry.value;
      bool isMatch = b.type == type;
      if (!isMatch && b.cachedInstance != null) {
        isMatch = b.cachedInstance!.runtimeType == type;
      }
      if (isMatch) {
        typesToRemove.add(entry.key);
        _disposeBindInstance(b);
      }
    }

    for (final typeToRemove in typesToRemove) {
      _storage.bindsMap.remove(typeToRemove);
      _clearSearchState(typeToRemove);
    }

    _clearSearchState(type);
  }

  void clearAll() {
    _protection.clearAll();

    final bindsToClean = List<Bind>.from(_storage.bindsMap.values);
    final bindsByKeyToClean = List<Bind>.from(_storage.bindsMapByKey.values);

    _storage.bindsMap.clear();
    _storage.bindsMapByKey.clear();
    _storage.pendingObjectBinds.clear();
    _storage.negativeLookupCache.clear();

    for (final bind in bindsToClean) {
      _disposeBindInstance(bind);
    }

    for (final bind in bindsByKeyToClean) {
      _disposeBindInstance(bind);
    }
  }

  void _disposeBindInstance(Bind bind) {
    try {
      if (bind.cachedInstance != null) {
        CleanBind.fromInstance(bind.cachedInstance!);
      }
    } catch (_) {}
    bind.clearCache();
  }

  void _clearSearchState(Type type) {
    _protection.currentlySearching.remove(type);
    _protection.searchAttempts.remove(type);
  }
}
