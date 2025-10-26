import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'package:get_it/get_it.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/internal/setup.dart';
import 'package:go_router_modular/src/di/clean_bind.dart';
import '_module_registry.dart';
import '_bind_resolver.dart';
import '_module_injector.dart';

/// InjectionManager usando GetIt com isolamento via prefixos de módulo
///
/// Estratégia de Isolamento:
/// - AppModule: binds sem prefixo (globais)
/// - Outros módulos: binds com prefixo "ModuleName_"
/// - Resolução: tenta com prefixo do módulo atual, depois sem prefixo (AppModule)
/// - Imports: módulos importados têm seus prefixos adicionados à lista de busca
class InjectionManager {
  static InjectionManager? _instance;
  InjectionManager._();
  static InjectionManager get instance => _instance ??= InjectionManager._();

  /// GetIt instance singleton
  final GetIt _getIt = GetIt.instance;

  /// Registry para rastrear módulos
  final ModuleRegistry _registry = ModuleRegistry();

  /// Resolver para binds
  late final BindResolver _resolver = BindResolver(_getIt, _registry);

  bool get debugLog => SetupModular.instance.debugLogGoRouterModular;

  /// Define o contexto do módulo atual (chamado ao navegar para uma rota)
  void setModuleContext(Type moduleType) {
    _registry.setContext(moduleType);
  }

  /// Obtém uma instância tentando diferentes contextos (módulo atual, imports, AppModule)
  T getWithModuleContext<T extends Object>({String? key}) {
    return _resolver.resolve<T>(key: key);
  }

  /// Obtém o GetIt principal
  GetIt getContextualInjector() {
    return _getIt;
  }

  // Sistema de fila sequencial para operações de módulos
  final Queue<Future<void> Function()> _operationQueue = Queue<Future<void> Function()>();
  bool _isProcessingQueue = false;

  Future<void> _processQueue() async {
    if (_isProcessingQueue || _operationQueue.isEmpty) {
      return;
    }

    _isProcessingQueue = true;

    try {
      while (_operationQueue.isNotEmpty) {
        final operation = _operationQueue.removeFirst();
        await operation();
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  Future<T> _enqueueOperation<T>(Future<T> Function() operation) async {
    final completer = Completer<T>();

    _operationQueue.add(() async {
      try {
        final result = await operation();
        completer.complete(result);
      } catch (e) {
        completer.completeError(e);
      }
    });

    _processQueue();

    return completer.future;
  }

  Future<void> registerAppModule(Module module) async {
    if (_registry.appModule != null) {
      return;
    }
    _registry.setAppModule(module);
    await registerBindsModule(module);
  }

  Future<void> registerBindsModule(Module module) async {
    return _enqueueOperation(() => _registerBindsModuleInternal(module));
  }

  Future<void> _registerBindsModuleInternal(Module module) async {
    if (_registry.isActive(module.runtimeType)) {
      return;
    }

    _registry.registerModule(module.runtimeType);

    final imports = module.imports();
    final importsList = imports is Future ? <Module>[] : imports;

    for (final importedModule in importsList) {
      _registry.addImport(module.runtimeType, importedModule.runtimeType);

      // Registrar módulo importado se ainda não foi registrado
      if (!_registry.isActive(importedModule.runtimeType)) {
        await _registerBindsModuleInternal(importedModule);
      }
    }

    // Criar um Injector com contexto do módulo
    final modulePrefix = module == _registry.appModule ? null : _registry.getPrefix(module.runtimeType);
    final injector = ModuleInjector(_getIt, modulePrefix, module.runtimeType, _registry);

    // Chamar module.binds() passando o injector com contexto
    module.binds(injector);

    // Inicializar estado do módulo
    module.initState(injector);

    if (debugLog) {
      log('💉 INJECTED 🧩 MODULE: ${module.runtimeType}', name: "GO_ROUTER_MODULAR");
    }
  }

  Future<void> unregisterBinds(Module module) async {
    return _enqueueOperation(() => _unregisterModuleInternal(module));
  }

  Future<void> unregisterModule(Module module) async {
    return _enqueueOperation(() => _unregisterModuleInternal(module));
  }

  Future<void> _unregisterModuleInternal(Module module) async {
    if (!_registry.isActive(module.runtimeType)) {
      return;
    }

    try {
      // Para binds com instanceName, podemos tentar resetLazySingleton
      final binds = _registry.getBinds(module.runtimeType);
      for (final bind in binds) {
        try {
          if (bind.instanceName != null) {
            // Tentar resetLazySingleton para limpar a instância
            try {
              await _getIt.resetLazySingleton(
                instanceName: bind.instanceName,
                disposingFunction: (instance) {
                  CleanBind.fromInstance(instance);
                },
              );
            } catch (_) {
              // Se não for lazy singleton, ignorar
            }
          }
        } catch (e) {
          // Ignorar erros individuais
          if (debugLog) {
            log('⚠️ Failed to reset bind ${bind.type}: $e', name: "GO_ROUTER_MODULAR");
          }
        }
      }

      // Chamar dispose do módulo
      module.dispose();

      // Remover rastreamento
      _registry.unregisterModule(module.runtimeType);

      if (debugLog) {
        log('🗑️ DISPOSED 🧩 MODULE: ${module.runtimeType}', name: "GO_ROUTER_MODULAR");
      }
    } catch (e) {
      if (debugLog) {
        log('⚠️ Failed to unregister module ${module.runtimeType}: $e', name: "GO_ROUTER_MODULAR");
      }
    }
  }

  /// Obtém instância do GetIt principal
  GetIt get injector => _getIt;

  /// Clear all binds for testing purposes
  Future<void> clearAllForTesting() async {
    try {
      // Reset GetIt completamente (é assíncrono!)
      await _getIt.reset(dispose: true);

      // Limpar registry
      _registry.clear();

      if (debugLog) {
        log('🧹 Cleared all injectors for testing', name: "GO_ROUTER_MODULAR");
      }
    } catch (e) {
      if (debugLog) {
        log('⚠️ Failed to clear injectors: $e', name: "GO_ROUTER_MODULAR");
      }
    }
  }
}
