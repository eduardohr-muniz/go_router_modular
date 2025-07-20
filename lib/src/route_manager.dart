import 'dart:async';
import 'dart:developer';
import 'package:go_router_modular/go_router_modular.dart';

class RouteManager {
  static final RouteManager _instance = RouteManager._();
  final Map<Type, int> _bindReferences = {};
  Module? _appModule;

  final Injector _injector = Injector();

  final Map<Module, Set<Type>> _moduleBindTypes = {};

  bool _isBindForAppModule(Type type) {
    return _moduleBindTypes[_appModule]?.contains(type) ?? false;
  }

  RouteManager._();

  factory RouteManager() {
    return _instance;
  }

  void registerBindsAppModule(Module module) {
    if (_appModule != null) {
      return;
    }
    _appModule = module;
    registerBindsModule(module);
  }

  /// Coleta recursivamente todos os binds de imports aninhados
  Future<List<Bind<Object>>> _getAllImportedBindsRecursively(Module module, [Set<Module>? visited]) async {
    visited ??= <Module>{};
    Set<Bind<Object>> allImportedBinds = {};

    if (visited.contains(module)) {
      return allImportedBinds.toList();
    }
    visited.add(module);

    final imports = await module.imports();

    await Future.forEach(imports, (module) async {
      final binds = await module.binds();
      allImportedBinds.addAll(binds);
      allImportedBinds.addAll(await _getAllImportedBindsRecursively(module, visited));
    });

    return allImportedBinds.toList();
  }

  Future<void> registerBindsModule(Module module) async {
    if (_moduleBindTypes.containsKey(module)) {
      return;
    }

    final moduleBinds = await module.binds();

    final importedBinds = await _getAllImportedBindsRecursively(module);

    List<Bind<Object>> allBinds = [...moduleBinds, ...importedBinds];

    _recursiveRegisterBinds(allBinds);
    _moduleBindTypes[module] = allBinds.map((e) => e.instance.runtimeType).toSet();

    module.initState(_injector);

    if (Modular.debugLogDiagnostics) {
      log('INJECTED: ${module.runtimeType} BINDS: ${allBinds.map((e) => e.instance.runtimeType.toString()).toList()}', name: "💉");
    }
  }

  void _recursiveRegisterBinds(List<Bind<Object>> binds) {
    if (binds.isEmpty) {
      return;
    }

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
        try {
          _incrementBindReference(bind.instance.runtimeType);
          Bind.register(bind);
        } catch (e) {
          rethrow;
        }
      }
    }
  }

  Future<void> unregisterBinds(Module module) async {
    if (_appModule != null && module == _appModule!) {
      return;
    }

    final Set<Type> bindsToDispose = _moduleBindTypes[module] ?? {};

    List<Type> disposedBinds = [];

    for (var bind in bindsToDispose) {
      try {
        final disposed = _decrementBindReference(bind);
        if (disposed) {
          disposedBinds.add(bind);
        }
      } catch (_) {}
    }

    if (Modular.debugLogDiagnostics) {
      log('DISPOSED: ${module.runtimeType} BINDS: ${disposedBinds.map((e) => e.toString()).toList()}', name: "🗑️");
    }

    bindsToDispose.map((type) {
      if (_isBindForAppModule(type)) {
        return;
      }
      Bind.disposeByType(type);
    }).toList();
    bindsToDispose.clear();
  }

  // Notifica que um módulo foi disposto para limpeza de cache

  void _incrementBindReference(Type type) {
    if (_bindReferences.containsKey(type)) {
      _bindReferences[type] = (_bindReferences[type] ?? 0) + 1;
    } else {
      _bindReferences[type] = 1;
    }
  }

  bool _decrementBindReference(Type type) {
    if (_bindReferences.containsKey(type)) {
      _bindReferences[type] = (_bindReferences[type] ?? 1) - 1;
      if (_bindReferences[type] == 0) {
        _bindReferences.remove(type);

        return true;
      }
    }
    return false;
  }

  void unregisterModule(Module module) {
    module.dispose();
    unregisterBinds(module);
    _moduleBindTypes.remove(module);
  }
}
