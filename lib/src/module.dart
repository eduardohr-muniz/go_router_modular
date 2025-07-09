import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/src/bind.dart';
import 'package:go_router_modular/src/go_router_modular_configure.dart';
import 'package:go_router_modular/src/internal_logs.dart';
import 'package:go_router_modular/src/route_manager.dart';
import 'package:go_router_modular/src/routes/child_route.dart';
import 'package:go_router_modular/src/routes/i_modular_route.dart';
import 'package:go_router_modular/src/routes/module_route.dart';
import 'package:go_router_modular/src/routes/shell_modular_route.dart';
import 'package:go_router_modular/src/transition.dart';

abstract class Module {
  List<Module> get imports => const [];
  List<Bind<Object>> get binds => const [];
  List<ModularRoute> get routes => const [];

  /// Coleta todos os binds disponíveis recursivamente evitando duplicatas
  List<Bind<Object>> getModuleBindsAvaliable() {
    final List<Bind<Object>> availableBinds = [];
    final Set<Module> processedModules = {};

    _collectBindsRecursively(this, availableBinds, processedModules);

    return availableBinds;
  }

  void _collectBindsRecursively(Module module, List<Bind<Object>> availableBinds, Set<Module> processedModules) {
    // Evita loops infinitos se houver importações circulares
    if (processedModules.contains(module)) {
      return;
    }

    processedModules.add(module);

    // Adiciona os binds do módulo atual se não existirem
    for (final bind in module.binds) {
      if (!availableBinds.contains(bind)) {
        availableBinds.add(bind);
      }
    }

    // Processa recursivamente todos os imports
    for (final importedModule in module.imports) {
      _collectBindsRecursively(importedModule, availableBinds, processedModules);
    }
  }

  List<RouteBase> configureRoutes({String modulePath = '', bool topLevel = false}) {
    List<RouteBase> result = [];
    RouteManager().registerBindsAppModule(this);

    result.addAll(_createChildRoutes(topLevel: topLevel));
    result.addAll(_createModuleRoutes(modulePath: modulePath, topLevel: topLevel));
    result.addAll(_createShellRoutes(topLevel));

    return result;
  }

  GoRoute _createChild({required ChildRoute childRoute, required bool topLevel}) {
    return GoRoute(
      path: _normalizePath(path: childRoute.path, topLevel: topLevel),
      name: childRoute.name,
      builder: (context, state) => _buildRouteChild(
        context,
        state: state,
        route: childRoute,
      ),
      pageBuilder: childRoute.pageBuilder != null
          ? (context, state) => childRoute.pageBuilder!(context, state)
          : (context, state) => _buildCustomTransitionPage(
                context,
                state: state,
                route: childRoute,
              ),
      parentNavigatorKey: childRoute.parentNavigatorKey,
      redirect: childRoute.redirect,
      onExit: (context, state) => _handleRouteExit(context, state: state, route: childRoute, module: this),
    );
  }

  List<GoRoute> _createChildRoutes({required bool topLevel}) {
    return routes.whereType<ChildRoute>().where((route) => adjustRoute(route.path) != '/').map((route) {
      return _createChild(childRoute: route, topLevel: topLevel);
    }).toList();
  }

  GoRoute _createModule({required ModuleRoute module, required String modulePath, required bool topLevel}) {
    final childRoute = module.module.routes.whereType<ChildRoute>().where((route) => adjustRoute(route.path) == '/').firstOrNull;

    return GoRoute(
      path: _normalizePath(path: module.path + (childRoute?.path ?? ""), topLevel: topLevel),
      name: childRoute?.name ?? module.name,
      builder: (context, state) => _buildModuleChild(context, state: state, module: module, route: childRoute),
      routes: module.module.configureRoutes(modulePath: module.path, topLevel: false),
      parentNavigatorKey: childRoute?.parentNavigatorKey,
      redirect: childRoute?.redirect,
      onExit: (context, state) => childRoute == null ? Future.value(true) : _handleRouteExit(context, state: state, route: childRoute, module: module.module),
    );
  }

