import 'dart:async';
import 'dart:developer';
import 'package:go_router_modular/go_router_modular.dart';

class RouteManager {
  static RouteManager? _instance;
  RouteManager._();
  static RouteManager get instance => _instance ??= RouteManager._();

  final Map<Type, int> _bindReferences = {};
  Module? _appModule;

  final Injector _injector = Injector();

  final Map<Module, Set<Type>> _moduleBindTypes = {};

  bool _isBindForAppModule(Type type) {
    return _moduleBindTypes[_appModule]?.contains(type) ?? false;
  }

  void registerAppModule(Module module) {
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

  void _recursiveRegisterBinds(List<Bind<Object>> binds, [int maxAttempts = 10]) {
    if (binds.isEmpty || maxAttempts <= 0) {
      return;
    }

    List<Bind<Object>> failedBinds = [];

    for (var bind in binds) {
      try {
        // Captura erro ao acessar instance
        final type = bind.instance.runtimeType;
        _incrementBindReference(type);
        Bind.register(bind);
      } catch (e) {
        failedBinds.add(bind);
      }
    }

    // Se ainda há binds que falharam, tenta novamente
    if (failedBinds.isNotEmpty && failedBinds.length < binds.length) {
      _recursiveRegisterBinds(failedBinds, maxAttempts - 1);
    } else if (failedBinds.isNotEmpty) {
      for (var bind in failedBinds) {
        //TODO: PRINT DE ERROS DE BIND NAO RESOLVIDOS
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
