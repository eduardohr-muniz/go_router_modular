import 'package:auto_injector/auto_injector.dart';
import 'package:flutter/material.dart';
import 'injector.dart';

/// Configuration for dependency injection bindings
class BindConfig<T> {
  final T Function()? factory;
  final T? instance;
  final bool singleton;
  final bool lazy;
  final String? key;
  final bool permanent;

  const BindConfig({
    this.factory,
    this.instance,
    this.singleton = false,
    this.lazy = false,
    this.key,
    this.permanent = false,
  });

  /// Create a factory binding
  factory BindConfig.factory(T Function() factory, {String? key}) {
    return BindConfig<T>(
      factory: factory,
      key: key,
    );
  }

  /// Create a singleton binding
  factory BindConfig.singleton(T Function() factory, {String? key, bool lazy = false}) {
    return BindConfig<T>(
      factory: factory,
      singleton: true,
      lazy: lazy,
      key: key,
    );
  }

  /// Create an instance binding
  factory BindConfig.instance(T instance, {String? key, bool permanent = false}) {
    return BindConfig<T>(
      instance: instance,
      singleton: true,
      permanent: permanent,
      key: key,
    );
  }

  /// Create a lazy singleton binding
  factory BindConfig.lazySingleton(T Function() factory, {String? key}) {
    return BindConfig<T>(
      factory: factory,
      singleton: true,
      lazy: true,
      key: key,
    );
  }
}

/// Service to manage dependency injection bindings
class BindService {
  final AutoInjector _injector;

  BindService(this._injector);

  /// Get a dependency by type and optional key
  T get<T extends Object>([String? key]) {
    return _injector.get<T>(key: key);
  }

  /// Try to get a dependency, returns null if not found
  T? tryGet<T extends Object>([String? key]) {
    try {
      return _injector.get<T>(key: key);
    } catch (e) {
      return null;
    }
  }

  /// Check if a dependency is registered
  bool isRegistered<T extends Object>([String? key]) {
    try {
      _injector.get<T>(key: key);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Dispose a singleton instance
  bool disposeSingleton<T extends Object>([String? key]) {
    return _injector.disposeSingleton<T>(key: key) != null;
  }

  /// Replace an instance
  void replaceInstance<T>(T instance, [String? key]) {
    _injector.replaceInstance(instance, key: key);
  }

  /// Add a binding configuration
  void add<T extends Object>(BindConfig<T> config) {
    if (config.instance != null) {
      if (config.permanent) {
        _injector.addInstance<T>(config.instance!, key: config.key);
      } else {
        _injector.addSingleton<T>(() => config.instance!, key: config.key);
      }
    } else if (config.factory != null) {
      if (config.singleton) {
        if (config.lazy) {
          _injector.addLazySingleton<T>(config.factory!, key: config.key);
        } else {
          _injector.addSingleton<T>(config.factory!, key: config.key);
        }
      } else {
        _injector.add<T>(config.factory!, key: config.key);
      }
    }
  }

  /// Add a factory binding
  void addFactory<T extends Object>(T Function() factory, {String? key}) {
    _injector.add<T>(factory, key: key);
  }

  /// Add a singleton binding
  void addSingleton<T extends Object>(T Function() factory, {String? key, bool lazy = false}) {
    if (lazy) {
      _injector.addLazySingleton<T>(factory, key: key);
    } else {
      _injector.addSingleton<T>(factory, key: key);
    }
  }

  /// Add an instance binding
  void addInstance<T extends Object>(T instance, {String? key, bool permanent = false}) {
    if (permanent) {
      _injector.addInstance<T>(instance, key: key);
    } else {
      _injector.addSingleton<T>(() => instance, key: key);
    }
  }

  /// Commit all pending bindings
  void commit() {
    _injector.commit();
  }

  /// Dispose all bindings
  void dispose() {
    _injector.dispose();
  }
}

/// Global bind service instance
final BindService bindService = BindService(injector);
