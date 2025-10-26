import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'package:auto_injector/auto_injector.dart';
import 'package:go_router_modular/go_router_modular.dart' as go_router_modular;
import 'package:go_router_modular/src/internal/setup.dart';
import 'package:go_router_modular/src/di/clean_bind.dart';
import '_module_registry.dart';

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
  /// SEGUINDO O PADRÃO DO FLUTTER_MODULAR: usar callback 'on' para fazer commit
  final AutoInjector _autoInjector = AutoInjector(
    tag: 'go_router_modular_main',
    on: (i) {
      // AutoInjector inicializado com commit automático via callback 'on'
      // Isso evita warnings sobre injector não commitado
      i.commit();
    },
  );

  /// Registry para rastrear módulos
  final ModuleRegistry _registry = ModuleRegistry();

  /// Cadeia de dependências para rastrear resoluções aninhadas
  final List<String> _dependencyChain = [];

  /// Getter público para a cadeia de dependências (apenas leitura)
  List<String> get dependencyChain => List.unmodifiable(_dependencyChain);

  bool get debugLog => SetupModular.instance.debugLogGoRouterModular;

  /// Obtém a cadeia de dependências atual
  String getCurrentDependencyChain() {
    if (_dependencyChain.isEmpty) return '';
    return _dependencyChain.join(' -> ');
  }

  /// Adiciona um tipo à cadeia de dependências
  void pushDependencyChain(Type type) {
    _dependencyChain.add(type.toString());
  }

  /// Remove o último tipo da cadeia de dependências
  void popDependencyChain() {
    if (_dependencyChain.isNotEmpty) {
      _dependencyChain.removeLast();
    }
  }

  /// Define o contexto do módulo atual (chamado ao navegar para uma rota)
  void setModuleContext(Type moduleType) {
    _registry.setContext(moduleType);
  }

  /// Obtém uma instância tentando diferentes contextos (módulo atual, imports, AppModule)
  T getWithModuleContext<T extends Object>({String? key}) {
    final contextualInjector = getContextualInjector();
    return contextualInjector.get<T>(key: key);
  }

  /// Obtém o AutoInjector correto baseado no contexto do módulo atual
  /// Retorna o injector do módulo atual (que inclui seus imports) ou o injector principal (AppModule)
  AutoInjector getContextualInjector() {
    final currentContext = _registry.currentModuleContext;
    final appModule = _registry.appModule;

    // Se temos um contexto de módulo específico, usar o injector desse módulo
    if (currentContext != null && _moduleInjectors.containsKey(currentContext)) {
      final injector = _moduleInjectors[currentContext]!;
      return injector;
    }

    // Fallback para o injector principal (AppModule) ou injector do AppModule se disponível
    AutoInjector fallbackInjector = _autoInjector;

    if (appModule != null && _moduleInjectors.containsKey(appModule.runtimeType)) {
      fallbackInjector = _moduleInjectors[appModule.runtimeType]!;
    }

    return fallbackInjector;
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

  Future<void> registerAppModule(go_router_modular.Module module) async {
    if (_registry.appModule != null) {
      return;
    }
    _registry.setAppModule(module);
    await registerBindsModule(module);
  }

  Future<void> registerBindsModule(go_router_modular.Module module) async {
    return _enqueueOperation(() => _registerBindsModuleInternal(module));
  }

  Future<void> _registerBindsModuleInternal(go_router_modular.Module module) async {
    if (_registry.isActive(module.runtimeType)) {
      return;
    }

    _registry.registerModule(module.runtimeType);

    // SEGUINDO O PADRÃO DO FLUTTER_MODULAR (tracker.dart linhas 207-213):
    // 1. Criar injector para o módulo
    final moduleInjector = await _createModuleInjector(module);

    // 2. Adicionar ao mapa de injectors ANTES de commitar
    _moduleInjectors[module.runtimeType] = moduleInjector;

    // 3. Adicionar injector do módulo ao injector principal
    // Como o injector principal já foi commitado no callback 'on', precisamos
    // uncommit temporariamente para adicionar novos injectors
    // (SEGUINDO O PADRÃO DO FLUTTER_MODULAR)
    _autoInjector.uncommit();
    _autoInjector.addInjector(moduleInjector);
    _autoInjector.commit();

    // Inicializar estado do módulo
    final moduleInjectorWrapper2 = go_router_modular.Injector.fromAutoInjector(moduleInjector);
    module.initState(moduleInjectorWrapper2);

    if (debugLog) {
      log('💉 INJECTED: ${module.runtimeType}', name: "GO_ROUTER_MODULAR");
    }
  }

  /// Cria um AutoInjector para um módulo (seguindo padrão flutter_modular - tracker.dart linha 275)
  Future<AutoInjector> _createModuleInjector(go_router_modular.Module module) async {
    print('🔧 [InjectionManager._createModuleInjector] INÍCIO para: ${module.runtimeType}');
    // SEGUINDO O PADRÃO DO FLUTTER_MODULAR: criar injector sem callback 'on'
    final moduleInjector = AutoInjector(tag: module.runtimeType.toString());
    print('✅ [InjectionManager._createModuleInjector] Injector criado para: ${module.runtimeType}');

    // Processar imports do módulo
    final imports = module.imports();
    final importsList = imports is Future ? <go_router_modular.Module>[] : imports;
    print('🔍 [InjectionManager._createModuleInjector] Processando ${importsList.length} imports para: ${module.runtimeType}');

    for (final importedModule in importsList) {
      _registry.addImport(module.runtimeType, importedModule.runtimeType);
      final importedInjector = await _getOrCreateModuleInjector(importedModule);
      moduleInjector.addInjector(importedInjector);
      print('✅ [InjectionManager._createModuleInjector] Import ${importedModule.runtimeType} adicionado ao injector de ${module.runtimeType}');
    }

    // IMPORTANTE: Adicionar o AppModule ao injector do módulo para que dependências sejam resolvidas
    // O AppModule contém binds globais (como IClient) que os módulos precisam acessar
    print('🔍 [InjectionManager._createModuleInjector] Verificando AppModule para: ${module.runtimeType}');
    final appModule = _registry.appModule;
    print('🔍 [InjectionManager._createModuleInjector] appModule: ${appModule?.runtimeType}');
    print('🔍 [InjectionManager._createModuleInjector] module.runtimeType: ${module.runtimeType}');
    print('🔍 [InjectionManager._createModuleInjector] Injectors disponíveis: ${_moduleInjectors.keys}');
    if (appModule != null && appModule.runtimeType != module.runtimeType) {
      final appModuleInjector = _moduleInjectors[appModule.runtimeType];
      print('🔍 [InjectionManager._createModuleInjector] appModuleInjector: ${appModuleInjector != null ? "encontrado" : "null"}');
      if (appModuleInjector != null) {
        print('🔧 [InjectionManager._createModuleInjector] Adicionando AppModule ao injector de ${module.runtimeType}');
        moduleInjector.addInjector(appModuleInjector);
        print('✅ [InjectionManager._createModuleInjector] AppModule adicionado ao injector de ${module.runtimeType}');
      } else {
        print('⚠️ [InjectionManager._createModuleInjector] AppModule não encontrado no mapa de injectors');
      }
    } else {
      print('⚠️ [InjectionManager._createModuleInjector] AppModule é null ou é o próprio módulo');
    }

    // Criar um wrapper Injector e chamar module.binds() (SEGUINDO PADRÃO FLUTTER_MODULAR linha 282)
    print('🔧 [InjectionManager._createModuleInjector] Chamando module.binds() para: ${module.runtimeType}');
    print('🔧 [InjectionManager._createModuleInjector] moduleInjector: $moduleInjector');
    final injectorWrapper = go_router_modular.Injector.fromAutoInjector(moduleInjector);
    print('🔧 [InjectionManager._createModuleInjector] injectorWrapper criado, chamando binds()...');
    final bindsResult = module.binds(injectorWrapper);
    // Se binds retorna um Future, aguardar (FutureBinds é FutureOr<void>)
    if (bindsResult is Future) {
      print('⏳ [InjectionManager._createModuleInjector] Aguardando binds assíncronos para ${module.runtimeType}...');
      await bindsResult;
      print('✅ [InjectionManager._createModuleInjector] Binds assíncronos concluídos para ${module.runtimeType}');
    }
    print('✅ [InjectionManager._createModuleInjector] module.binds() concluído para: ${module.runtimeType}');

    // Commit do injector do módulo após registrar todos os binds
    moduleInjector.commit();

    return moduleInjector;
  }

  /// Mapa para armazenar os injectors dos módulos
  final Map<Type, AutoInjector> _moduleInjectors = {};

  /// Getter público para acessar o mapa de injectors
  Map<Type, AutoInjector> get moduleInjectors => _moduleInjectors;

  /// Obtém ou cria o injector de um módulo
  Future<AutoInjector> _getOrCreateModuleInjector(go_router_modular.Module module) async {
    if (_moduleInjectors.containsKey(module.runtimeType)) {
      return _moduleInjectors[module.runtimeType]!;
    }

    final injector = await _createModuleInjector(module);
    _moduleInjectors[module.runtimeType] = injector;

    return injector;
  }

  Future<void> unregisterBinds(go_router_modular.Module module) async {
    return _enqueueOperation(() => _unregisterModuleInternal(module));
  }

  Future<void> unregisterModule(go_router_modular.Module module) async {
    return _enqueueOperation(() => _unregisterModuleInternal(module));
  }

  Future<void> _unregisterModuleInternal(go_router_modular.Module module) async {
    if (!_registry.isActive(module.runtimeType)) {
      return;
    }

    try {
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
    } catch (e) {
      // Ignorar erros de dispose
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
      _moduleInjectors.clear();

      // Re-comitar para evitar warnings do auto_injector
      // Isso garante que o injector esteja pronto para o próximo teste
      _autoInjector.commit();
    } catch (e) {
      // Ignorar erros de cleanup
    }
  }
}
