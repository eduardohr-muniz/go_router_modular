import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'package:get_it/get_it.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/internal/setup.dart';
import 'package:go_router_modular/src/di/clean_bind.dart';

/// Registro de um bind para rastreamento
class _BindRegistration {
  final Type type;
  final String? instanceName;

  _BindRegistration(this.type, this.instanceName);
}

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

  /// Rastrear quais módulos estão ativos
  final Set<Type> _activeModules = {};

  /// Rastrear quais módulos cada módulo importa
  final Map<Type, Set<Type>> _moduleImports = {};

  /// Rastrear os binds registrados por cada módulo (para unregister)
  final Map<Type, List<_BindRegistration>> _moduleBinds = {};

  /// Módulo ativo no contexto atual (para resolução de binds)
  Type? _currentModuleContext;

  Module? _appModule;

  bool get debugLog => SetupModular.instance.debugLogGoRouterModular;

  /// Define o contexto do módulo atual (chamado ao navegar para uma rota)
  void setModuleContext(Type moduleType) {
    _currentModuleContext = moduleType;
  }

  /// Obtém o prefixo para um módulo
  String _getModulePrefix(Type moduleType) {
    return '${moduleType.toString()}_';
  }

  /// Obtém uma instância tentando diferentes contextos (módulo atual, imports, AppModule)
  T getWithModuleContext<T extends Object>({String? key}) {
    final typeName = T.toString();

    // 1. Tentar no módulo atual (com prefixo)
    if (_currentModuleContext != null && _activeModules.contains(_currentModuleContext)) {
      final prefix = _getModulePrefix(_currentModuleContext!);

      // Tentar com key se fornecida
      if (key != null) {
        final fullName = '$prefix$key';
        if (_getIt.isRegistered<T>(instanceName: fullName)) {
          return _getIt.get<T>(instanceName: fullName);
        }
      }

      // Tentar com tipo
      final fullTypeName = '$prefix$typeName';
      if (_getIt.isRegistered<T>(instanceName: fullTypeName)) {
        return _getIt.get<T>(instanceName: fullTypeName);
      }

      // 2. Tentar nos módulos importados (apenas se estiverem ativos)
      final imports = _moduleImports[_currentModuleContext] ?? {};
      for (final importedModule in imports) {
        if (!_activeModules.contains(importedModule)) {
          continue; // Pular módulos que foram disposed
        }

        final importPrefix = _getModulePrefix(importedModule);

        if (key != null) {
          final importFullName = '$importPrefix$key';
          if (_getIt.isRegistered<T>(instanceName: importFullName)) {
            return _getIt.get<T>(instanceName: importFullName);
          }
        }

        final importFullTypeName = '$importPrefix$typeName';
        if (_getIt.isRegistered<T>(instanceName: importFullTypeName)) {
          return _getIt.get<T>(instanceName: importFullTypeName);
        }
      }
    }

    // 3. Tentar no AppModule (sem prefixo - global)
    if (key != null) {
      if (_getIt.isRegistered<T>(instanceName: key)) {
        return _getIt.get<T>(instanceName: key);
      }
    }

    // Tentar com tipo como instanceName
    if (_getIt.isRegistered<T>(instanceName: typeName)) {
      return _getIt.get<T>(instanceName: typeName);
    }

    // 4. Tentar sem instanceName (registro direto por tipo - fallback)
    if (key == null && _getIt.isRegistered<T>()) {
      return _getIt.get<T>();
    }

    throw Exception('Bind not found for type: ${T.toString()}${key != null ? ' with key: $key' : ''}');
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
    if (_appModule != null) {
      return;
    }
    _appModule = module;
    await registerBindsModule(module);
  }

  Future<void> registerBindsModule(Module module) async {
    return _enqueueOperation(() => _registerBindsModuleInternal(module));
  }

  Future<void> _registerBindsModuleInternal(Module module) async {
    if (_activeModules.contains(module.runtimeType)) {
      return;
    }

    _activeModules.add(module.runtimeType);

    // Rastrear imports deste módulo
    _moduleImports[module.runtimeType] = <Type>{};

    // Inicializar rastreamento de binds deste módulo
    _moduleBinds[module.runtimeType] = [];

    final imports = module.imports();
    final importsList = imports is Future ? <Module>[] : imports;

    for (final importedModule in importsList) {
      _moduleImports[module.runtimeType]!.add(importedModule.runtimeType);

      // Registrar módulo importado se ainda não foi registrado
      if (!_activeModules.contains(importedModule.runtimeType)) {
        await _registerBindsModuleInternal(importedModule);
      }
    }

    // Criar um Injector com contexto do módulo
    final modulePrefix = module == _appModule ? null : _getModulePrefix(module.runtimeType);
    final injector = ModuleInjector(_getIt, modulePrefix, module.runtimeType);

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
    if (!_activeModules.contains(module.runtimeType)) {
      return;
    }

    try {
      // Unregister todos os binds deste módulo
      // IMPORTANTE: GetIt não permite unregister genérico sem o tipo
      // Vamos usar uma abordagem de "marcar como removido" verificando se o módulo está ativo
      // Os binds permanecerão no GetIt mas não serão acessíveis via getWithModuleContext
      // Isso é uma limitação do GetIt vs auto_injector

      // Para binds com instanceName, podemos tentar resetLazySingleton
      final binds = _moduleBinds[module.runtimeType] ?? [];
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
      _activeModules.remove(module.runtimeType);
      _moduleImports.remove(module.runtimeType);
      _moduleBinds.remove(module.runtimeType);

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

      // Limpar mapas de rastreamento
      _activeModules.clear();
      _moduleImports.clear();
      _moduleBinds.clear();

      // Resetar contexto e app module
      _currentModuleContext = null;
      _appModule = null;

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

/// Injector com contexto de módulo para registrar binds com prefixo
class ModuleInjector extends Injector {
  final GetIt _getIt;
  final String? _modulePrefix;
  final Type _moduleType;

  ModuleInjector(this._getIt, this._modulePrefix, this._moduleType) : super.fromGetIt(_getIt);

  String _getInstanceName<T>(String? key) {
    final baseName = key ?? T.toString();
    return _modulePrefix != null ? '$_modulePrefix$baseName' : baseName;
  }

  void _trackBind<T>(String? instanceName) {
    final binds = InjectionManager.instance._moduleBinds[_moduleType];
    if (binds != null) {
      binds.add(_BindRegistration(T, instanceName));
    }
  }

  @override
  void add<T extends Object>(T Function() builder, {String? key}) {
    if (_modulePrefix == null && key == null) {
      // AppModule sem key: registrar sem instanceName
      _getIt.registerFactory<T>(builder);
      _trackBind<T>(null);
    } else {
      final instanceName = _getInstanceName<T>(key);
      _getIt.registerFactory<T>(builder, instanceName: instanceName);
      _trackBind<T>(instanceName);
    }
  }

  @override
  void addSingleton<T extends Object>(T Function() builder, {String? key}) {
    if (_modulePrefix == null && key == null) {
      // AppModule sem key: registrar sem instanceName
      _getIt.registerLazySingleton<T>(
        builder,
        dispose: (instance) {
          CleanBind.fromInstance(instance);
        },
      );
      _trackBind<T>(null);
    } else {
      final instanceName = _getInstanceName<T>(key);
      _getIt.registerLazySingleton<T>(
        builder,
        instanceName: instanceName,
        dispose: (instance) {
          CleanBind.fromInstance(instance);
        },
      );
      _trackBind<T>(instanceName);
    }
  }

  @override
  void addLazySingleton<T extends Object>(T Function() builder, {String? key}) {
    if (_modulePrefix == null && key == null) {
      // AppModule sem key: registrar sem instanceName
      _getIt.registerLazySingleton<T>(
        builder,
        dispose: (instance) {
          CleanBind.fromInstance(instance);
        },
      );
      _trackBind<T>(null);
    } else {
      final instanceName = _getInstanceName<T>(key);
      _getIt.registerLazySingleton<T>(
        builder,
        instanceName: instanceName,
        dispose: (instance) {
          CleanBind.fromInstance(instance);
        },
      );
      _trackBind<T>(instanceName);
    }
  }

  @override
  T get<T extends Object>({String? key}) {
    return InjectionManager.instance.getWithModuleContext<T>(key: key);
  }
}
