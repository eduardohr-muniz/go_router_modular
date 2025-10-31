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
      // Se temos um auto_injector específico (contexto de módulo), usar ele
      // Este injector já inclui os imports do módulo como sub-injectors
      if (_autoInjector != null) {
        try {
          final result = _autoInjector.get<T>(key: key);
          return result;
        } catch (e) {
          // Tentar fallback para o AppModule se não encontrou no módulo e seus imports
          try {
            final appModuleInjector = InjectionManager.instance.getAppModuleInjector();
            if (appModuleInjector != null) {
              final result = appModuleInjector.get<T>(key: key);
              return result;
            }
            rethrow;
          } catch (e2) {
            rethrow;
          }
        }
      }

      // Caso contrário, usar o injector contextual (módulo atual ou AppModule)
      final contextualInjector = InjectionManager.instance.getContextualInjector();
      try {
        return contextualInjector.get<T>(key: key);
      } catch (e) {
        rethrow;
      }
    } catch (e) {
      return Bind.get<T>(key: key); // Fallback to old system if needed
    }
  }

  /// Métodos para registrar binds diretamente (padrão flutter_modular)
  /// Aceita tanto Function (MyClass.new) quanto T Function()
  void add<T>(Function constructor, {String? key}) {
    if (_autoInjector != null) {
      _autoInjector.add<T>(constructor, key: key);
    }
  }

  void addSingleton<T>(Function constructor, {String? key}) {
    if (_autoInjector != null) {
      _autoInjector.addSingleton<T>(constructor, key: key);
    }
  }

  void addLazySingleton<T>(Function constructor, {String? key}) {
    if (_autoInjector != null) {
      _autoInjector.addLazySingleton<T>(constructor, key: key);
    }
  }
}
