import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'package:auto_injector/auto_injector.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/internal/setup.dart';
import 'package:go_router_modular/src/di/clean_bind.dart';
import '_module_registry.dart';
import '_bind_resolver.dart';
import '_module_injector.dart';

/// InjectionManager usando AutoInjector com isolamento via prefixos de módulo
///
/// Estratégia de Isolamento:
/// - AppModule: binds sem prefixo (globais)
/// - Outros módulos: binds com prefixo "ModuleName_"
/// - Resolução: tenta com prefixo do módulo atual, depois sem prefixo (AppModule)
/// - Imports: módulos importados têm seus prefixos adicionados à lista de busca
/// - AutoInjector: resolve interfaces automaticamente! 🎉
class InjectionManager {
  static InjectionManager? _instance;
  InjectionManager._();
  static InjectionManager get instance => _instance ??= InjectionManager._();

  /// AutoInjector instance singleton
  final AutoInjector _autoInjector = AutoInjector(
    tag: 'go_router_modular_main',
  );

  /// Registry para rastrear módulos
  final ModuleRegistry _registry = ModuleRegistry();

  /// Resolver para binds
  late final BindResolver _resolver = BindResolver(_autoInjector, _registry);

  bool get debugLog => SetupModular.instance.debugLogGoRouterModular;

  /// Define o contexto do módulo atual (chamado ao navegar para uma rota)
  void setModuleContext(Type moduleType) {
    _registry.setContext(moduleType);
  }

  /// Obtém uma instância tentando diferentes contextos (módulo atual, imports, AppModule)
  T getWithModuleContext<T extends Object>({String? key}) {
    return _resolver.resolve<T>(key: key);
  }

  /// Obtém o AutoInjector principal
  AutoInjector getContextualInjector() {
    return _autoInjector;
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

    // SEGUINDO O PADRÃO DO FLUTTER_MODULAR (tracker.dart linhas 207-213):
    // 1. Criar injector para o módulo
    final moduleInjector = _createModuleInjector(module);

    // 2. Adicionar ao mapa de injectors ANTES de commitar
    _moduleInjectors[module.runtimeType] = moduleInjector;

    // 3. Uncommit → addInjector → commit (padrão flutter_modular)
    _autoInjector.uncommit();
    _autoInjector.addInjector(moduleInjector);
    _autoInjector.commit();

    // Inicializar estado do módulo
    final moduleInjectorWrapper = ModuleInjector(moduleInjector);
    module.initState(moduleInjectorWrapper);

    if (debugLog) {
      log('💉 INJECTED: ${module.runtimeType}', name: "GO_ROUTER_MODULAR");
    }
  }

  /// Cria um AutoInjector para um módulo (seguindo padrão flutter_modular - tracker.dart linha 275)
  AutoInjector _createModuleInjector(Module module) {
    // Criar um novo AutoInjector para este módulo (sem commit ainda!)
    final moduleInjector = AutoInjector(tag: module.runtimeType.toString());

    // Processar imports do módulo
    final imports = module.imports();
    final importsList = imports is Future ? <Module>[] : imports;

    for (final importedModule in importsList) {
      _registry.addImport(module.runtimeType, importedModule.runtimeType);

      // Criar ou reusar o injector do módulo importado
      final importedInjector = _getOrCreateModuleInjector(importedModule);

      // Adicionar o injector importado ao injector do módulo atual
      moduleInjector.addInjector(importedInjector);
    }

    // IMPORTANTE: NÃO auto-importar o AppModule
    // Cada módulo só tem acesso aos seus próprios binds e aos binds importados explicitamente
    // Para usar o AppModule, o módulo precisa importá-lo explicitamente

    // Criar um wrapper Injector e chamar module.binds() (SEGUINDO PADRÃO FLUTTER_MODULAR linha 282)
    final injectorWrapper = ModuleInjector(moduleInjector);
    module.binds(injectorWrapper);

    return moduleInjector;
  }

  /// Mapa para armazenar os injectors dos módulos
  final Map<Type, AutoInjector> _moduleInjectors = {};

  /// Getter público para acessar o mapa de injectors
  Map<Type, AutoInjector> get moduleInjectors => _moduleInjectors;

  /// Obtém ou cria o injector de um módulo
  AutoInjector _getOrCreateModuleInjector(Module module) {
    if (_moduleInjectors.containsKey(module.runtimeType)) {
      return _moduleInjectors[module.runtimeType]!;
    }

    final injector = _createModuleInjector(module);
    _moduleInjectors[module.runtimeType] = injector;

    return injector;
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
      if (debugLog) {
        log('🗑️ DISPOSING: ${module.runtimeType}', name: "GO_ROUTER_MODULAR");
      }

      // Chamar dispose do módulo
      module.dispose();

      // SEGUINDO O PADRÃO DO FLUTTER_MODULAR:
      // Dispose do injector do módulo usando disposeInjectorByTag
      final moduleTag = module.runtimeType.toString();
      _autoInjector.disposeInjectorByTag(moduleTag, (instance) {
        CleanBind.fromInstance(instance);
      });

      // Remover do mapa de injectors
      _moduleInjectors.remove(module.runtimeType);

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

  /// Obtém instância do AutoInjector principal
  AutoInjector get injector => _autoInjector;

  /// Clear all binds for testing purposes
  Future<void> clearAllForTesting() async {
    try {
      // Uncommit antes de dispose (necesário para o AutoInjector)
      _autoInjector.uncommit();

      // Dispose all instances
      _autoInjector.dispose((instance) {
        CleanBind.fromInstance(instance);
      });

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
