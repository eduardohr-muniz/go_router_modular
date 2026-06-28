import 'dart:async';
import 'dart:developer';
import 'package:go_router_modular/src/di/bind.dart';
import 'package:go_router_modular/src/module/module.dart';
import 'package:go_router_modular/src/di/injector.dart';
import 'package:go_router_modular/src/di/bind_identifier.dart';
import 'package:go_router_modular/src/di/operation_queue.dart';
import 'package:go_router_modular/src/di/bind_context_tracker.dart';
import 'package:go_router_modular/src/shared/exception.dart';
import 'package:go_router_modular/src/shared/setup.dart';

/// Manages module lifecycle: registration, bind injection, and disposal.
class InjectionManager {
  static InjectionManager? _instance;
  InjectionManager._();
  static InjectionManager get instance => _instance ??= InjectionManager._();

  final Injector _injector = Injector();
  final OperationQueue _queue = OperationQueue();
  final BindContextTracker _tracker = BindContextTracker();
  final List<Function> _bindsToValidate = [];

  /// Contagem de referências por instância de módulo (identidade).
  ///
  /// Conta quantas entradas de rota ativas referenciam cada instância. O
  /// registro real ocorre na primeira referência (0→1) e o descarte real na
  /// última (1→0), evitando descarte prematuro quando a mesma instância aparece
  /// mais de uma vez na pilha de navegação (ex.: A → B → A).
  final Map<Module, int> _referenceCount = Map<Module, int>.identity();

  bool get _debugLog => SetupModular.instance.debugLogModular;

  /// Defensive resolver for bind introspection (tracking, logging, validation).
  ///
  /// `commitBatch` already populates `cachedInstance` for eager singletons.
  /// This helper handles the residual cases — lazy singletons whose factory
  /// must run for type discovery, or binds whose factory failed during commit
  /// — without leaking duplicate singleton instances.
  Object _singletonInstanceOrFactory(Bind<Object> bind) {
    final cached = bind.cachedInstance;
    if (cached != null) return cached;

    final instance = bind.factoryFunction(_injector);
    if (bind.isSingleton) {
      bind.cachedInstance = instance;
    }
    return instance;
  }

  /// Clears every bind and module-registration state. Use between tests that
  /// touch [InjectionManager] so `registerAppModule` is not skipped due to a
  /// stale [BindContextTracker.appModule].
  void resetForTesting() {
    Bind.clearAll();
    _tracker.clear();
    _bindsToValidate.clear();
    _referenceCount.clear();
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
    // Reference counting: only the first reference (0→1) does the actual
    // registration; subsequent references of the same instance just count.
    final referenceCount = (_referenceCount[module] ?? 0) + 1;
    _referenceCount[module] = referenceCount;
    if (referenceCount > 1) return;

    if (_tracker.moduleBindTypes.containsKey(module)) return;

    // Collect binds from module and its imports
    _injector.startRegistering();
    await module.binds(_injector);
    final moduleBinds = _injector.finishRegistering();

    final importedBinds = await _collectImportedBinds(module);
    final allBinds = [...moduleBinds, ...importedBinds];

    // Register using batch strategy. As dependências resolvidas pelas factories
    // durante o commit são gravadas (sem re-executar nada) para a validação de
    // escopo.
    _injector.beginScopeRecording();
    if (allBinds.isNotEmpty) {
      Bind.registerBatch(allBinds);
      Bind.commitBatch(_injector);
    }
    final recordedDependencies = _injector.endScopeRecording();

    // Map binds to module context
    _tracker.moduleBindTypes[module] = _mapBindsToIdentifiers(allBinds, module);

    // Scope validation (commit-time, eager): cada dependência resolvida pelos
    // binds deste módulo só pode pertencer ao seu escopo visível (próprios +
    // importados + AppModule).
    _validateModuleScope(module, recordedDependencies);

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
        final instance = _singletonInstanceOrFactory(bind);
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
    // Reference counting: only the last reference (1→0) does the actual
    // disposal. While other route entries still reference this instance, keep
    // its binds alive (fix for premature disposal in stacks like A → B → A).
    final referenceCount = _referenceCount[module] ?? 0;
    if (referenceCount == 0) return;
    if (referenceCount > 1) {
      _referenceCount[module] = referenceCount - 1;
      return;
    }
    _referenceCount.remove(module);

    module.dispose();
    _unregisterBinds(module);
    _tracker.moduleBindTypes.remove(module);

    if (_bindsToValidate.isNotEmpty) {
      final validationsToRun = List<Function>.from(_bindsToValidate);
      for (final validation in validationsToRun) {
        try {
          validation();
        } catch (_) {
          // Validation errors must never interrupt the operation queue.
          // Failures are already logged inside _validateModuleBinds.
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
      // Factory binds are transient and validated lazily on first use.
      // Attempting to instantiate them here is unsafe: their singleton
      // dependencies may already have been disposed by _unregisterBinds.
      if (!bind.isSingleton) continue;

      // Skip singletons whose cache was already cleared by _unregisterBinds —
      // attempting to recreate them would produce phantom instances that are
      // never tracked and immediately discarded.
      if (bind.cachedInstance == null) continue;

      Type? bindType;
      try {
        final newInstance = _singletonInstanceOrFactory(bind);
        bindType = newInstance.runtimeType;
      } catch (e) {
        bindType ??= _tryGetBindType(bind);
        if (_debugLog) {
          final normalizedStack = _normalizeStackTrace(bind.stackTrace.toString());
          log('Bind validation failed: $bindType - $e \nSTACKTRACE: \n$normalizedStack', name: "GO_ROUTER_MODULAR");
          // Do NOT throw here — a validation failure must never interrupt the
          // OperationQueue. The log above is sufficient for debugging.
        }
      }
    }
  }

  /// Valida (commit-time) que cada dependência resolvida pelos binds de [module]
  /// durante o commit pertence ao seu conjunto visível (próprios + importados +
  /// AppModule). Lança [ModularException] na violação.
  void _validateModuleScope(Module module, List<BindIdentifier> resolvedDependencies) {
    for (final resolvedId in resolvedDependencies) {
      if (!_tracker.isVisible(resolvedId, module)) {
        throw ModularException(
          '${module.runtimeType} resolveu ${resolvedId.type} que não declarou nem importou. '
          'Importe o módulo dono de ${resolvedId.type} ou injete ${resolvedId.type} em ${module.runtimeType}.',
        );
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
        final instance = _singletonInstanceOrFactory(bind);
        final type = instance.runtimeType.toString();
        final keyInfo = bind.key != null && bind.key != type ? 'key: ${bind.key}' : '';
        return '$type($keyInfo)';
      } catch (_) {
        // return 'Object(${bind.key != null ? 'key: ${bind.key}' : ''})'
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
