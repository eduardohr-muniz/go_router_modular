import 'dart:async';
import 'dart:developer';
import 'package:auto_injector/auto_injector.dart' as ai;
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/internal/setup.dart';
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
    if (_currentModuleContext != moduleType) {
      _currentModuleContext = moduleType;
    }
  }

  /// Limpa temporariamente o contexto do módulo (para callbacks globais como listen())
  void clearModuleContextTemporarily() {
    _currentModuleContext = null;
  }

  /// Retorna o contexto do módulo atual (ou null se não há contexto)
  Type? get currentModuleContext => _currentModuleContext;

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

  /// Obtém o injector do AppModule
  /// Usado para fallback quando um módulo não encontra um bind localmente
  ai.AutoInjector? getAppModuleInjector() {
    if (_appModule == null) return null;
    return _moduleInjectors[_appModule!.runtimeType];
  }

  // Sistema de fila sequencial para operações de módulos
  // Sistema de fila removido - causava Stack Overflow
  // A lógica de DI já funciona corretamente sem fila

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

    // ✅ IMPORTANTE: Se o módulo importado é o AppModule, usar o injector já registrado
    if (importedModule == _appModule && _moduleInjectors.containsKey(_appModule!.runtimeType)) {
      final appModuleInjector = _moduleInjectors[_appModule!.runtimeType]!;
      _importedInjectors[importTag] = appModuleInjector;
      return appModuleInjector;
    }

    // _createInjector já adiciona os binds (igual flutter_modular)
    final exportedInject = await _createInjector(importedModule, '${importTag}_Imported');
    _importedInjectors[importTag] = exportedInject;

    return exportedInject;
  }

  /// Cria um injector para o módulo seguindo o padrão do flutter_modular
  /// Referência: modular_core/lib/src/tracker.dart linha 275-284
  /// 
  /// ⚠️ IMPORTANTE: Igual ao flutter_modular - SEMPRE adiciona binds aqui!
  Future<ai.AutoInjector> _createInjector(Module module, String tag, {bool trackImports = false}) async {
    final newInjector = ai.AutoInjector(tag: tag);

    // Rastrear imports deste módulo (para validação de acesso)
    if (trackImports) {
      _moduleImports[module.runtimeType] = <Type>{};
    }

    // 1️⃣ Adicionar imports PRIMEIRO
    final imports = await module.imports();
    final importsList = await imports;
    
    for (var i = 0; i < importsList.length; i++) {
      final importedModule = importsList[i];
      final exportedInjector = await _createExportedInjector(importedModule);
      newInjector.addInjector(exportedInjector);

      if (trackImports) {
        _moduleImports[module.runtimeType]!.add(importedModule.runtimeType);
      }
    }

    // 🔑 CRÍTICO: Adicionar AppModule como sub-injector para que .new funcione!
    // Isso permite que AutoInjector resolva dependências globais automaticamente
    // quando usar construtores com .new (ex: EstablishmentApi.new)
    if (_appModule != null && module.runtimeType != _appModule!.runtimeType) {
      final appModuleInjector = _moduleInjectors[_appModule!.runtimeType];
      if (appModuleInjector != null) {
        newInjector.addInjector(appModuleInjector);
      }
    }

    // 2️⃣ SEMPRE adicionar binds aqui (igual flutter_modular linha 282)
    final bindsResult = module.binds(Injector.fromAutoInjector(newInjector));
    if (bindsResult is Future) {
      await bindsResult;
    }

    return newInjector;
  }

  Future<void> registerBindsModule(Module module) async {
    return await _registerBindsModuleInternal(module);
  }

  Future<void> _registerBindsModuleInternal(Module module) async {
    if (_moduleInjectors.containsKey(module.runtimeType)) {
      return;
    }

    // _createInjector já adiciona imports e binds (igual flutter_modular)
    final moduleTag = '${module.runtimeType}_${DateTime.now().millisecondsSinceEpoch}';
    final moduleInjector = await _createInjector(module, moduleTag, trackImports: true);

    // 🎯 SEGUINDO FLUTTER_MODULAR (tracker.dart linha 207-213):
    _injector.uncommit();
    _injector.addInjector(moduleInjector);
    _injector.commit();

    _moduleInjectors[module.runtimeType] = moduleInjector;
    _activeModuleTags[module.runtimeType] = moduleTag;

    // Inicializar estado do módulo
    module.initState(Injector.fromAutoInjector(moduleInjector));

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
    return _unregisterModuleInternal(module);
  }

  Future<void> _unregisterModuleInternal(Module module) async {
    module.dispose();
    await unregisterBinds(module);
  }

  /// Obtém instância do injector principal
  ai.AutoInjector get injector => _injector;

  /// Busca uma instância globalmente em todos os injectors registrados
  /// Útil quando o contexto atual não tem a dependência, mas outro módulo sim
  T? tryGetFromAllModules<T extends Object>({String? key}) {
    try {
      // Tentar no injector principal primeiro
      try {
        return _injector.get<T>(key: key);
      } catch (e) {
        // Continuar tentando outros módulos
      }

      // Tentar em todos os injectors de módulos
      for (final entry in _moduleInjectors.entries) {
        try {
          return entry.value.get<T>(key: key);
        } catch (e) {
          // Continuar tentando próximo módulo
        }
      }

      // Tentar em todos os injectors importados (cache)
      for (final entry in _importedInjectors.entries) {
        try {
          return entry.value.get<T>(key: key);
        } catch (e) {
          // Continuar tentando próximo
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

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
