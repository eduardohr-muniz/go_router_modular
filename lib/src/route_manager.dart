import 'dart:async';
import 'dart:developer';
import 'package:flutter/widgets.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/delay_dispose.dart';
import 'package:go_router_modular/src/internal_logs.dart';

class RouteManager {
  static final RouteManager _instance = RouteManager._();
  final Map<Module, Set<String>> _activeRoutes = {};
  final Map<Type, int> _bindReferences = {};
  Module? _appModule;
  List<Type> bindsToDispose = [];
  final Injector _injector = Injector();

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
  List<Bind<Object>> _getAllImportedBindsRecursively(Module module, [Set<Module>? visited]) {
    visited ??= <Module>{};
    Set<Bind<Object>> allImportedBinds = {};

    // Evita loops infinitos
    if (visited.contains(module)) {
      return allImportedBinds.toList();
    }
    visited.add(module);

    for (var importedModule in module.imports) {
      // Adiciona os binds do módulo importado
      allImportedBinds.addAll(importedModule.binds);

      // Recursivamente coleta binds dos imports do módulo importado
      allImportedBinds.addAll(_getAllImportedBindsRecursively(importedModule, visited));
    }

    return allImportedBinds.toList();
  }

  void registerBindsIfNeeded(Module module) {
    iLog('🔍 CHECKING MODULE: ${module.runtimeType}', name: "ROUTE_MANAGER");

    if (_activeRoutes.containsKey(module)) {
      iLog('⚠️ MÓDULO JÁ REGISTRADO: ${module.runtimeType}', name: "ROUTE_MANAGER");
      return;
    }

    iLog('📦 INICIANDO REGISTRO: ${module.runtimeType}', name: "ROUTE_MANAGER");
    iLog('📦 NÚMERO DE BINDS DO MÓDULO: ${module.binds.length}', name: "ROUTE_MANAGER");
    iLog('📦 IMPORTS DO MÓDULO: ${module.imports.map((e) => e.runtimeType).toList()}', name: "ROUTE_MANAGER");

    final importedBindings = _getAllImportedBindsRecursively(module);

    List<Bind<Object>> allBinds = [...module.binds, ...importedBindings];
    iLog('📦 TOTAL DE BINDS PARA REGISTRAR: ${allBinds.length}', name: "ROUTE_MANAGER");

    _recursiveRegisterBinds(allBinds);

    _activeRoutes[module] = {};
    module.initState(_injector);
    iLog('✅ MÓDULO REGISTRADO: ${module.runtimeType}', name: "ROUTE_MANAGER");

    if (Modular.debugLogDiagnostics) {
      log('INJECTED: ${module.runtimeType} BINDS: ${[...module.binds.map((e) => e.instance.runtimeType.toString()), ...module.imports.map((e) => e.binds.map((e) => e.instance.runtimeType.toString()).toList())]}', name: "💉");
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

  void unregisterBinds(Module module) {
    iLog('🗑️ INICIANDO UNREGISTER: ${module.runtimeType}', name: "ROUTE_MANAGER");

    if (_appModule != null && module == _appModule!) {
      iLog('⛔ NÃO PODE DISPOSAR APP MODULE: ${module.runtimeType}', name: "ROUTE_MANAGER");
      return;
    }

    // if (_activeRoutes[module]?.isNotEmpty ?? false) {
    //   iLog('⚠️ MÓDULO AINDA TEM ROTAS ATIVAS: ${module.runtimeType} - ${_activeRoutes[module]}', name: "ROUTE_MANAGER");
    //   return;
    // }

    iLog('🗑️ DISPOSANDO MÓDULO: ${module.runtimeType}', name: "ROUTE_MANAGER");

    if (Modular.debugLogDiagnostics) {
      log('DISPOSED: ${module.runtimeType} BINDS: ${[...module.binds.map((e) => e.instance.runtimeType.toString()), ...module.imports.map((e) => e.binds.map((e) => e.instance.runtimeType.toString()).toList())]}', name: "🗑️");
    }

    for (var bind in module.binds) {
      try {
        iLog('📉 DECREMENTANDO REFERÊNCIA: ${bind.instance.runtimeType}', name: "ROUTE_MANAGER");
        _decrementBindReference(bind.instance.runtimeType);
      } catch (e) {
        iLog('⚠️ ERRO AO DECREMENTAR: ${bind.runtimeType} - $e', name: "ROUTE_MANAGER");
      }
    }

    if (module.imports.isNotEmpty) {
      for (var importedModule in module.imports) {
        for (var bind in importedModule.binds) {
          if (_appModule?.binds.contains(bind) ?? false) {
            iLog('⛔ PULANDO BIND DO APP MODULE: ${bind.runtimeType}', name: "ROUTE_MANAGER");
            continue;
          }
          try {
            iLog('📉 DECREMENTANDO IMPORT: ${bind.instance.runtimeType}', name: "ROUTE_MANAGER");
            _decrementBindReference(bind.instance.runtimeType);
          } catch (e) {
            iLog('⚠️ ERRO AO DECREMENTAR IMPORT: ${bind.runtimeType} - $e', name: "ROUTE_MANAGER");
          }
        }
      }
    }

    iLog('🗑️ DISPOSANDO ${bindsToDispose.length} BINDS', name: "ROUTE_MANAGER");
    bindsToDispose.map((type) => Bind.disposeByType(type)).toList();
    bindsToDispose.clear();

    _activeRoutes.remove(module);

    // Notifica o módulo para limpar seu cache de transições
    _notifyModuleDisposed(module);

    iLog('✅ MÓDULO REMOVIDO: ${module.runtimeType}', name: "ROUTE_MANAGER");
  }

  // Notifica que um módulo foi disposto para limpeza de cache
  void _notifyModuleDisposed(Module module) {
    // Importa dinamicamente para evitar dependência circular
    // O Module tem acesso estático ao método de limpeza
    module.cleanModuleTransitionCache();
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
