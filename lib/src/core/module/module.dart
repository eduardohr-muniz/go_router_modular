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

abstract class Module {
  FutureOr<List<Module>> imports() => [];

  /// Seguindo o padrão do flutter_modular: recebe o injector e registra os binds diretamente
  void binds(Injector i) {}

  /// DEPRECATED: Use binds(Injector i) em vez disso
  @Deprecated('Use binds(Injector i) para seguir o padrão do flutter_modular')
  FutureOr<List<Bind<Object>>> legacyBinds() => [];
  List<ModularRoute> get routes => const [];

  void initState(Injector i) {}
  void dispose() {}

  List<RouteBase> configureRoutes({String modulePath = '', bool topLevel = false}) {
    List<RouteBase> result = [];
    InjectionManager.instance.registerAppModule(this);

    result.addAll(_createChildRoutes(topLevel: topLevel));
    result.addAll(_createModuleRoutes(modulePath: modulePath, topLevel: topLevel));
    result.addAll(_createShellRoutes(topLevel, modulePath));

    return result;
  }

  Set<Module> didChangeGoingReference = {};
}
