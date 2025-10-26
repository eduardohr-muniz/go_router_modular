import 'package:auto_injector/auto_injector.dart' as ai;
import 'package:go_router_modular/go_router_modular.dart';

/// Wrapper para AutoInjector seguindo o padrão do flutter_modular
/// Permite que módulos registrem binds usando i.add(), i.addSingleton(), etc.
/// AutoInjector resolve interfaces automaticamente! 🎉
class Injector {
  final ai.AutoInjector? _autoInjector;

  Injector() : _autoInjector = null;

  /// Obtém uma instância registrada usando o sistema de resolução com contexto
  T get<T extends Object>({String? key}) {
    return InjectionManager.instance.getWithModuleContext<T>(key: key);
  }

  /// Registra uma factory (nova instância a cada get)
  /// Suporta sintaxe `.new` do auto_injector
  void add<T extends Object>(dynamic builder, {String? key}) {
    final injector = _autoInjector ?? InjectionManager.instance.injector;
    // Auto-injector resolve parâmetros do construtor automaticamente
    injector.add<T>(builder is Function ? builder : () => builder, key: key);
  }

  /// Registra um singleton (instância única criada imediatamente)
  /// Suporta sintaxe `.new` do auto_injector
  void addSingleton<T extends Object>(dynamic builder, {String? key}) {
    final injector = _autoInjector ?? InjectionManager.instance.injector;
    injector.addSingleton<T>(builder is Function ? builder : () => builder, key: key);
  }

  /// Registra um lazy singleton (instância única criada no primeiro get)
  /// Suporta sintaxe `.new` do auto_injector
  void addLazySingleton<T extends Object>(dynamic builder, {String? key}) {
    final injector = _autoInjector ?? InjectionManager.instance.injector;
    injector.addLazySingleton<T>(builder is Function ? builder : () => builder, key: key);
  }
}
