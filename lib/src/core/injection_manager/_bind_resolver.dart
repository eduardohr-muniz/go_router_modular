import 'dart:developer';
import 'package:auto_injector/auto_injector.dart';
import 'package:go_router_modular/src/core/injection_manager/_module_registry.dart';
import 'package:go_router_modular/src/core/injection_manager/injection_manager.dart';

/// Resolve binds com isolamento de módulos
/// Cada módulo só pode acessar:
/// 1. Seus próprios binds
/// 2. Binds dos módulos importados (via imports)
/// 3. Binds do AppModule (sempre disponível)
class BindResolver {
  final AutoInjector _autoInjector;
  final ModuleRegistry _registry;

  BindResolver(this._autoInjector, this._registry);

  T resolve<T extends Object>({String? key}) {
    final currentContext = _registry.currentContext;
    log('🔍 [BindResolver.resolve] Tipo: ${T.toString()}${key != null ? ' key: $key' : ''}', name: "GO_ROUTER_MODULAR");
    log('🔍 [BindResolver.resolve] Contexto: ${currentContext?.toString() ?? "null"}', name: "GO_ROUTER_MODULAR");

    // Se não há contexto definido, tentar resolver no AppModule
    if (currentContext == null) {
      log('🔍 [BindResolver] Sem contexto, tentando AppModule', name: "GO_ROUTER_MODULAR");
      try {
        final result = _autoInjector.get<T>(key: key);
        log('✅ [BindResolver] Encontrado no AppModule (sem contexto)', name: "GO_ROUTER_MODULAR");
        return result;
      } catch (e) {
        log('❌ [BindResolver] Erro no AppModule (sem contexto): $e', name: "GO_ROUTER_MODULAR");
        throw Exception('Bind not found for type: ${T.toString()}${key != null ? ' with key: $key' : ''}');
      }
    }

    // Se o contexto é o AppModule, resolver no injector principal
    if (currentContext == _registry.appModule?.runtimeType) {
      log('🔍 [BindResolver] Contexto é AppModule', name: "GO_ROUTER_MODULAR");
      try {
        final result = _autoInjector.get<T>(key: key);
        log('✅ [BindResolver] Encontrado no AppModule', name: "GO_ROUTER_MODULAR");
        return result;
      } catch (e) {
        log('❌ [BindResolver] Erro no AppModule: $e', name: "GO_ROUTER_MODULAR");
        throw Exception('Bind not found for type: ${T.toString()}${key != null ? ' with key: $key' : ''}');
      }
    }

    // Buscar o injector do módulo atual
    final moduleInjector = _getModuleInjector(currentContext);
    log('🔍 [BindResolver] Injector do módulo: ${moduleInjector != null ? moduleInjector.toString() : "null"}', name: "GO_ROUTER_MODULAR");

    if (moduleInjector != null) {
      try {
        log('🔍 [BindResolver] Tentando resolver no injector do módulo...', name: "GO_ROUTER_MODULAR");
        // Tentar resolver no injector do módulo atual (que inclui seus próprios binds e imports)
        final result = moduleInjector.get<T>(key: key);
        log('✅ [BindResolver] Encontrado no injector do módulo', name: "GO_ROUTER_MODULAR");
        return result;
      } catch (e) {
        log('❌ [BindResolver] Não encontrado no injector do módulo: $e', name: "GO_ROUTER_MODULAR");
        // Não encontrou no módulo atual ou nos imports
        // TENTAR NO APPMODULE GLOBAL (sempre disponível)
        if (_registry.appModule != null) {
          try {
            log('🔍 [BindResolver] Tentando AppModule como fallback...', name: "GO_ROUTER_MODULAR");
            final result = _autoInjector.get<T>(key: key);
            log('✅ [BindResolver] Encontrado no AppModule (fallback)', name: "GO_ROUTER_MODULAR");
            return result;
          } catch (e2) {
            log('❌ [BindResolver] Erro no AppModule (fallback): $e2', name: "GO_ROUTER_MODULAR");
            throw Exception('Bind not found for type: ${T.toString()}${key != null ? ' with key: $key' : ''}');
          }
        }
        log('❌ [BindResolver] Sem AppModule, lançando exceção', name: "GO_ROUTER_MODULAR");
        throw Exception('Bind not found for type: ${T.toString()}${key != null ? ' with key: $key' : ''}');
      }
    }

    // Se não conseguiu encontrar o injector do módulo, tentar no injector principal
    // (fallback para casos onde o moduleInjector é null)
    if (_registry.appModule != null) {
      try {
        return _autoInjector.get<T>(key: key);
      } catch (e) {
        throw Exception('Bind not found for type: ${T.toString()}${key != null ? ' with key: $key' : ''}');
      }
    }

    throw Exception('Bind not found for type: ${T.toString()}${key != null ? ' with key: $key' : ''}');
  }

  /// Obtém o injector de um módulo específico
  AutoInjector? _getModuleInjector(Type moduleType) {
    // Buscar o injector do módulo no mapa de injectors
    try {
      final moduleInjectors = InjectionManager.instance.moduleInjectors;
      return moduleInjectors[moduleType];
    } catch (e) {
      return null;
    }
  }
}
