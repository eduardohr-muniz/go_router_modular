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

  /// Cache de injectors importados (seguindo flutter_modular linha 59)
  final Map<String, ai.AutoInjector> _importedInjectors = {};

  /// Rastrear quais módulos cada módulo importa (para validação de acesso)
  final Map<Type, Set<Type>> _moduleImports = {};

  /// Módulo ativo no contexto atual (para resolução de binds)
  Type? _currentModuleContext;

  Module? _appModule;

  bool get debugLog => SetupModular.instance.debugLogGoRouterModular;

  /// Define o contexto do módulo atual (chamado ao navegar para uma rota)
  void setModuleContext(Type moduleType) {
    _currentModuleContext = moduleType;
  }

  /// Obtém o injector correto baseado no contexto do módulo atual
  /// Retorna o injector do módulo atual (que inclui seus imports) ou o injector principal (AppModule)
  ai.AutoInjector getContextualInjector() {
    // Se temos um contexto de módulo específico, usar o injector desse módulo
    if (_currentModuleContext != null && _moduleInjectors.containsKey(_currentModuleContext)) {
      return _moduleInjectors[_currentModuleContext]!;
    }

    // Fallback para o injector principal (AppModule)
    return _injector;
  }

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

  /// Cria um injector exportado para módulos importados (com cache)
  /// Referência: flutter_modular linha 261-273
  Future<ai.AutoInjector> _createExportedInjector(Module importedModule) async {
    final importTag = importedModule.runtimeType.toString();

    if (_importedInjectors.containsKey(importTag)) {
      return _importedInjectors[importTag]!;
    }

    final exportedInject = await _createInjector(importedModule, '${importTag}_Imported');
    _importedInjectors[importTag] = exportedInject;

    return exportedInject;
  }

  /// Cria um injector para o módulo seguindo o padrão do flutter_modular
  /// Referência: modular_core/lib/src/tracker.dart linha 275-284
  Future<ai.AutoInjector> _createInjector(Module module, String tag, {bool trackImports = false}) async {
    final newInjector = ai.AutoInjector(tag: tag);

    // Rastrear imports deste módulo (para validação de acesso)
    if (trackImports) {
      _moduleImports[module.runtimeType] = <Type>{};
    }

    // Adicionar injectors dos módulos importados primeiro
    final imports = await module.imports();
    final importsList = imports is List ? imports : <Module>[];

    for (final importedModule in importsList) {
      // Usar injector exportado com cache
      final exportedInjector = await _createExportedInjector(importedModule);
      newInjector.addInjector(exportedInjector);

      // Rastrear que este módulo importa o módulo importado
      if (trackImports) {
        _moduleImports[module.runtimeType]!.add(importedModule.runtimeType);
      }
    }

    // Chamar module.binds() passando o injector diretamente
    // O módulo registra seus binds usando i.add(), i.addSingleton(), etc
    module.binds(Injector.fromAutoInjector(newInjector));

    // IMPORTANTE: Commitar o injector após registrar todos os binds
    // Isso permite que os binds sejam resolvidos corretamente
    newInjector.commit();

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
    final moduleInjector = await _createInjector(module, moduleTag, trackImports: true);

    _moduleInjectors[module.runtimeType] = moduleInjector;
    _activeModuleTags[module.runtimeType] = moduleTag;

    // IMPORTANTE: Apenas adicionar ao injector principal se for AppModule
    // Outros módulos ficam isolados em seus próprios injectors
    if (module == _appModule) {
      _injector.uncommit();
      _injector.addInjector(moduleInjector);
      _injector.commit();
    }

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
      // IMPORTANTE: Chamar dispose() antes de limpar para fazer cleanup das instâncias
      // Usar callback para chamar CleanBind.fromInstance em cada instância
      try {
        _injector.dispose((instance) {
          CleanBind.fromInstance(instance);
        });
      } catch (e) {
        // Ignorar erros de dispose - pode não ter instâncias
      }

      // Limpar injectors de módulos
      for (final moduleInjector in _moduleInjectors.values) {
        try {
          moduleInjector.dispose((instance) {
            CleanBind.fromInstance(instance);
          });
        } catch (e) {
          // Ignorar erros
        }
      }

      // Limpar injectors importados
      for (final importedInjector in _importedInjectors.values) {
        try {
          importedInjector.dispose((instance) {
            CleanBind.fromInstance(instance);
          });
        } catch (e) {
          // Ignorar erros
        }
      }

      // Limpar mapas de módulos
      _moduleInjectors.clear();
      _activeModuleTags.clear();
      _importedInjectors.clear();
      _moduleImports.clear();

      // Resetar contexto e app module
      _currentModuleContext = null;
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
