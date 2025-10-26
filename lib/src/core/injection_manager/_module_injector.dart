import 'dart:developer';
import 'package:auto_injector/auto_injector.dart' as ai;
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/core/injection_manager/_bind_registration.dart';
import 'package:go_router_modular/src/core/injection_manager/_module_registry.dart';
import 'package:go_router_modular/src/core/injection_manager/injection_manager.dart';

/// Injector com contexto de módulo - Segue o padrão do flutter_modular
/// Cada módulo tem seu próprio AutoInjector, que é adicionado ao injector principal
class ModuleInjector extends Injector {
  final ai.AutoInjector _moduleInjector;
  final ModuleRegistry _registry;

  ModuleInjector(this._moduleInjector, this._registry);

  @override
  void add<T extends Object>(dynamic builder, {String? key}) {
    if (builder is Function) {
      // Se T é Object, chamar sem tipo e deixar o auto_injector inferir
      if (T == Object) {
        // Registrar sem tipo e deixar o auto_injector inferir a implementação
        _moduleInjector.add(builder, key: key);
      } else {
        // Passar o tipo explicitamente
        _moduleInjector.add<T>(builder, key: key);
      }
    } else {
      _moduleInjector.add<T>(() => builder, key: key);
    }
  }

  @override
  void addSingleton<T extends Object>(dynamic builder, {String? key}) {
    if (builder is Function) {
      // Se T é Object, chamar sem tipo e deixar o auto_injector inferir
      if (T == Object) {
        _moduleInjector.addSingleton(builder, key: key);
      } else {
        _moduleInjector.addSingleton<T>(builder, key: key);
      }
    } else {
      _moduleInjector.addSingleton<T>(() => builder, key: key);
    }
  }

  @override
  void addLazySingleton<T extends Object>(dynamic builder, {String? key}) {
    if (builder is Function) {
      // Se T é Object, chamar sem tipo e deixar o auto_injector inferir
      if (T == Object) {
        _moduleInjector.addLazySingleton(builder, key: key);
      } else {
        _moduleInjector.addLazySingleton<T>(builder, key: key);
      }
    } else {
      _moduleInjector.addLazySingleton<T>(() => builder, key: key);
    }
  }

  @override
  T get<T extends Object>({String? key}) {
    try {
      return _moduleInjector.get<T>(key: key);
    } catch (e) {
      // Se não encontrou no injector do módulo, tentar através do sistema de resolução
      // Isso permite acessar binds do AppModule
      return InjectionManager.instance.getWithModuleContext<T>(key: key);
    }
  }

  /// Registra uma implementação automaticamente sob a interface correspondente
  void addAs<TInterface extends Object, TImplementation extends TInterface>(
    TInterface Function() builder, {
    String? key,
  }) {
    // Registrar a implementação concreta
    _moduleInjector.add<TImplementation>(builder, key: key);

    // Registrar a interface apontando para a implementação
    _moduleInjector.add<TInterface>(() => _moduleInjector.get<TImplementation>(key: key) as TInterface, key: key);
  }

  /// Registra um singleton automaticamente sob a interface correspondente
  void addSingletonAs<TInterface extends Object, TImplementation extends TInterface>(
    TInterface Function() builder, {
    String? key,
  }) {
    // Registrar a implementação concreta
    _moduleInjector.addSingleton<TImplementation>(builder, key: key);

    // Registrar a interface apontando para a implementação
    _moduleInjector.addSingleton<TInterface>(() => _moduleInjector.get<TImplementation>(key: key) as TInterface, key: key);
  }

  /// Registra um lazy singleton automaticamente sob a interface correspondente
  void addLazySingletonAs<TInterface extends Object, TImplementation extends TInterface>(
    TInterface Function() builder, {
    String? key,
  }) {
    // Registrar a implementação concreta
    _moduleInjector.addLazySingleton<TImplementation>(builder, key: key);

    // Registrar a interface apontando para a implementação
    _moduleInjector.addLazySingleton<TInterface>(() => _moduleInjector.get<TImplementation>(key: key) as TInterface, key: key);
  }
}
