import 'package:flutter/material.dart';
import 'package:go_router_modular/src/injector.dart';

class Bind<T> {
  final T Function(Injector i) factoryFunction;
  final bool isSingleton;
  final bool isLazy;
  T? _instance;

  Bind(
    this.factoryFunction, {
    this.isSingleton = true,
    this.isLazy = true,
  });

  T get instance {
    if (_instance == null || !isSingleton) {
      _instance = factoryFunction(Injector());
    }
    return _instance!;
  }

  static final Map<Type, Bind> _bindsMap = {};

  static void register<T>(Bind<T> bind) {
    final type = bind.instance.runtimeType;

    if (!_bindsMap.containsKey(type)) {
      _bindsMap[type] = bind;
      return;
    }
    Bind<T> b = _bindsMap[type] as Bind<T>;
    if (b.isLazy || b.isSingleton) return;

    _bindsMap[type] = bind;
  }

  static void dispose<T>(Bind<T> bind) {
    if (T.toString() == "Object") return;
    _bindsMap.remove(T);
  }

  static void disposeByType(Type type) {
    _bindsMap.remove(type);
  }

  static T _find<T>() {
    var bind = _bindsMap[T];

    if (bind == null) {
      for (var entry in _bindsMap.entries) {
        if (entry.value.instance is T) {
          bind = Bind<T>((injector) => entry.value.instance, isSingleton: entry.value.isSingleton, isLazy: entry.value.isLazy);
          // _bindsMap[entry.key] = bind;
          break;
        }
      }

      if (bind == null) {
        throw Exception('Bind not found for type ${T.toString()}');
      }
    }

    return bind.instance as T;
  }

  static T get<T>() => _find<T>();

  static Bind<T> singleton<T>(T Function(Injector i) factoryFunction) {
    final bind = Bind<T>(factoryFunction, isSingleton: true, isLazy: false);
    return bind;
  }

  static Bind<T> lazySingleton<T>(T Function(Injector i) factoryFunction) {
    final bind = Bind<T>(factoryFunction, isSingleton: true, isLazy: true);
    return bind;
  }

  static Bind<T> factory<T>(T Function(Injector i) factoryFunction) {
    final bind = Bind<T>(factoryFunction, isSingleton: false, isLazy: true);
    return bind;
  }
}

extension BindContextExtension on BuildContext {
  T read<T>() {
    final bind = Bind._find<T>();
    return bind;
  }
}
