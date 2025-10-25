import 'dart:async';
import 'package:auto_injector/auto_injector.dart';
import 'injector.dart';

/// Abstract base class for all modules
abstract class Module {
  /// List of modules to import
  FutureOr<List<Module>> imports() => [];

  /// Configure dependency injection bindings
  FutureOr<void> binds(AutoInjector i);

  /// Initialize module state
  void initState(AutoInjector i) {}

  /// Dispose module resources
  void dispose() {}

  /// Register this module and its dependencies
  Future<void> register() async {
    await _registerImports();
    await binds(injector);
    initState(injector);
  }

  /// Register imported modules
  Future<void> _registerImports() async {
    final importedModules = await imports();
    for (final module in importedModules) {
      await module.register();
    }
  }
}

/// Service to manage module lifecycle
class ModuleService {
  final Set<Module> _registeredModules = <Module>{};
  final AutoInjector _injector;

  ModuleService(this._injector);

  /// Register a module
  Future<void> registerModule(Module module) async {
    if (_registeredModules.contains(module)) return;

    await module.register();
    _registeredModules.add(module);
  }

  /// Unregister a module
  Future<void> unregisterModule(Module module) async {
    if (!_registeredModules.contains(module)) return;

    module.dispose();
    _registeredModules.remove(module);
  }

  /// Check if module is registered
  bool isModuleRegistered(Module module) {
    return _registeredModules.contains(module);
  }

  /// Get all registered modules
  Set<Module> get registeredModules => Set.unmodifiable(_registeredModules);

  /// Dispose all modules
  Future<void> disposeAll() async {
    for (final module in _registeredModules.toList()) {
      await unregisterModule(module);
    }
  }
}

/// Global module service instance
final ModuleService moduleService = ModuleService(injector);
