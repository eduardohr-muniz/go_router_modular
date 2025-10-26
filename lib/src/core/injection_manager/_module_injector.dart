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
    _moduleInjector.add<T>(builder is Function ? builder : () => builder, key: key);
  }

  @override
  void addSingleton<T extends Object>(dynamic builder, {String? key}) {
    _moduleInjector.addSingleton<T>(builder is Function ? builder : () => builder, key: key);
  }

  @override
  void addLazySingleton<T extends Object>(dynamic builder, {String? key}) {
    _moduleInjector.addLazySingleton<T>(builder is Function ? builder : () => builder, key: key);
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
}
