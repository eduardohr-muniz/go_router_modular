import 'dart:async';
import 'dart:developer';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/di/bind_identifier.dart';
import 'package:go_router_modular/src/core/manager/operation_queue.dart';
import 'package:go_router_modular/src/core/manager/bind_context_tracker.dart';
import 'package:go_router_modular/src/internal/setup.dart';


/// Manages module lifecycle: registration, bind injection, and disposal.
class InjectionManager {
  static InjectionManager? _instance;
  InjectionManager._();
  static InjectionManager get instance => _instance ??= InjectionManager._();

  final Injector _injector = Injector();
  final OperationQueue _queue = OperationQueue();
  final BindContextTracker _tracker = BindContextTracker();
  final List<Function> _bindsToValidate = [];

  bool get _debugLog => SetupModular.instance.debugLogGoRouterModular;

  /// Clears every bind and module-registration state. Use between tests that
  /// touch [InjectionManager] so `registerAppModule` is not skipped due to a
  /// stale [BindContextTracker.appModule].
  void resetForTesting() {
    Bind.clearAll();
    _tracker.clear();
    _bindsToValidate.clear();
  }

  // ==================== MODULE REGISTRATION ====================

  Future<void> registerAppModule(Module module) async {
    if (_tracker.appModule != null) return;
    _tracker.appModule = module;
    await registerBindsModule(module);
  }

  Future<void> registerBindsModule(Module module) async {
    return _queue.enqueue(() => _registerBindsModuleInternal(module));
  }

  Future<void> _registerBindsModuleInternal(Module module) async {
    if (_tracker.moduleBindTypes.containsKey(module)) return;

    // Collect binds from module and its imports
    _injector.startRegistering();
    await module.binds(_injector);
    final moduleBinds = _injector.finishRegistering();

    final importedBinds = await _collectImportedBinds(module);
    final allBinds = [...moduleBinds, ...importedBinds];

    // Register using batch strategy
    if (allBinds.isNotEmpty) {
      Bind.registerBatch(allBinds);
      Bind.commitBatch(_injector);
    }

    // Map binds to module context
    _tracker.moduleBindTypes[module] = _mapBindsToIdentifiers(allBinds, module);

    module.initState(_injector);

    if (_debugLog) _logRegisteredBinds(module, allBinds);

    // Schedule validation
    _scheduleValidation(() => _validateModuleBinds(module, allBinds), module.runtimeType.toString());
  }

  Future<List<Bind<Object>>> _collectImportedBinds(Module module, [Set<Module>? visited]) async {
    visited ??= <Module>{};
    final allImportedBinds = <Bind<Object>>{};

    if (visited.contains(module)) return allImportedBinds.toList();
    visited.add(module);

    final imports = await module.imports();

    await Future.forEach(imports, (Module importedModule) async {
      _injector.startRegistering();
      await importedModule.binds(_injector);
      final importedBinds = _injector.finishRegistering();
      allImportedBinds.addAll(importedBinds);
      allImportedBinds.addAll(await _collectImportedBinds(importedModule, visited));
    });

    return allImportedBinds.toList();
  }

  Set<BindIdentifier> _mapBindsToIdentifiers(List<Bind<Object>> binds, Module module) {
    return binds.map((bind) {
      try {
        final instance = bind.cachedInstance ?? bind.factoryFunction(_injector);
        final type = instance.runtimeType;
        final bindId = BindIdentifier(type, bind.key ?? type.toString());
        _tracker.addModuleToBindContext(bindId, module);
        return bindId;
      } catch (_) {
        return BindIdentifier(Object, bind.key ?? 'Object');
      }
    }).toSet();
  }

  // ==================== MODULE UNREGISTRATION ====================

  Future<void> unregisterModule(Module module) async {
    if (module.runtimeType == _tracker.appModule?.runtimeType) return;
    return _queue.enqueue(() => _unregisterModuleInternal(module));
  }

  Future<void> _unregisterModuleInternal(Module module) async {
    module.dispose();
    _unregisterBinds(module);
    _tracker.moduleBindTypes.remove(module);

    if (_bindsToValidate.isNotEmpty) {
      final validationsToRun = List<Function>.from(_bindsToValidate);
      for (final validation in validationsToRun) {
        try {
          validation();
        } catch (e) {
          if (e is GoRouterModularException) rethrow;
        }
      }
      _bindsToValidate.clear();
    }
  }

