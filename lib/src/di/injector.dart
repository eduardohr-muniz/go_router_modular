import 'package:auto_injector/auto_injector.dart' as ai;
import 'package:go_router_modular/go_router_modular.dart';

class Injector {
  final ai.AutoInjector? _autoInjector;

  Injector() : _autoInjector = null;

  /// Cria um Injector a partir de um AutoInjector específico
  /// Usado para seguir o padrão do flutter_modular
  Injector.fromAutoInjector(ai.AutoInjector injector) : _autoInjector = injector;

  T get<T>({String? key}) {
    try {
      // Se temos um auto_injector específico, usar ele
      if (_autoInjector != null) {
        return _autoInjector.get<T>(key: key);
      }

      // Caso contrário, usar o injector global
      final instance = InjectionManager.instance.injector.get<T>(key: key);
      return instance;
    } catch (e) {
      return Bind.get<T>(key: key); // Fallback to old system if needed
    }
  }

  /// Métodos para registrar binds diretamente (padrão flutter_modular)
  void add<T>(T Function() builder, {String? key}) {
    _autoInjector?.add<T>(builder, key: key);
  }

  void addSingleton<T>(T Function() builder, {String? key}) {
    _autoInjector?.addSingleton<T>(builder, key: key);
  }

  void addLazySingleton<T>(T Function() builder, {String? key}) {
    _autoInjector?.addLazySingleton<T>(builder, key: key);
  }
}
