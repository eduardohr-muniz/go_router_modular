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
      print('🎯 Contexto do módulo alterado: $_currentModuleContext → $moduleType');
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
    print('🔍 [getContextualInjector] Contexto atual: $_currentModuleContext');
    print('   Injectors disponíveis: ${_moduleInjectors.keys.join(", ")}');

    // Se temos um contexto de módulo específico, usar o injector desse módulo
    if (_currentModuleContext != null && _moduleInjectors.containsKey(_currentModuleContext)) {
      print('   ✅ Retornando injector de $_currentModuleContext');
      return _moduleInjectors[_currentModuleContext]!;
    }

    // Fallback para o injector principal (AppModule)
    print('   ⚠️  Fallback para injector principal (AppModule)');
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

    final exportedInject = await _createInjector(importedModule, '${importTag}_Imported');
    _importedInjectors[importTag] = exportedInject;

    return exportedInject;
  }

  /// Cria um injector para o módulo seguindo o padrão do flutter_modular
  /// Referência: modular_core/lib/src/tracker.dart linha 275-284
  Future<ai.AutoInjector> _createInjector(Module module, String tag, {bool trackImports = false}) async {
    print('');
    print('═══════════════════════════════════════════════════════════════');
    print('🔧 [_createInjector] INÍCIO para: ${module.runtimeType}');
    print('═══════════════════════════════════════════════════════════════');

    final newInjector = ai.AutoInjector(tag: tag);
    print('✅ Injector criado: tag="$tag"');

    // Rastrear imports deste módulo (para validação de acesso)
    if (trackImports) {
      _moduleImports[module.runtimeType] = <Type>{};
    }

    // SOLUÇÃO UNIVERSAL: Registrar binds ANTES de processar imports
    // Isso funciona para TODOS os módulos (AppModule e módulos normais)
    final isAppModule = module == _appModule;

    print('');
    if (isAppModule) {
      print('🎯 DETECTADO: Este é o AppModule!');
    } else {
      print('🎯 Módulo: ${module.runtimeType}');
    }
    print('🔧 SOLUÇÃO: Registrando binds ANTES de processar imports');
    print('   (Isso garante que imports possam usar binds do módulo pai)');
    print('');

    // Registrar binds do módulo PRIMEIRO
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📝 CHAMANDO ${module.runtimeType}.binds() ANTES DOS IMPORTS');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final bindsResult = module.binds(Injector.fromAutoInjector(newInjector));
    if (bindsResult is Future) {
      print('⏳ Aguardando binds assíncronos de ${module.runtimeType}...');
      await bindsResult;
    }
    print('✅ ${module.runtimeType}.binds() CONCLUÍDO');
    print('');

    // Commitar ANTES de processar imports para que o módulo esteja disponível
    print('📌 Commitando injector de ${module.runtimeType} ANTES de processar imports...');
    print('   ℹ️  Binds assíncronos concluídos, injector pronto');
    try {
      newInjector.commit();
      print('🔒 ${module.runtimeType} injector commitado com sucesso');
    } catch (e) {
      print('⚠️  Erro ao commitar: $e');
    }
    print('');

    // 🎯 CRÍTICO: Adicionar ao mapa ANTES de processar imports
    // Para que imports possam fazer fallback ao AppModule
    _moduleInjectors[module.runtimeType] = newInjector;
    if (isAppModule) {
      print('💾 AppModule adicionado ao mapa de injectors ANTES dos imports');
    } else {
      print('💾 ${module.runtimeType} adicionado ao mapa de injectors ANTES dos imports');
    }
    print('   Mapa de injectors atualizado: ${_moduleInjectors.keys.join(", ")}');
    print('');

    // Adicionar injectors dos módulos importados
    print('');
    print('📥 PROCESSANDO IMPORTS de ${module.runtimeType}:');
    final imports = await module.imports();
    final importsList = await imports;
    print('   Quantidade de imports: ${importsList.length}');
    if (importsList.isNotEmpty) {
      print('   Imports: ${importsList.map((m) => m.runtimeType.toString()).join(", ")}');
    }

    for (var i = 0; i < importsList.length; i++) {
      final importedModule = importsList[i];
      print('');
      print('   ┌─────────────────────────────────────────────────────────');
      print('   │ 📦 Processando import ${i + 1}/${importsList.length}: ${importedModule.runtimeType}');
      print('   └─────────────────────────────────────────────────────────');

      // Usar injector exportado com cache
      final exportedInjector = await _createExportedInjector(importedModule);
      newInjector.addInjector(exportedInjector);
      print('   ✅ Import ${importedModule.runtimeType} ADICIONADO ao injector de ${module.runtimeType}');

      // Rastrear que este módulo importa o módulo importado
      if (trackImports) {
        _moduleImports[module.runtimeType]!.add(importedModule.runtimeType);
      }
    }

    if (importsList.isNotEmpty) {
      print('');
      print('✅ TODOS OS IMPORTS de ${module.runtimeType} PROCESSADOS');
    }

    // IMPORTANTE: Adicionar o AppModule ao injector do módulo para que dependências sejam resolvidas
    // O AppModule contém binds globais (como IClient) que os módulos precisam acessar
    print('');
    print('🔍 VERIFICANDO APPMODULE para ${module.runtimeType}:');
    print('   AppModule registrado: ${_appModule?.runtimeType ?? "null"}');
    print('   Módulo atual: ${module.runtimeType}');
    print('   É o próprio AppModule? ${_appModule == module}');
    print('   Injectors disponíveis no mapa: ${_moduleInjectors.keys.map((k) => k.toString()).join(", ")}');

    // NÃO adicionar AppModule como sub-injector
    // Deixar o Injector.get() fazer fallback para AppModule automaticamente
    // Isso evita o problema de "Injector committed!" do auto_injector
    if (_appModule != null && _appModule != module) {
      final appModuleInjector = _moduleInjectors[_appModule!.runtimeType];
      print('   AppModuleInjector no mapa: ${appModuleInjector != null ? "✅ SIM" : "❌ NÃO"}');
      print('   ℹ️  NÃO adicionando AppModule como sub-injector');
      print('   ℹ️  Injector.get() fará fallback automático para AppModule');
    } else {
      print('   ℹ️  Não precisa adicionar AppModule (é null ou é o próprio módulo)');
    }

    // binds() já foi executado ANTES dos imports (para TODOS os módulos)
    print('ℹ️  ${module.runtimeType}.binds() já foi executado antes dos imports');
    print('ℹ️  ${module.runtimeType} já está no mapa e disponível para fallback');
    print('');

    // Inicializar estado do módulo
    module.initState(Injector.fromAutoInjector(newInjector));

    return newInjector;
  }

  Future<void> registerBindsModule(Module module) async {
    return await _registerBindsModuleInternal(module);
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
