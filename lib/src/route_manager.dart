import 'dart:async';
import 'dart:developer';
import 'package:go_router_modular/go_router_modular.dart';

class RouteManager {
  static final RouteManager _instance = RouteManager._();
  final Map<Type, int> _bindReferences = {};
  Module? _appModule;
  final List<Type> _injectedBinds = [];
  final Injector _injector = Injector();

  final Map<Module, Set<Type>> _bindsToDispose = {};

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

    Future.forEach(imports, (module) async {
      final binds = await module.binds();
      allImportedBinds.addAll(binds);
      allImportedBinds.addAll(await _getAllImportedBindsRecursively(module, visited));
    });

    return allImportedBinds.toList();
  }

  Future<void> registerBindsModule(Module module) async {
    if (_injectedBinds.contains(module.runtimeType)) {
      return;
    }
    _injectedBinds.add(module.runtimeType);

    final moduleBinds = await module.binds();

    final importedBinds = await _getAllImportedBindsRecursively(module);

    List<Bind<Object>> allBinds = [...moduleBinds, ...importedBinds];

    _recursiveRegisterBinds(allBinds);
    _bindsToDispose[module] = allBinds.map((e) => e.instance.runtimeType).toSet();

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

    final List<Type> bindsToDispose = _bindsToDispose[module]?.toList() ?? [];

    if (Modular.debugLogDiagnostics) {
      log('DISPOSED: ${module.runtimeType} BINDS: ', name: "🗑️");
    }

    for (var bind in bindsToDispose) {
      try {
        _decrementBindReference(bind.runtimeType);
      } catch (e) {}
    }

    bindsToDispose.map((type) => Bind.disposeByType(type)).toList();
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

  void _decrementBindReference(Type type) {
    if (_bindReferences.containsKey(type)) {
      _bindReferences[type] = (_bindReferences[type] ?? 1) - 1;
      if (_bindReferences[type] == 0) {
        _bindReferences.remove(type);
      }
    }
  }

  // final Set<Module> _modulesBeingDisposed = {};

  void _disposeModule(Module module) {
    module.dispose();
    unregisterBinds(module);
    // _modulesBeingDisposed.remove(module);
    _injectedBinds.remove(module.runtimeType);
  }

  void unregisterModule(Module module) {
    // _modulesBeingDisposed.add(module);
    _disposeModule(module);
  }
}
