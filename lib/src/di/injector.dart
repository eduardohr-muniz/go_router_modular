import 'package:auto_injector/auto_injector.dart' as ai;
import 'package:go_router_modular/go_router_modular.dart';

/// Wrapper para AutoInjector seguindo o padrão do flutter_modular
/// Permite que módulos registrem binds usando i.add(), i.addSingleton(), etc.
/// AutoInjector resolve interfaces automaticamente! 🎉
class Injector {
  final ai.AutoInjector? _autoInjector;

  Injector() : _autoInjector = null;

  /// Registra uma implementação automaticamente sob a interface correspondente
  /// Detecta interface baseado no nome (ex: MyService implementa IService)
  ///
  /// Uso: i.addAs<IService, MyService>(MyService.new)
  /// Isso registra tanto IService quanto MyService
  void addAs<TInterface extends Object, TImplementation extends TInterface>(
    TInterface Function() builder, {
    String? key,
  }) {
    final injector = _autoInjector ?? InjectionManager.instance.injector;

    // Registrar a implementação concreta
    injector.add<TImplementation>(builder, key: key);

    // Registrar a interface apontando para a implementação
    injector.add<TInterface>(() => injector.get<TImplementation>(key: key) as TInterface, key: key);
  }

  /// Registra um singleton automaticamente sob a interface correspondente
  void addSingletonAs<TInterface extends Object, TImplementation extends TInterface>(
    TInterface Function() builder, {
    String? key,
  }) {
    final injector = _autoInjector ?? InjectionManager.instance.injector;

    // Registrar a implementação concreta
    injector.addSingleton<TImplementation>(builder, key: key);

    // Registrar a interface apontando para a implementação
    injector.addSingleton<TInterface>(() => injector.get<TImplementation>(key: key) as TInterface, key: key);
  }

  /// Registra um lazy singleton automaticamente sob a interface correspondente
  void addLazySingletonAs<TInterface extends Object, TImplementation extends TInterface>(
    TInterface Function() builder, {
    String? key,
  }) {
    final injector = _autoInjector ?? InjectionManager.instance.injector;

    // Registrar a implementação concreta
    injector.addLazySingleton<TImplementation>(builder, key: key);

    // Registrar a interface apontando para a implementação
    injector.addLazySingleton<TInterface>(() => injector.get<TImplementation>(key: key) as TInterface, key: key);
  }

  /// Obtém uma instância registrada usando o sistema de resolução com contexto
  T get<T extends Object>({String? key}) {
    return InjectionManager.instance.getWithModuleContext<T>(key: key);
  }

  /// Registra uma factory (nova instância a cada get)
  /// Suporta sintaxe `.new` do auto_injector
  void add<T extends Object>(dynamic builder, {String? key}) {
    final injector = _autoInjector ?? InjectionManager.instance.injector;
    if (builder is Function && T == Object) {
      // Se T é Object, chamar sem tipo e deixar o auto_injector inferir
      injector.add(builder, key: key);
    } else if (builder is Function) {
      injector.add<T>(builder, key: key);
    } else {
      injector.add<T>(() => builder, key: key);
    }
  }

  /// Registra um singleton (instância única criada imediatamente)
  /// Suporta sintaxe `.new` do auto_injector
  void addSingleton<T extends Object>(dynamic builder, {String? key}) {
    final injector = _autoInjector ?? InjectionManager.instance.injector;
    if (builder is Function && T == Object) {
      injector.addSingleton(builder, key: key);
    } else if (builder is Function) {
      injector.addSingleton<T>(builder, key: key);
    } else {
      injector.addSingleton<T>(() => builder, key: key);
    }
  }

  /// Registra um lazy singleton (instância única criada no primeiro get)
  /// Suporta sintaxe `.new` do auto_injector
  void addLazySingleton<T extends Object>(dynamic builder, {String? key}) {
    final injector = _autoInjector ?? InjectionManager.instance.injector;
    if (builder is Function && T == Object) {
      injector.addLazySingleton(builder, key: key);
    } else if (builder is Function) {
      injector.addLazySingleton<T>(builder, key: key);
    } else {
      injector.addLazySingleton<T>(() => builder, key: key);
    }
  }
}
