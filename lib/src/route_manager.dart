import 'dart:developer';
import 'package:go_router_modular/go_router_modular.dart';

class RouteManager {
  static final RouteManager _instance = RouteManager._();
  final Map<Module, Set<String>> _registeredModules = {};
  final Map<Type, int> _bindReferences = {};
  Module? _appModule;

  RouteManager._();

  factory RouteManager() {
    return _instance;
  }

  void registerBindsAppModule(Module module) {
    if (_appModule != null) return;
    _appModule = module;
    registerBindsIfNeeded(module);
  }

  void registerBindsIfNeeded(Module module) {
    if (_registeredModules.containsKey(module)) return;

    for (var bind in module.binds) {
      _incrementBindReference(bind.runtimeType);
      Bind.register(bind);
    }

    _registeredModules.addAll({module: {}});
    log('INJECTED: ${module.runtimeType} BINDS: ${module.binds.toList().map((e) => e.instance.runtimeType.toString())}', name: "💉");
  }

  void unregisterBinds(Module module) {
    if (_appModule != null && module == _appModule!) return;
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!_registeredModules.containsKey(module)) return;
      if (_registeredModules[module]?.isNotEmpty ?? true) return;

      for (var bind in module.binds) {
        _decrementBindReference(bind.runtimeType);
      }

      _registeredModules.remove(module);
      for (var module in module.binds) {
        Bind.unregisterType(module.instance.runtimeType);
      }

      log('DISPOSED: ${module.runtimeType} BINDS: ${module.binds.toList().map((e) => e.instance.runtimeType.toString())}', name: "🗑️");
    });
  }

  void _incrementBindReference(Type type) {
    if (_bindReferences.containsKey(type)) {
      _bindReferences[type] = (_bindReferences[type] ?? 0) + 1;
    } else {
      _bindReferences[type] = 1;
    }
  }

  void _decrementBindReference(Type type) {
    if (_bindReferences.containsKey(type)) {
      _bindReferences[type] = (_bindReferences[type] ?? 1) - 1;
      if (_bindReferences[type] == 0) {
        _bindReferences.remove(type);
        Bind.unregisterType(type);
      }
    }
  }

  void registerRoute(String route, Module module) {
    _registeredModules.putIfAbsent(module, () => {});
    _registeredModules[module]!.add(route);
  }

  void unregisterRoute(String route, Module module) {
    _registeredModules[module]?.remove(route);
    if (_registeredModules[module]?.isEmpty ?? false) {
      unregisterBinds(module);
    }
  }
}