  void _unregisterBinds(Module module) {
    if (_tracker.appModule != null && module == _tracker.appModule!) return;

    final bindsToDispose = _tracker.moduleBindTypes[module] ?? {};
    final disposedBinds = <BindIdentifier>[];

    for (final bindId in bindsToDispose) {
      try {
        final shouldDispose = _tracker.removeModuleFromBindContext(bindId, module);

        if (shouldDispose && !_tracker.isBindForAppModule(bindId)) {
          disposedBinds.add(bindId);
          Bind.disposeByType(bindId.type);
          Bind.cleanSearchAttemptsForType(bindId.type);
        }
      } catch (_) {}
    }

    if (_debugLog) {
      final bindList = disposedBinds.isEmpty ? 'EMPTY' : disposedBinds.map((e) => e.toString()).join('\n');
      log('DISPOSED MODULE: ${module.runtimeType} \nBINDS: { \n$bindList \n}', name: "GO_ROUTER_MODULAR");
    }

    bindsToDispose.clear();
  }

  // ==================== VALIDATION ====================

  void _scheduleValidation(void Function() validate, String moduleName) {
    _bindsToValidate.add(validate);

    Future.delayed(const Duration(milliseconds: 500), () {
      _bindsToValidate.remove(validate);
    });
  }

  void _validateModuleBinds(Module module, List<Bind<Object>> moduleBinds) {
    for (final bind in moduleBinds) {
      Type? bindType;
      try {
        final newInstance = bind.cachedInstance ?? bind.factoryFunction(_injector);
        bindType = newInstance.runtimeType;
      } catch (e) {
        bindType ??= _tryGetBindType(bind);
        if (_debugLog) {
          final normalizedStack = _normalizeStackTrace(bind.stackTrace.toString());
          log('Bind validation failed: $bindType - $e \nSTACKTRACE: \n$normalizedStack', name: "GO_ROUTER_MODULAR");
          throw GoRouterModularException('Bind not found for type ${bindType.toString()}');
        }
      }
    }
  }

  Type _tryGetBindType(Bind bind) {
    try {
      return bind.instance.runtimeType;
    } catch (_) {
      return Object;
    }
  }

  // ==================== LOGGING ====================

  void _logRegisteredBinds(Module module, List<Bind<Object>> binds) {
    final bindDescriptions = binds.map((bind) {
      try {
        final instance = bind.cachedInstance ?? bind.factoryFunction(_injector);
        final type = instance.runtimeType.toString();
        final keyInfo = bind.key != null && bind.key != type ? 'key: ${bind.key}' : '';
        return '$type($keyInfo)';
      } catch (_) {
        return 'Object(${bind.key != null ? 'key: ${bind.key}' : ''})';
      }
    }).join('\n');

    log(
      'INJECTED MODULE: ${module.runtimeType} \nBINDS: { \n${binds.isEmpty ? 'EMPTY' : bindDescriptions} \n}',
      name: "GO_ROUTER_MODULAR",
    );
  }

  String _normalizeStackTrace(String stackTrace) {
    return stackTrace
        .split('\n')
        .where((line) => line.contains('binds') || line.contains('imports'))
        .map((line) {
          String normalized = line.replaceAll('../packages/', 'packages/').replaceAll(RegExp(r'^\s*\.\.\/'), '').trim();

          if (normalized.contains('/lib/')) {
            final libIndex = normalized.indexOf('/lib/');
            return normalized.substring(libIndex + 1);
          }

          if (normalized.startsWith('lib/')) return normalized;

          if (normalized.startsWith('packages/')) {
            final parts = normalized.split('/');
            if (parts.length >= 3) {
              if (!parts.contains('lib')) parts.insert(2, 'lib');
              final libIndexInParts = parts.indexOf('lib');
              if (libIndexInParts != -1) {
                return parts.sublist(libIndexInParts).join('/');
              }
            }
          }

          return normalized;
        })
        .take(4)
        .join('\n');
  }
}
