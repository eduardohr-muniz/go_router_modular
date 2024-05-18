import 'package:flutter/material.dart';

class Bind<T> {
  final T Function(Injector) factoryFunction;
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

  static void unregister<T>(Bind<T> bind) {
    if (T.toString() == "Object") return;
    // print("Unregistering bind for ${T.toString()}");
    _bindsMap.remove(T);
  }

  static void unregisterType(Type type) {
    // print("Unregistering bind for $type");
    _bindsMap.remove(type);
  }

  static Bind<T> find<T>() {
    var bind = _bindsMap[T] as Bind<T>?;

    if (bind == null) {
      throw Exception('Bind not found for type ${T.toString()}');
    }
    return bind;
  }

  static T get<T>() => find<T>().instance;

  static Bind<T> create<T>(T Function(Injector i) factoryFunction) {
    final bind = Bind<T>(factoryFunction, isSingleton: false, isLazy: true);
    // register<T>(bind);
    return bind;
  }

  static Bind<T> singleton<T>(T Function(Injector i) factoryFunction) {
    final bind = Bind<T>(factoryFunction, isSingleton: true, isLazy: false);
    // register<T>(bind);
    return bind;
  }

  static Bind<T> lazySingleton<T>(T Function(Injector i) factoryFunction) {
    final bind = Bind<T>(factoryFunction, isSingleton: true, isLazy: true);
    // register<T>(bind);
    return bind;
  }

  static Bind<T> factory<T>(T Function(Injector i) factoryFunction) {
    final bind = Bind<T>(factoryFunction, isSingleton: false, isLazy: true);
    // register<T>(bind);
    return bind;
  }
}

class Injector {
  T get<T>() => Bind.get<T>();
}

extension BindContextExtension on BuildContext {
  T read<T>() {
    final bind = Bind.find<T>();
    return bind.instance;
  }
}