  List<GoRoute> _createModuleRoutes({required String modulePath, required bool topLevel}) {
    return routes.whereType<ModuleRoute>().map((module) {
      return _createModule(module: module, modulePath: modulePath, topLevel: topLevel);
    }).toList();
  }

  List<RouteBase> _createShellRoutes(bool topLevel) {
    return routes.whereType<ShellModularRoute>().map((shellRoute) {
      // if (shellRoute.routes.whereType<ChildRoute>().where((element) => element.path == '/').isNotEmpty) {
      //   throw Exception('ShellModularRoute cannot contain ChildRoute with path "/"');
      // }
      return ShellRoute(
        builder: (context, state, child) => shellRoute.builder!(context, state, child),
        pageBuilder: shellRoute.pageBuilder != null ? (context, state, child) => shellRoute.pageBuilder!(context, state, child) : null,
        redirect: shellRoute.redirect,
        navigatorKey: shellRoute.navigatorKey,
        observers: shellRoute.observers,
        parentNavigatorKey: shellRoute.parentNavigatorKey,
        restorationScopeId: shellRoute.restorationScopeId,
        routes: shellRoute.routes
            .map((routeOrModule) {
              if (routeOrModule is ChildRoute) {
                return _createChild(childRoute: routeOrModule, topLevel: topLevel);
              } else if (routeOrModule is ModuleRoute) {
                return _createModule(module: routeOrModule, modulePath: routeOrModule.path, topLevel: topLevel);
              }
              return null;
            })
            .whereType<RouteBase>()
            .toList(),
      );
    }).toList();
  }

  String adjustRoute(String route) {
    if (route == "/") {
      return "/";
    } else if (route.startsWith("/:")) {
      return "/";
    } else {
      return route;
    }
  }

  String _normalizePath({required String path, required bool topLevel}) {
    if (path.startsWith("/") && !topLevel && !path.startsWith("/:")) {
      path = path.substring(1);
    }
    return _buildPath(path);
  }

  Widget _buildRouteChild(BuildContext context, {required GoRouterState state, required ChildRoute route}) {
    // Executa registro com prioridade (fire and forget - não bloqueia UI)
    iLog('📱 BUILD ChildRoute: ${state.uri} - Módulo: $runtimeType', name: "BUILD_DEBUG");
    _register(path: state.uri.toString());
    return route.child(context, state);
  }

