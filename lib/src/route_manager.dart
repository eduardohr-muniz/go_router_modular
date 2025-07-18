import 'dart:async';
import 'dart:developer';
import 'package:flutter/widgets.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/utils/delay_dispose.dart';
import 'package:go_router_modular/src/utils/internal_logs.dart';

class RouteManager {
  static final RouteManager _instance = RouteManager._();
  final Map<Module, Set<String>> _activeRoutes = {};
  final Map<Type, int> _bindReferences = {};
  Module? _appModule;
  List<Type> bindsToDispose = [];
  final Injector _injector = Injector();

  final Map<Module, Set<Type>> _bindsToDispose = {};

  RouteManager._();

  factory RouteManager() {
    return _instance;
  }

  void registerBindsAppModule(Module module) {
    if (_appModule != null) {
      iLog('⚠️ APP MODULE JÁ REGISTRADO: ${module.runtimeType}', name: "ROUTE_MANAGER");
      return;
    }
    iLog('🏠 REGISTERING APP MODULE: ${module.runtimeType}', name: "ROUTE_MANAGER");
    _appModule = module;
    registerBindsIfNeeded(module);
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

  Future<void> registerBindsIfNeeded(Module module) async {
    iLog('🔍 CHECKING MODULE: ${module.runtimeType}', name: "ROUTE_MANAGER");

    if (_activeRoutes.containsKey(module)) {
      iLog('⚠️ MÓDULO JÁ REGISTRADO: ${module.runtimeType}', name: "ROUTE_MANAGER");
      return;
    }

    final moduleBinds = await module.binds();
    final imports = await module.imports();

    iLog('📦 INICIANDO REGISTRO: ${module.runtimeType}', name: "ROUTE_MANAGER");
    iLog('📦 NÚMERO DE BINDS DO MÓDULO: $moduleBinds.length}', name: "ROUTE_MANAGER");
    iLog('📦 IMPORTS DO MÓDULO: ${imports.map((e) => e.runtimeType).toList()}', name: "ROUTE_MANAGER");

    final importedBinds = await _getAllImportedBindsRecursively(module);

    List<Bind<Object>> allBinds = [...moduleBinds, ...importedBinds];
    iLog('📦 TOTAL DE BINDS PARA REGISTRAR: ${allBinds.length}', name: "ROUTE_MANAGER");

    _recursiveRegisterBinds(allBinds);
    _bindsToDispose[module] = allBinds.map((e) => e.instance.runtimeType).toSet();

    _activeRoutes[module] = {};
    module.initState(_injector);
    iLog('✅ MÓDULO REGISTRADO: ${module.runtimeType}', name: "ROUTE_MANAGER");

    if (Modular.debugLogDiagnostics) {
      log('INJECTED: ${module.runtimeType} BINDS: ${allBinds.map((e) => e.instance.runtimeType.toString()).toList()}', name: "💉");
    }
  }

  void _recursiveRegisterBinds(List<Bind<Object>> binds) {
    if (binds.isEmpty) {
      iLog('📦 NENHUM BIND PARA REGISTRAR', name: "ROUTE_MANAGER");
      return;
    }

    iLog('🔧 TENTANDO REGISTRAR ${binds.length} BINDS', name: "ROUTE_MANAGER");
    List<Bind<Object>> queueBinds = [];

    for (var bind in binds) {
      try {
        iLog('✅ REGISTRANDO BIND: ${bind.runtimeType}', name: "ROUTE_MANAGER");
        _incrementBindReference(bind.instance.runtimeType);
        Bind.register(bind);
        iLog('✅ BIND REGISTRADO COM SUCESSO: ${bind.instance.runtimeType}', name: "ROUTE_MANAGER");
      } catch (e) {
        iLog('❌ ERRO AO REGISTRAR BIND: ${bind.runtimeType} - $e', name: "ROUTE_MANAGER");
        queueBinds.add(bind);
      }
    }

    if (queueBinds.length < binds.length) {
      iLog('🔄 RECURSÃO COM ${queueBinds.length} BINDS NA FILA', name: "ROUTE_MANAGER");
      _recursiveRegisterBinds(queueBinds);
    } else if (queueBinds.isNotEmpty) {
      iLog('🚨 FORÇANDO REGISTRO DOS ${queueBinds.length} BINDS RESTANTES', name: "ROUTE_MANAGER");
      for (var bind in queueBinds) {
        try {
          iLog('🔨 FORÇANDO BIND: ${bind.runtimeType}', name: "ROUTE_MANAGER");
          _incrementBindReference(bind.instance.runtimeType);
          Bind.register(bind);
          iLog('✅ BIND FORÇADO COM SUCESSO: ${bind.instance.runtimeType}', name: "ROUTE_MANAGER");
        } catch (e) {
          iLog('💥 ERRO CRÍTICO NO BIND: ${bind.runtimeType} - $e', name: "ROUTE_MANAGER");
          rethrow;
        }
      }
    }
  }

  Future<void> unregisterBinds(Module module) async {
    iLog('🗑️ INICIANDO UNREGISTER: ${module.runtimeType}', name: "ROUTE_MANAGER");

    if (_appModule != null && module == _appModule!) {
      iLog('⛔ NÃO PODE DISPOSAR APP MODULE: ${module.runtimeType}', name: "ROUTE_MANAGER");
      return;
    }

    iLog('🗑️ DISPOSANDO MÓDULO: ${module.runtimeType}', name: "ROUTE_MANAGER");
    final List<Type> bindsToDispose = _bindsToDispose[module]?.toList() ?? [];

    if (Modular.debugLogDiagnostics) {
      log('DISPOSED: ${module.runtimeType} BINDS: ', name: "🗑️");
    }

    for (var bind in bindsToDispose) {
      try {
        iLog('📉 DECREMENTANDO REFERÊNCIA: ${bind.runtimeType}', name: "ROUTE_MANAGER");
        _decrementBindReference(bind.runtimeType);
      } catch (e) {
        iLog('⚠️ ERRO AO DECREMENTAR: ${bind.runtimeType} - $e', name: "ROUTE_MANAGER");
      }
    }

    iLog('🗑️ DISPOSANDO ${bindsToDispose.length} BINDS', name: "ROUTE_MANAGER");
    bindsToDispose.map((type) => Bind.disposeByType(type)).toList();
    bindsToDispose.clear();

    _activeRoutes.remove(module);

    iLog('✅ MÓDULO REMOVIDO: ${module.runtimeType}', name: "ROUTE_MANAGER");
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
        bindsToDispose.add(type);
      }
    }
  }

  void registerRoute(String route, Module module) {
    if (_modulesBeingDisposed.contains(module)) {
      iLog('⚠️ MÓDULO EM DISPOSE: ${module.runtimeType}', name: "ROUTE_MANAGER");
      return;
    }

    iLog('✅ REGISTRANDO ROTA: $route para ${module.runtimeType} DATE: ${DateTime.now().toIso8601String()}', name: "ROUTE_MANAGER");
    _activeRoutes.putIfAbsent(module, () => {});
    _activeRoutes[module]?.add(route);
    iLog('✅ ROTA REGISTRADA: ${module.runtimeType} agora tem ${_activeRoutes[module]?.length} rotas', name: "ROUTE_MANAGER");
  }

  final Set<Module> _modulesBeingDisposed = {};

  Timer? _timer;

  void _disposeModule(Module module) {
    module.dispose();
    unregisterBinds(module);
    _modulesBeingDisposed.remove(module);
  }

  void unregisterRoute(String route, Module module) {
    iLog('📍 REMOVENDO ROTA: $route de ${module.runtimeType} DATE: ${DateTime.now().toIso8601String()}', name: "ROUTE_MANAGER");
    _activeRoutes[module]?.remove(route);
    iLog('📊 ${module.runtimeType} agora tem ${_activeRoutes[module]?.length ?? 0} rotas', name: "ROUTE_MANAGER");

    iLog('⏰ INICIANDO TIMER DE DISPOSE (${modularDelayDisposeMilisenconds}ms)', name: "ROUTE_MANAGER");
    if (_activeRoutes[module]?.isNotEmpty ?? false) {
      iLog('⚠️ MÓDULO AINDA TEM ROTAS ATIVAS: ${module.runtimeType} - ${_activeRoutes[module]}', name: "ROUTE_MANAGER");
      return;
    }
    _modulesBeingDisposed.add(module);

    _timer?.cancel();

    _timer = Timer(const Duration(milliseconds: 500), () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _disposeModule(module);
      });
    });
  }
}
