import 'dart:async';
import 'dart:developer';
import 'package:go_router_modular/src/bind.dart';
import 'package:go_router_modular/src/delay_dispose.dart';
import 'package:go_router_modular/src/go_router_modular_configure.dart';
import 'package:go_router_modular/src/module.dart';

class RouteManager {
  static final RouteManager _instance = RouteManager._();
  final Map<Module, Set<String>> _activeRoutes = {};
  final Map<Type, int> _bindReferences = {};
  final Map<Module, Timer> _disposeTimers = {};
  Module? _appModule;
  List<Type> bindsToDispose = [];
  final Map<String, Module> _routes = {};
  final Map<String, DateTime> _routeLastAccess = {};
  static const _routeTimeout = Duration(minutes: 30);

  RouteManager._();

  factory RouteManager() {
    return _instance;
  }

  Future<void> registerBindsAppModule(Module module) async {
    if (_appModule != null) return;
    _appModule = module;
    await registerBindsIfNeeded(module);
  }

  Future<void> registerBindsIfNeeded(Module module) async {
    if (_activeRoutes.containsKey(module)) return;
    List<Bind<Object>> allBinds = [
      ...module.binds,
      ...module.imports.map((e) => e.binds).expand((e) => e)
    ];
    await _recursiveRegisterBinds(allBinds);

    _activeRoutes[module] = {};

    if (Modular.debugLogDiagnostics) {
      log(
          'INJECTED: ${module.runtimeType} BINDS: ${[
            ...module.binds.map((e) => e.instance.runtimeType.toString()),
            ...module.imports.map((e) =>
                e.binds.map((e) => e.instance.runtimeType.toString()).toList())
          ]}',
          name: "💉");
    }
  }

  Future<void> _recursiveRegisterBinds(List<Bind<Object>> binds) async {
    if (binds.isEmpty) return;
    List<Bind<Object>> queueBinds = [];

    for (var bind in binds) {
      try {
        _incrementBindReference(bind.instance.runtimeType);
        await Bind.register(bind);
      } catch (e) {
        queueBinds.add(bind);
      }
    }
    if (queueBinds.length < binds.length) {
      await _recursiveRegisterBinds(queueBinds);
    } else if (queueBinds.isNotEmpty) {
      for (var bind in queueBinds) {
        _incrementBindReference(bind.instance.runtimeType);
        await Bind.register(bind);
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
            ...module.imports.map((e) =>
                e.binds.map((e) => e.instance.runtimeType.toString()).toList())
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

  void _cleanupRoutes() {
    final now = DateTime.now();
    _routeLastAccess.removeWhere((path, lastAccess) {
      if (now.difference(lastAccess) > _routeTimeout) {
        _routes.remove(path);
        return true;
      }
      return false;
    });
  }

  void registerRoute(String path, Module module) {
    _cleanupRoutes();

    if (path.isEmpty) {
      throw ArgumentError('Path cannot be empty');
    }

    if (_routes.containsKey(path)) {
      throw StateError('Route $path already registered');
    }

    _routes[path] = module;
    _routeLastAccess[path] = DateTime.now();
  }

  void unregisterRoute(String path) {
    _routes.remove(path);
    _routeLastAccess.remove(path);
  }

  void dispose() {
    for (var timer in _disposeTimers.values) {
      timer.cancel();
    }
    _disposeTimers.clear();
    _activeRoutes.clear();
    _bindReferences.clear();
    bindsToDispose.clear();
    _routes.clear();
    _routeLastAccess.clear();
  }
}
