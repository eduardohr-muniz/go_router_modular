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
    Bind<T> existingBind = _bindsMap[type] as Bind<T>;
    if (existingBind.isLazy || existingBind.isSingleton) return;

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
          _bindsMap[T] = bind; // Atualiza o mapa com o novo Bind encontrado
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
    final bind = Bind<T>(builder, isSingleton: true, isLazy: false);
    return bind;
  }

  static Bind<T> lazySingleton<T>(T Function(Injector i) builder) {
    final bind = Bind<T>(builder, isSingleton: true, isLazy: true);
    return bind;
  }

  static Bind<T> factory<T>(T Function(Injector i) builder) {
    final bind = Bind<T>(builder, isSingleton: false, isLazy: false);
    return bind;
  }
}
