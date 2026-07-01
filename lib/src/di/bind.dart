import 'package:flutter/foundation.dart';
import 'package:go_router_modular/src/di/bind_storage.dart';
import 'package:go_router_modular/src/di/bind_search_protection.dart';
import 'package:go_router_modular/src/di/bind_registry.dart';
import 'package:go_router_modular/src/di/bind_disposer.dart';
import 'package:go_router_modular/src/di/bind_locator.dart';
import 'package:go_router_modular/src/di/injector.dart';

/// Represents a binding between a type and its factory function.
class Bind<T> {
  final T Function(Injector i) factoryFunction;
  final bool isSingleton;
  final bool isLazy;
  final String? key;
  final StackTrace stackTrace;

  Type get type => T;

  bool isType<U>() => this is Bind<U>;

  /// Returns true if T (this bind's declared type) is a subtype of U.
  /// Uses Dart's covariant List to check subtype without creating an instance.
  bool isCompatibleWith<U>() => <T>[] is List<U>;

  T? _cachedInstance;

  Bind(this.factoryFunction, {this.isSingleton = true, this.isLazy = false, this.key})
      : stackTrace = StackTrace.current;

  T get instance {
    if (_cachedInstance == null || !isSingleton) {
      _cachedInstance = factoryFunction(Injector());
    }

    if (_cachedInstance != null && _cachedInstance is ChangeNotifier) {
      try {
        final notifier = _cachedInstance as ChangeNotifier;
        final testListener = () {};
        notifier.addListener(testListener);
        notifier.removeListener(testListener);
      } catch (_) {
        _cachedInstance = factoryFunction(Injector());
      }
    }

    return _cachedInstance!;
  }

  T? get cachedInstance => _cachedInstance;

  set cachedInstance(T? value) => _cachedInstance = value;

  void clearCache() {
    _cachedInstance = null;
  }

  // ==================== DELEGATION ====================

  static final BindRegistry _registry = BindRegistry();
  static final BindDisposer _disposer = BindDisposer();
  static final BindLocator _locator = BindLocator();
  static final BindStorage _storage = BindStorage.instance;
  static final BindSearchProtection _protection = BindSearchProtection.instance;

  // ==================== STATIC METHODS ====================

  static void register(dynamic bind) => _registry.register(bind);

  static void registerBatch(List<Bind<Object>> binds) => _registry.registerBatch(binds);

  static void commitBatch(Injector injector) => _registry.commitBatch(injector);

  static void registerTyped<T>(Bind<T> bind) => _registry.registerTyped<T>(bind);

  static void dispose<T>() => _disposer.dispose<T>();

  static void disposeByKey(String key) => _disposer.disposeByKey(key);

  static void disposeByType(Type type) => _disposer.disposeByType(type);

  static void clearAll() => _disposer.clearAll();

  static T get<T>({String? key}) => _locator.get<T>(key: key);

  static T? tryGet<T>({String? key}) => _locator.tryGet<T>(key: key);

  static bool isRegistered<T>({String? key}) => _locator.isRegistered<T>(key: key);

  static List<String> getAllKeys() => _storage.bindsMapByKey.keys.toList();

  static void cleanSearchAttempts() => _protection.clearAll();

  static void cleanSearchAttemptsForType(Type type) {
    _protection.clearForType(type);
  }

  // ==================== FACTORY METHODS ====================

  static Bind<T> singleton<T>(T Function(Injector i) builder, {String? key}) {
    return Bind<T>(builder, isSingleton: true, isLazy: false, key: key);
  }

  static Bind<T> lazySingleton<T>(T Function(Injector i) builder, {String? key}) {
    return Bind<T>(builder, isSingleton: true, isLazy: true, key: key);
  }

  @Deprecated('Use Bind.add instead')
  static Bind<T> factory<T>(T Function(Injector i) builder, {String? key}) {
    return Bind<T>(builder, isSingleton: false, isLazy: false, key: key);
  }

  static Bind<T> add<T>(T Function(Injector i) builder, {String? key}) {
    return Bind<T>(builder, isSingleton: false, isLazy: false, key: key);
  }
}
