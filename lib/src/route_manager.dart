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
    if (_activeRoutes.containsKey(module)) return;

    final binds = [...module.binds, ...module.imports.expand((e) => e.binds)];
    for (final bind in binds) {
      final type = bind.instance.runtimeType;
      _bindInstances[type] = bind;
      _incrementBindReference(type);
      Bind.register(bind);
    }

    _activeRoutes[module] = {};
    dev.log(
        'INJECTED: ${module.runtimeType} BINDS: ${[
          ...module.binds.map((e) => e.instance.runtimeType.toString()),
          ...module.imports.map((e) =>
              e.binds.map((e) => e.instance.runtimeType.toString()).toList())
        ]}',
        name: "💉 GO_ROUTER_MODULAR");
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
    _bindReferences[type] = (_bindReferences[type] ?? 0) + 1;
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
}
