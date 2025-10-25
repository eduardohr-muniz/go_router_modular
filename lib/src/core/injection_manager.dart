import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'package:auto_injector/auto_injector.dart' as ai;
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/internal/setup.dart';
import 'package:go_router_modular/src/internal/internal_logs.dart';
import 'package:go_router_modular/src/di/clean_bind.dart';

/// ValueObject para representar um bind único (Type + Key)

class InjectionManager {
  static InjectionManager? _instance;
  InjectionManager._() {
    // IMPORTANTE: Seguir o padrão do flutter_modular
    // O injector principal deve ser committed imediatamente após criação
    _injector.commit();
  }
  static InjectionManager get instance => _instance ??= InjectionManager._();

  /// Main AutoInjector instance - similar to flutter_modular's approach
  ai.AutoInjector _injector = ai.AutoInjector();

  /// Module-specific injectors tracked by module type
  final Map<Type, ai.AutoInjector> _moduleInjectors = {};

  /// Store which modules are currently active
  final Map<Type, String> _activeModuleTags = {};

  Module? _appModule;

  bool get debugLog => SetupModular.instance.debugLogGoRouterModular;

  // Sistema de fila sequencial para operações de módulos
  final Queue<Future<void> Function()> _operationQueue = Queue<Future<void> Function()>();
  bool _isProcessingQueue = false;

  // Processa operações na fila sequencialmente
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

  // Adiciona operação à fila e garante processamento sequencial
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
    if (_appModule != null) {
      return;
    }
    _appModule = module;
    await registerBindsModule(module);
  }

  /// Coleta recursivamente todos os binds de imports aninhados
  /// Cria um injector para o módulo seguindo o padrão do flutter_modular
  /// Referência: modular_core/lib/src/tracker.dart linha 275-284
  ai.AutoInjector _createInjector(Module module, String tag) {
    final newInjector = ai.AutoInjector(tag: tag);

    // Adicionar injectors dos módulos importados primeiro
    final imports = module.imports();
    final importsList = imports is Future ? <Module>[] : imports;

    for (final importedModule in importsList) {
      final importTag = '${importedModule.runtimeType}_Imported';
      final exportedInjector = _createInjector(importedModule, importTag);
      newInjector.addInjector(exportedInjector);
    }

    // Chamar module.binds() passando o injector diretamente
    // O módulo registra seus binds usando i.add(), i.addSingleton(), etc
    module.binds(Injector.fromAutoInjector(newInjector));

    // Inicializar estado do módulo
    module.initState(Injector.fromAutoInjector(newInjector));

    return newInjector;
  }

  Future<void> registerBindsModule(Module module) async {
    return _enqueueOperation(() => _registerBindsModuleInternal(module));
  }

  Future<void> _registerBindsModuleInternal(Module module) async {
    if (_moduleInjectors.containsKey(module.runtimeType)) {
      return;
    }

    // Criar injector para o módulo seguindo o padrão do flutter_modular
    final moduleTag = '${module.runtimeType}_${DateTime.now().millisecondsSinceEpoch}';
    final moduleInjector = _createInjector(module, moduleTag);

    _moduleInjectors[module.runtimeType] = moduleInjector;
    _activeModuleTags[module.runtimeType] = moduleTag;

    // Seguir exatamente o padrão do flutter_modular (linha 210-212):
    // 1. uncommit() antes de adicionar novos injectors
    // 2. addInjector()
    // 3. commit() após adicionar todos os injectors
    _injector.uncommit();
    _injector.addInjector(moduleInjector);
    _injector.commit();

    if (debugLog) {
      log('💉 INJECTED 🧩 MODULE: ${module.runtimeType}', name: "GO_ROUTER_MODULAR");
    }
  }

  Future<void> unregisterBinds(Module module) async {
    // App module nunca é desregistrado
    if (_appModule != null && module == _appModule!) {
      return;
    }

    final moduleType = module.runtimeType;
    final moduleInjector = _moduleInjectors[moduleType];

    if (moduleInjector != null && _activeModuleTags.containsKey(moduleType)) {
      final tag = _activeModuleTags[moduleType]!;

      // Dispose do injector do módulo
      _injector.disposeInjectorByTag(tag, (instance) {
        // Chama dispose se implementar Disposable
        if (instance is Disposable) {
          instance.dispose();
        }
      });

      _moduleInjectors.remove(moduleType);
      _activeModuleTags.remove(moduleType);

      if (debugLog) {
        log('🗑️ DISPOSED 🧩 MODULE: ${module.runtimeType}', name: "GO_ROUTER_MODULAR");
      }
    }
  }

  Future<void> unregisterModule(Module module) async {
    if (module.runtimeType == _appModule?.runtimeType) return;
    return _enqueueOperation(() => _unregisterModuleInternal(module));
  }

  Future<void> _unregisterModuleInternal(Module module) async {
    module.dispose();
    await unregisterBinds(module);
  }

  /// Obtém instância do injector principal
  ai.AutoInjector get injector => _injector;

  /// Clear all binds for testing purposes
  void clearAllForTesting() {
    try {
      // Limpar mapas de módulos primeiro
      _moduleInjectors.clear();
      _activeModuleTags.clear();

      // Resetar o app module
      _appModule = null;

      // Criar um novo injector principal para limpeza completa
      _injector = ai.AutoInjector();
      // IMPORTANTE: Commitar o novo injector imediatamente
      _injector.commit();

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
