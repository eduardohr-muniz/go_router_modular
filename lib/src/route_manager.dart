import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class RouteManager {
  static final RouteManager _instance = RouteManager._();
  final Map<Module, Set<String>> _activeRoutes = {};
  final Map<Type, int> _bindReferences = {};
  Module? _appModule;
  List<Type> bindsToDispose = [];

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
    if (_activeRoutes.containsKey(module)) return;
    List<Bind<Object>> allBinds = [...module.binds, ...module.imports.map((e) => e.binds).expand((e) => e)];
    _recursiveRegisterBinds(allBinds);

    _activeRoutes[module] = {};

    if (Modular.debugLogDiagnostics) {
      log(
          'INJECTED: ${module.runtimeType} BINDS: ${[
            ...module.binds.map((e) => e.instance.runtimeType.toString()),
            ...module.imports.map((e) => e.binds.map((e) => e.instance.runtimeType.toString()).toList())
          ]}',
          name: "💉");
    }
  }

  void _recursiveRegisterBinds(List<Bind<Object>> binds) {
    if (binds.isEmpty) return;
    List<Bind<Object>> queueBinds = [];

    for (var bind in binds) {
      try {
        _incrementBindReference(bind.instance.runtimeType);
        Bind.register(bind);
      } catch (e) {
        queueBinds.add(bind);
      }
    }
    if (queueBinds.length < binds.length) {
      _recursiveRegisterBinds(queueBinds);
    } else if (queueBinds.isNotEmpty) {
      for (var bind in queueBinds) {
        _incrementBindReference(bind.instance.runtimeType);
        Bind.register(bind);
      }
    }
  }

  void unregisterBinds(Module module) {
    if (_appModule != null && module == _appModule!) return;

    if (_activeRoutes[module]?.isNotEmpty ?? false) return;

    if (Modular.debugLogDiagnostics) {
      log(
          'DISPOSED: ${module.runtimeType} BINDS: ${[
            ...module.binds.map((e) => e.instance.runtimeType.toString()),
            ...module.imports.map((e) => e.binds.map((e) => e.instance.runtimeType.toString()).toList())
          ]}',
          name: "🗑️");
    }

    for (var bind in module.binds) {
      _decrementBindReference(bind.instance.runtimeType);
    }

    if (module.imports.isNotEmpty) {
      for (var importedModule in module.imports) {
        for (var bind in importedModule.binds) {
          if (_appModule?.binds.contains(bind) ?? false) continue;
          _decrementBindReference(bind.instance.runtimeType);
        }
      }
    }
    bindsToDispose.map((type) => Bind.disposeByType(type)).toList();
    bindsToDispose.clear();

    _activeRoutes.remove(module);
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
        bindsToDispose.add(type);
      }
    }
  }

  void registerRoute(String route, Module module) {
    _activeRoutes.putIfAbsent(module, () => {});
    _activeRoutes[module]?.add(route);
  }

  void unregisterRoute(String route, Module module) {
    _activeRoutes[module]?.remove(route);
    if (_activeRoutes[module]?.isEmpty ?? true) {
      unregisterBinds(module);
    }
  }
}
