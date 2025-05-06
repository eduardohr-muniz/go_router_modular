import 'dart:async';
import 'dart:developer' as dev;
import 'package:go_router_modular/src/bind.dart';
import 'package:go_router_modular/src/module.dart';

class RouteManager {
  static final RouteManager _instance = RouteManager._internal();
  factory RouteManager() => _instance;
  RouteManager._internal();

  final Map<Module, Set<String>> _activeRoutes = {};
  final Map<Type, Bind<Object>> _bindInstances = {};
  final Map<Type, int> _bindReferences = {};
  Module? _appModule;
  Timer? _disposeTimer;

  void registerBindsAppModule(Module module) {
    if (_appModule != null) return;
    _appModule = module;
    dev.log(
        '💉 App Module Injected forever: [${module.binds.map((b) => b.runtimeType.toString())}]',
        name: 'GO_ROUTER_MODULAR');
    registerBindsIfNeeded(module);
  }

  void registerBindsIfNeeded(Module module) {
    dev.log('Registering binds for module: ${module.runtimeType}',
        name: 'GO_ROUTER_MODULAR');

    // Sempre registra o appModule primeiro
    if (_appModule != null && !_isModuleRegistered(_appModule!)) {
      dev.log('Registering appModule first: ${_appModule.runtimeType}',
          name: 'GO_ROUTER_MODULAR');
      _registerBinds(_appModule!);
    }

    // Registra os módulos importados primeiro
    for (final importedModule in module.imports) {
      if (!_isModuleRegistered(importedModule)) {
        dev.log('Registering imported module: ${importedModule.runtimeType}',
            name: 'GO_ROUTER_MODULAR');
        _registerBinds(importedModule);
      }
    }

    // Por fim, registra o módulo atual
    if (!_isModuleRegistered(module)) {
      dev.log('Registering current module: ${module.runtimeType}',
          name: 'GO_ROUTER_MODULAR');
      _registerBinds(module);
    }
  }

  bool _isModuleRegistered(Module module) {
    final isRegistered = _activeRoutes.containsKey(module);
    dev.log(
        'Checking if module is registered: ${module.runtimeType} -> $isRegistered',
        name: 'GO_ROUTER_MODULAR');
    return isRegistered;
  }

  void _registerBinds(Module module) {
    if (_isModuleRegistered(module)) {
      dev.log('Module already registered: ${module.runtimeType}',
          name: 'GO_ROUTER_MODULAR');
      return;
    }

    final binds = module.binds;
    if (binds.isEmpty) {
      dev.log('No binds to register for module: ${module.runtimeType}',
          name: 'GO_ROUTER_MODULAR');
      return;
    }

    _activeRoutes[module] = {};
    for (final bind in binds) {
      final type = bind.instance.runtimeType;
      dev.log('Registering bind: $type', name: 'GO_ROUTER_MODULAR');
      _bindInstances[type] = bind;
      _incrementBindReference(type);
      Bind.register(bind);
    }

    dev.log(
        '💉 INJECTED: ${module.runtimeType} BINDS: ${[
          ...module.binds.map((e) => e.instance.runtimeType.toString()),
        ]}',
        name: "GO_ROUTER_MODULAR");
  }

  void registerRoute(String path, Module module) {
    _activeRoutes.putIfAbsent(module, () => {}).add(path);
  }

  void unregisterRoute(String path, Module module) {
    _activeRoutes[module]?.remove(path);
    _scheduleDispose(module);
  }

  void handleRouteChange(String path) {}

  void _scheduleDispose(Module module) {
    if (_appModule == module) return;

    final activeRoutes = _activeRoutes[module];
    if (activeRoutes?.isNotEmpty ?? false) return;

    _disposeTimer?.cancel();
    _disposeTimer = Timer(const Duration(milliseconds: 300), () {
      if (_activeRoutes[module]?.isEmpty ?? false) {
        _disposeModule(module);
      }
    });
  }

  void _disposeModule(Module module) {
    final binds = [...module.binds, ...module.imports.expand((e) => e.binds)];
    dev.log(
        'DISPOSED: ${module.runtimeType} BINDS: ${[
          ...binds.map((e) => e.instance.runtimeType.toString()),
        ]}',
        name: "🗑️ GO_ROUTER_MODULAR");

    for (final bind in binds) {
      _decrementBindReference(bind.instance.runtimeType);
    }
    _activeRoutes.remove(module);
  }

  void _incrementBindReference(Type type) {
    if (!_bindReferences.containsKey(type)) {
      _bindReferences[type] = 1;
    } else {
      _bindReferences[type] = (_bindReferences[type] ?? 0) + 1;
    }
  }

  void _decrementBindReference(Type type) {
    if (_bindReferences.containsKey(type)) {
      _bindReferences[type] = (_bindReferences[type] ?? 1) - 1;
      if (_bindReferences[type] == 0) {
        _bindReferences.remove(type);
        final bind = _bindInstances.remove(type);
        if (bind != null) {
          Bind.dispose(bind);
        }
      }
    }
  }

  T get<T>() {
    final bind = _bindInstances[T];
    if (bind == null) {
      dev.log('Bind not found for type: $T', name: 'GO_ROUTER_MODULAR');
      dev.log(
          'Available binds: ${_bindInstances.keys.map((k) => k.toString())}',
          name: 'GO_ROUTER_MODULAR');
      throw Exception('Bind not found for type $T');
    }
    return bind.instance as T;
  }

  void disposeModule(Module module) {
    final binds = module.binds;
    for (final bind in binds) {
      _decrementBindReference(bind.instance.runtimeType);
    }
  }
}
