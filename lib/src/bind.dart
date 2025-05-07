import 'package:go_router_modular/src/injector.dart';

enum BindType {
  singleton,
  lazySingleton,
  factory,
}

class Bind<T> {
  final T Function(Injector i) factoryFunction;
  final BindType bindType;

  T? _instance;
  Type? _type;

  Bind(
    this.factoryFunction, {
    this.bindType = BindType.factory,
  });

  Type get type {
    if (_type == null) {
      try {
        _type = factoryFunction(Injector()).runtimeType;
      } catch (e) {
        throw Exception('Failed to determine type for Bind: $e');
      }
    }
    return _type!;
  }

  T get instance {
    switch (bindType) {
      case BindType.singleton:
        _instance ??= factoryFunction(Injector());
        return _instance!;

      case BindType.lazySingleton:
        _instance ??= factoryFunction(Injector());
        return _instance!;

      case BindType.factory:
        return factoryFunction(Injector());
    }
  }

  static final Map<Type, Bind> _bindsMap = {};

  static Future<void> register<T>(Bind<T> bind) async {
    try {
      final type = bind.type;

      if (!_bindsMap.containsKey(type)) {
        _bindsMap[type] = bind;
        return;
      }

      Bind<T> existingBind = _bindsMap[type] as Bind<T>;
      if (existingBind.bindType == BindType.singleton ||
          existingBind.bindType == BindType.lazySingleton) {
        return;
      }

      _bindsMap[type] = bind;
    } catch (e) {
      throw Exception('Failed to register bind: $e');
    }
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
          bind = Bind<T>((injector) => entry.value.instance,
              bindType: entry.value.bindType);
          _bindsMap[T] = bind;
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

  static Bind<T> singleton<T>(T Function(Injector i) builder) {
    final bind = Bind<T>(builder, bindType: BindType.singleton);
    return bind;
  }

  static Bind<T> lazySingleton<T>(T Function(Injector i) builder) {
    final bind = Bind<T>(builder, bindType: BindType.lazySingleton);
    return bind;
  }

  static Bind<T> factory<T>(T Function(Injector i) builder) {
    final bind = Bind<T>(builder, bindType: BindType.factory);
    return bind;
  }
}
