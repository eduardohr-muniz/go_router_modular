import 'dart:async';
import 'dart:developer';
import 'package:go_router_modular/src/bind.dart';
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
  final Set<Type> _disposedTypes = {};

  RouteManager._();

  factory RouteManager() {
    return _instance;
  }

  void _cancelAndRemoveTimer(Module module) {
    _disposeTimers[module]?.cancel();
    _disposeTimers.remove(module);
  }

  Future<void> registerBindsAppModule(Module module) async {
    if (_appModule != null) return;
    _appModule = module;
    await registerBindsIfNeeded(module);
  }

  Future<void> registerBindsIfNeeded(Module module) async {
    if (_activeRoutes.containsKey(module)) {
      return;
    }

    try {
      List<Bind<Object>> allBinds = [
        ...module.binds,
        ...module.imports.map((e) => e.binds).expand((e) => e)
      ];

      allBinds = allBinds.where((bind) {
        final type = bind.instance.runtimeType;
        final isAppModuleBind =
            _appModule?.binds.any((b) => b.instance.runtimeType == type) ??
                false;
        return !_bindReferences.containsKey(type) && !isAppModuleBind;
      }).toList();

      if (allBinds.isNotEmpty) {
        await _recursiveRegisterBinds(allBinds);
      }

      _activeRoutes[module] = {};

      if (Modular.debugLogDiagnostics) {
        final binds = [
          ...module.binds.map((e) => e.instance.runtimeType.toString()),
          ...module.imports.map((e) =>
              e.binds.map((e) => e.instance.runtimeType.toString()).toList())
        ];
        log('INJECTED: ${module.runtimeType} BINDS: ${binds.isEmpty ? "[]" : binds}',
            name: "💉");
      }
    } catch (e) {
      log('Error registering binds: $e', name: "⚠️");
      rethrow;
    }
  }

  Future<void> _recursiveRegisterBinds(List<Bind<Object>> binds) async {
    if (binds.isEmpty) return;
    List<Bind<Object>> queueBinds = [];

    for (var bind in binds) {
      try {
        final type = bind.instance.runtimeType;
        final isAppModuleBind =
            _appModule?.binds.any((b) => b.instance.runtimeType == type) ??
                false;

        if (!_bindReferences.containsKey(type) && !isAppModuleBind) {
          _incrementBindReference(type);
          await Bind.register(bind);
        }
      } catch (e) {
        queueBinds.add(bind);
      }
    }

    if (queueBinds.length < binds.length) {
      await _recursiveRegisterBinds(queueBinds);
    } else if (queueBinds.isNotEmpty) {
      for (var bind in queueBinds) {
        try {
          final type = bind.instance.runtimeType;
          final isAppModuleBind =
              _appModule?.binds.any((b) => b.instance.runtimeType == type) ??
                  false;

          if (!_bindReferences.containsKey(type) && !isAppModuleBind) {
            _incrementBindReference(type);
            await Bind.register(bind);
          }
        } catch (e) {
          log('Error in recursive bind registration: $e', name: "⚠️");
        }
      }
    }
  }

  void registerRoute(String path, Module module) {
    if (path.isEmpty) {
      throw ArgumentError('Path cannot be empty');
    }
    if (_routes.containsKey(path)) {
      throw StateError('Route $path already registered');
    }

    _routes[path] = module;
  }

  void unregisterRoute(String path) {
    final module = _routes[path];
    if (module != null) {
      _cancelAndRemoveTimer(module);
      unregisterBinds(module);
    }
    _routes.remove(path);
  }

  void unregisterBinds(Module module) {
    if (_appModule != null &&
        (module == _appModule || module.imports.contains(_appModule))) {
      return;
    }
    if (_activeRoutes[module]?.isNotEmpty ?? false) return;

    try {
      if (Modular.debugLogDiagnostics) {
        log(
            'DISPOSED: ${module.runtimeType} BINDS: ${[
              ...module.binds.map((e) => e.instance.runtimeType.toString()),
              ...module.imports.map((e) => e.binds
                  .map((e) => e.instance.runtimeType.toString())
                  .toList())
            ]}',
            name: "🗑️");
      }

      for (var bind in module.binds) {
        try {
          final type = bind.instance.runtimeType;
          if (_appModule?.binds.contains(bind) ?? false) continue;
          _decrementBindReference(type);
        } catch (e) {
          log('Error decrementing bind reference: $e', name: "⚠️");
        }
      }

      if (module.imports.isNotEmpty) {
        for (var importedModule in module.imports) {
          if (importedModule == _appModule) continue;

          for (var bind in importedModule.binds) {
            try {
              final type = bind.instance.runtimeType;
              if (_appModule?.binds.contains(bind) ?? false) continue;
              _decrementBindReference(type);
            } catch (e) {
              log('Error decrementing imported bind reference: $e', name: "⚠️");
            }
          }
        }
      }

      for (var type in bindsToDispose) {
        try {
          if (_appModule?.binds.any((b) => b.instance.runtimeType == type) ??
              false) {
            continue;
          }
          Bind.disposeByType(type);
        } catch (e) {
          log('Error disposing bind: $e', name: "⚠️");
        }
      }
      bindsToDispose.clear();

      _activeRoutes.remove(module);
    } catch (e) {
      log('Error in unregisterBinds: $e', name: "⚠️");
    }
  }

  void _incrementBindReference(Type type) {
    if (_disposedTypes.contains(type)) {
      throw StateError('Cannot increment reference for disposed type: $type');
    }

    _bindReferences[type] = (_bindReferences[type] ?? 0) + 1;
  }

  void _decrementBindReference(Type type) {
    if (!_bindReferences.containsKey(type)) {
      throw StateError(
          'Cannot decrement reference for unregistered type: $type');
    }

    final currentCount = _bindReferences[type]!;
    if (currentCount <= 0) {
      throw StateError('Reference count cannot be negative for type: $type');
    }

    _bindReferences[type] = currentCount - 1;

    if (_bindReferences[type] == 0) {
      _bindReferences.remove(type);
      _disposedTypes.add(type);
      bindsToDispose.add(type);
    }
  }
}
