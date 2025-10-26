import 'package:get_it/get_it.dart';
import 'package:go_router_modular/go_router_modular.dart';

/// Wrapper para GetIt seguindo o padrão do flutter_modular
/// Permite que módulos registrem binds usando i.add(), i.addSingleton(), etc.
class Injector {
  final GetIt? _getIt;

  Injector() : _getIt = null;

  /// Cria um Injector a partir de um GetIt específico
  /// Usado para seguir o padrão do flutter_modular
  Injector.fromGetIt(GetIt getIt) : _getIt = getIt;

  /// Obtém uma instância registrada usando o sistema de resolução com contexto
  T get<T extends Object>({String? key}) {
    return InjectionManager.instance.getWithModuleContext<T>(key: key);
  }

  /// Registra uma factory (nova instância a cada get)
  /// Equivalente ao auto_injector.add()
  void add<T extends Object>(T Function() builder, {String? key}) {
    final getIt = _getIt ?? GetIt.instance;
    getIt.registerFactory<T>(builder, instanceName: key);
  }

  /// Registra um singleton (instância única criada imediatamente)
  /// IMPORTANTE: GetIt.registerSingleton recebe a instância direta, não factory
  /// Para manter compatibilidade, vamos usar registerLazySingleton que aceita factory
  void addSingleton<T extends Object>(T Function() builder, {String? key}) {
    final getIt = _getIt ?? GetIt.instance;
    // Usar registerLazySingleton para aceitar factory function
    getIt.registerLazySingleton<T>(builder, instanceName: key);
  }

  /// Registra um lazy singleton (instância única criada no primeiro get)
  void addLazySingleton<T extends Object>(T Function() builder, {String? key}) {
    final getIt = _getIt ?? GetIt.instance;
    getIt.registerLazySingleton<T>(builder, instanceName: key);
  }
}
