import 'dart:developer';

import 'package:auto_injector/auto_injector.dart' as ai;
import 'package:go_router_modular/go_router_modular.dart';

import 'package:go_router_modular/src/internal/internal_logs.dart';

class Injector {
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
        iLog('🔍 [Injector.get] Buscando $T (key: $key) no módulo local', name: 'GO_ROUTER_MODULAR');

        try {
          final result = _autoInjector.get<T>(key: key);
          iLog('✅ [Injector.get] $T encontrado no módulo local', name: 'GO_ROUTER_MODULAR');
          return result;
        } catch (e) {
          iLog('❌ [Injector.get] $T NÃO encontrado no módulo local. Erro: $e', name: 'GO_ROUTER_MODULAR');

          // Tentar fallback para o AppModule se não encontrou no módulo e seus imports
          try {
            iLog('🔄 [Injector.get] Tentando fallback para AppModule...', name: 'GO_ROUTER_MODULAR');
            final appModuleInjector = InjectionManager.instance.getAppModuleInjector();
            if (appModuleInjector != null) {
              iLog('🔍 [Injector.get] AppModuleInjector encontrado', name: 'GO_ROUTER_MODULAR');
              final result = appModuleInjector.get<T>(key: key);
              iLog('✅ [Injector.get] $T encontrado no AppModule!', name: 'GO_ROUTER_MODULAR');
              return result;
            } else {
              iLog('⚠️ [Injector.get] AppModuleInjector é NULL!', name: 'GO_ROUTER_MODULAR');
            }
            rethrow;
          } catch (e2) {
            iLog('❌ [Injector.get] $T também NÃO encontrado no AppModule. Erro: $e2', name: 'GO_ROUTER_MODULAR');
            if (e2 is ai.UnregisteredInstance) {
              final classNames = e2.classNames;
              final classNameError = classNames.last;
              final coloredClassName = '\x1B[32m$classNameError\x1B[0m'; // green
              log(
                '❌ Bind not found: $coloredClassName\n'
                '📍 Make sure to register it in the module binds() method:\n'
                '⛓ Dependency chain: ${classNames.join(' -> ')}'
                '   ⚠️  IMPORTANT: Always use explicit typing!\n'
                '   ✅ i.add<$coloredClassName>($classNameError.new);\n'
                '   or\n'
                '   ✅ i.add<$coloredClassName>(() => $classNameError());\n'
                '\n'
                '   ❌ DO NOT: i.add(() => $classNameError()); // Missing type!',
                name: 'GO_ROUTER_MODULAR',
              );

              // Converte para GoRouterModularException (mantendo compatibilidade dos testes)
              final msg = '❌ Bind not found for type ' + classNameError + '\nInner error: ' + e.toString();
              throw GoRouterModularException(msg);
            }
            rethrow;
          }
        }
      }

      // Caso contrário, usar o injector contextual (módulo atual ou AppModule)
      iLog('🔍 [Injector.get] Usando injector contextual para $T', name: 'GO_ROUTER_MODULAR');
      final contextualInjector = InjectionManager.instance.getContextualInjector();
      try {
        final result = contextualInjector.get<T>(key: key);
        iLog('✅ [Injector.get] $T encontrado no injector contextual', name: 'GO_ROUTER_MODULAR');
        return result;
      } catch (e) {
        iLog('❌ [Injector.get] $T NÃO encontrado no injector contextual. Erro: $e', name: 'GO_ROUTER_MODULAR');
        rethrow;
      }
    } catch (e) {
      iLog('🔄 [Injector.get] Fallback final para Bind.get<$T>', name: 'GO_ROUTER_MODULAR');
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
