import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'package:auto_injector/auto_injector.dart' as ai;
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/internal/setup.dart';
import 'package:go_router_modular/src/internal/internal_logs.dart';

/// ValueObject para representar um bind único (Type + Key)

class InjectionManager {
  static InjectionManager? _instance;
  InjectionManager._();
  static InjectionManager get instance => _instance ??= InjectionManager._();

  /// Main AutoInjector instance - similar to flutter_modular's approach
  final ai.AutoInjector _injector = ai.AutoInjector();

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
  Future<void> _registerModuleBinds(Module module, ai.AutoInjector injector, Set<Module>? visited) async {
    visited ??= <Module>{};

    if (visited.contains(module)) {
      return;
    }
    visited.add(module);

    // Registrar imports recursivamente
    final imports = await module.imports();
    for (final importedModule in imports) {
      await _registerModuleBinds(importedModule, injector, visited);
    }

    // Registrar binds do módulo atual
    final binds = await module.binds();
    for (final bind in binds) {
      try {
        // Usar auto_injector para registrar
        _registerBindToInjector(injector, bind);
      } catch (e) {
        if (debugLog) {
          iLog('❌ Failed to register bind: ${bind.instance.runtimeType ?? 'Unknown'} - $e', name: "GO_ROUTER_MODULAR");
        }
        throw GoRouterModularException('❌ Bind not found for type ${bind.instance.runtimeType.toString() ?? 'Unknown'}: $e');
      }
    }

    // Inicializar estado do módulo com adaptador
    module.initState(Injector());
  }

  /// Registra um bind no AutoInjector com suporte a factory patterns
  void _registerBindToInjector(ai.AutoInjector injector, Bind<Object> bind) {
    final type = bind.instance.runtimeType ?? Object;
    final key = bind.key;

    if (bind.isSingleton) {
      // Singleton: cria uma vez e reutiliza
      injector.addSingleton<dynamic>(
        () {
          try {
            // Criar instância usando factory do bind
            return bind.factoryFunction(Injector());
          } catch (e) {
            throw GoRouterModularException('Failed to create instance of $type: $e');
          }
        },
        key: key,
      );
    } else {
      // Factory: cria nova instância a cada chamada
      injector.add<dynamic>(
        () {
          try {
            return bind.factoryFunction(Injector());
          } catch (e) {
            throw GoRouterModularException('Failed to create instance of $type: $e');
          }
        },
        key: key,
      );
    }
  }

  Future<void> registerBindsModule(Module module) async {
    return _enqueueOperation(() => _registerBindsModuleInternal(module));
  }

  Future<void> _registerBindsModuleInternal(Module module) async {
    if (_moduleInjectors.containsKey(module.runtimeType)) {
      return;
    }

    // Criar injector específico para este módulo
    final moduleTag = '${module.runtimeType}_${DateTime.now().millisecondsSinceEpoch}';
    final moduleInjector = ai.AutoInjector(tag: moduleTag);

    _moduleInjectors[module.runtimeType] = moduleInjector;
    _activeModuleTags[module.runtimeType] = moduleTag;

    // Registrar binds e imports recursivamente
    await _registerModuleBinds(module, moduleInjector, null);

    // Adicionar o injector do módulo ao injector principal
    _injector.addInjector(moduleInjector);

    if (debugLog) {
      final binds = await module.binds();
      final imports = await module.imports();
      final allBinds = <Bind<Object>>[];

      // Coletar todos os binds recursivamente
      for (final importedModule in imports) {
        final importedBinds = await importedModule.binds();
        allBinds.addAll(importedBinds);
      }
      allBinds.addAll(binds);

      log(
          '💉 INJECTED 🧩 MODULE: ${module.runtimeType} \nBINDS: { \n${allBinds.isEmpty ? '😴 EMPTY' : ''}${allBinds.map(
                (e) {
                  final type = e.instance.runtimeType.toString() ?? 'Unknown';
                  final key = e.key;
                  return '♻️ $type(${key != null ? (key == type ? '' : 'key: $key') : ''})';
                },
              ).toList().join('\n')} \n}',
          name: "GO_ROUTER_MODULAR");
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
}

/// Classe Disposable para permitir cleanup automático
abstract class Disposable {
  void dispose();
}