  Page<void> _buildCustomTransitionPage(BuildContext context, {required GoRouterState state, required ChildRoute route}) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: route.child(context, state),
      transitionsBuilder: Transition.builder(
        configRouteManager: () {
          final cacheKey = '$runtimeType:${state.uri}';
          if (!_transitionCache.contains(cacheKey)) {
            iLog('🎬 TRANSITION: ${state.uri} - Módulo: $runtimeType', name: "BUILD_DEBUG");
            _transitionCache.add(cacheKey);
            _register(path: state.uri.toString());

            // Remove do cache após um delay para permitir re-registro quando necessário
            Timer(const Duration(seconds: 2), () {
              _transitionCache.remove(cacheKey);
            });
          } else {
            iLog('🚫 TRANSITION IGNORADA (CACHE): ${state.uri} - Módulo: $runtimeType', name: "BUILD_DEBUG");
          }
        },
        pageTransition: route.pageTransition ?? Modular.getDefaultPageTransition,
      ),
    );
  }

  Widget _buildModuleChild(BuildContext context, {required GoRouterState state, required ModuleRoute module, ChildRoute? route}) {
    // Executa registro com prioridade (fire and forget - não bloqueia UI)
    iLog('📱 BUILD ModuleChild: ${state.uri} - Módulo: ${module.module.runtimeType}', name: "BUILD_DEBUG");
    _register(path: state.uri.toString(), module: module.module);
    return route?.child(context, state) ?? Container();
  }

  FutureOr<bool> _handleRouteExit(BuildContext context, {required GoRouterState state, required ChildRoute route, required Module module}) {
    iLog('🚪 EXIT ROUTE: ${state.uri} - Módulo: ${module.runtimeType}', name: "EXIT_DEBUG");
    final completer = Completer<bool>();
    final onExit = route.onExit?.call(context, state) ?? Future.value(true);
    completer.complete(onExit);
    return completer.future.then((exit) {
      try {
        if (exit) {
          iLog('🗑️ UNREGISTERING: ${state.uri} - Módulo: ${module.runtimeType}', name: "EXIT_DEBUG");
          _unregister(state.uri.toString(), module: module);
        } else {
          iLog('❌ EXIT BLOCKED: ${state.uri} - Módulo: ${module.runtimeType}', name: "EXIT_DEBUG");
        }
        return exit;
      } catch (e) {
        iLog('💥 ERROR ON EXIT: ${state.uri} - Módulo: ${module.runtimeType} - Error: $e', name: "EXIT_DEBUG");
        return false;
      }
    });
  }

  // Sistema de prioridade para _register - evita execuções simultâneas
  static final Map<String, Completer<void>> _registerQueue = {};

  // Cache para evitar registros repetidos em transições
  static final Set<String> _transitionCache = {};

  Future<void> _register({required String path, Module? module}) async {
    final targetModule = module ?? this;
    final queueKey = '${targetModule.runtimeType}:$path';

    iLog('🎯 REGISTER CHAMADO: ${targetModule.runtimeType} para path: $path', name: "PRIORITY_DEBUG");

    // Se já está executando para esta combinação módulo+path, aguarda completar
    if (_registerQueue.containsKey(queueKey)) {
      iLog('⏳ AGUARDANDO EXECUÇÃO EM ANDAMENTO: $queueKey', name: "PRIORITY_DEBUG");
      await _registerQueue[queueKey]!.future;
      iLog('✅ EXECUÇÃO COMPLETADA - RETORNANDO: $queueKey', name: "PRIORITY_DEBUG");
      return;
    }

    // Cria completer para esta execução
    iLog('🚀 INICIANDO EXECUÇÃO PRIORITÁRIA: $queueKey', name: "PRIORITY_DEBUG");
    final completer = Completer<void>();
    _registerQueue[queueKey] = completer;

    try {
      // Executa o registro com prioridade
      iLog('💉 REGISTERING BINDS: ${targetModule.runtimeType} para path: $path', name: "BIND_REGISTER");
      RouteManager().registerBindsIfNeeded(targetModule);
      if (path != '/') {
        RouteManager().registerRoute(path, targetModule);
      }
      iLog('✅ BINDS REGISTERED: ${targetModule.runtimeType} para path: $path', name: "BIND_REGISTER");
    } finally {
      // Remove da fila e completa
      iLog('🏁 FINALIZANDO EXECUÇÃO: $queueKey', name: "PRIORITY_DEBUG");
      _registerQueue.remove(queueKey);
      completer.complete();
    }
  }

  void _unregister(String path, {Module? module}) {
    final targetModule = module ?? this;
    iLog('🗑️ UNREGISTER: ${targetModule.runtimeType} para path: $path', name: "UNREGISTER_DEBUG");
    RouteManager().unregisterRoute(path, targetModule);

    // Limpa o cache de transições quando o módulo é unregistered
    _cleanTransitionCache(targetModule);

    iLog('✅ UNREGISTER COMPLETADO: ${targetModule.runtimeType} para path: $path', name: "UNREGISTER_DEBUG");
  }

  // Limpa entradas do cache de transições para um módulo específico
  static void _cleanTransitionCache(Module module) {
    final keysToRemove = _transitionCache.where((key) => key.startsWith('${module.runtimeType}:')).toList();
    for (final key in keysToRemove) {
      _transitionCache.remove(key);
      iLog('🧹 CACHE LIMPO: $key', name: "UNREGISTER_DEBUG");
    }
  }

  // Método público para limpeza de cache chamado pelo RouteManager
  void cleanModuleTransitionCache() {
    _cleanTransitionCache(this);
  }

  String _buildPath(String path) {
    if (!path.endsWith('/')) {
      path = '$path/';
    }
    path = path.replaceAll(RegExp(r'/+'), '/');
    if (path == '/') return path;
    return path.substring(0, path.length - 1);
  }
}
