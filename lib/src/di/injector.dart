import 'package:auto_injector/auto_injector.dart' as ai;
import 'package:go_router_modular/go_router_modular.dart';
import 'dart:developer' as dev;

class Injector {
  static bool enableInternalLogs = false;
  final ai.AutoInjector? _autoInjector;

  Injector() : _autoInjector = null;

  /// Cria um Injector a partir de um AutoInjector específico
  /// Usado para seguir o padrão do flutter_modular
  Injector.fromAutoInjector(ai.AutoInjector injector) : _autoInjector = injector;

  T get<T extends Object>({String? key}) {
    try {
      // Se temos um auto_injector específico (contexto de módulo), usar ele
      // Este injector já inclui os imports do módulo como sub-injectors
      if (_autoInjector != null) {
        if (enableInternalLogs) dev.log('🔍 [Injector.get] Buscando $T (key: $key) no módulo local', name: 'GO_ROUTER_MODULAR');
        
        try {
          final result = _autoInjector.get<T>(key: key);
          if (enableInternalLogs) dev.log('✅ [Injector.get] $T encontrado no módulo local', name: 'GO_ROUTER_MODULAR');
          return result;
        } catch (e) {
          if (enableInternalLogs) dev.log('❌ [Injector.get] $T NÃO encontrado no módulo local. Erro: $e', name: 'GO_ROUTER_MODULAR');
          
          // Tentar fallback para o AppModule se não encontrou no módulo e seus imports
          try {
            if (enableInternalLogs) dev.log('🔄 [Injector.get] Tentando fallback para AppModule...', name: 'GO_ROUTER_MODULAR');
            final appModuleInjector = InjectionManager.instance.getAppModuleInjector();
            if (appModuleInjector != null) {
              if (enableInternalLogs) dev.log('🔍 [Injector.get] AppModuleInjector encontrado', name: 'GO_ROUTER_MODULAR');
              final result = appModuleInjector.get<T>(key: key);
              if (enableInternalLogs) dev.log('✅ [Injector.get] $T encontrado no AppModule!', name: 'GO_ROUTER_MODULAR');
              return result;
            } else {
              if (enableInternalLogs) dev.log('⚠️ [Injector.get] AppModuleInjector é NULL!', name: 'GO_ROUTER_MODULAR');
            }
            rethrow;
          } catch (e2) {
            if (enableInternalLogs) dev.log('❌ [Injector.get] $T também NÃO encontrado no AppModule. Erro: $e2', name: 'GO_ROUTER_MODULAR');
            rethrow;
          }
        }
      }

      // Caso contrário, usar o injector contextual (módulo atual ou AppModule)
      if (enableInternalLogs) dev.log('🔍 [Injector.get] Usando injector contextual para $T', name: 'GO_ROUTER_MODULAR');
      final contextualInjector = InjectionManager.instance.getContextualInjector();
      try {
        final result = contextualInjector.get<T>(key: key);
        if (enableInternalLogs) dev.log('✅ [Injector.get] $T encontrado no injector contextual', name: 'GO_ROUTER_MODULAR');
        return result;
      } catch (e) {
        if (enableInternalLogs) dev.log('❌ [Injector.get] $T NÃO encontrado no injector contextual. Erro: $e', name: 'GO_ROUTER_MODULAR');
        rethrow;
      }
    } catch (e) {
      if (enableInternalLogs) dev.log('🔄 [Injector.get] Fallback final para Bind.get<$T>', name: 'GO_ROUTER_MODULAR');
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
