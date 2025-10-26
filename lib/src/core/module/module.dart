import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/exceptions/asserts/module_assert.dart';
import 'package:go_router_modular/src/widgets/parent_widget_observer.dart';
part '_module_lifecycle.dart';
part '_route_builders.dart';
part '_route_creators.dart';
part '_path_utils.dart';

/// Typedef para melhor semântica de binds assíncronos
typedef FutureBinds = FutureOr<void>;
typedef FutureModules = FutureOr<List<Module>>;

abstract class Module {
  FutureModules imports() => [];

  /// Seguindo o padrão do flutter_modular: recebe o injector e registra os binds diretamente
  /// Suporta binds assíncronos para inicialização de dependências que precisam de await
  FutureBinds binds(Injector i) {}

  List<ModularRoute> get routes => const [];

  void initState(Injector i) {}
  void dispose() {}

  List<RouteBase> configureRoutes({
    String modulePath = '',
    bool topLevel = false,
    Duration? parentDuration,
    GoTransition? parentTransition,
  }) {
    List<RouteBase> result = [];
    InjectionManager.instance.registerAppModule(this);

    result.addAll(_createChildRoutes(
      topLevel: topLevel,
      parentDuration: parentDuration,
      parentTransition: parentTransition,
    ));
    result.addAll(_createModuleRoutes(
      modulePath: modulePath,
      topLevel: topLevel,
      parentDuration: parentDuration,
      parentTransition: parentTransition,
    ));
    result.addAll(_createShellRoutes(
      topLevel,
      modulePath,
      parentDuration: parentDuration,
      parentTransition: parentTransition,
    ));

    return result;
  }

  Set<Module> didChangeGoingReference = {};
}
