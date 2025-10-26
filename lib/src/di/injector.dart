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
  void add<T extends Object>(T Function() builder, {String? key}) {
    final injector = _autoInjector ?? InjectionManager.instance.injector;
    injector.add<T>(builder, key: key);
  }

  /// Registra um singleton (instância única criada imediatamente)
  void addSingleton<T extends Object>(T Function() builder, {String? key}) {
    final injector = _autoInjector ?? InjectionManager.instance.injector;
    injector.addSingleton<T>(builder, key: key);
  }

  /// Registra um lazy singleton (instância única criada no primeiro get)
  void addLazySingleton<T extends Object>(T Function() builder, {String? key}) {
    final injector = _autoInjector ?? InjectionManager.instance.injector;
    injector.addLazySingleton<T>(builder, key: key);
  }
}
