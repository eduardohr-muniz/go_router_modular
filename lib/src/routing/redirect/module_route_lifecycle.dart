import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/src/di/injection_manager.dart';
import 'package:go_router_modular/src/module/module.dart';
import 'package:go_router_modular/src/routing/route_with_completer_service.dart';
import 'package:go_router_modular/src/shared/exception.dart';
import 'package:go_router_modular/src/ui/modular_loader.dart';

/// Coordena o ciclo de vida de módulos durante o roteamento: registra os binds
/// do módulo no `redirect` (com loader) ao entrar, e descarta o módulo ao sair,
/// respeitando a proteção contra descarte prematuro do módulo pai.
///
/// Extraído de `route_builder.dart` para isolar a responsabilidade de ciclo de
/// vida/redirect da construção de rotas (Single Responsibility).
class ModuleRouteLifecycle {
  ModuleRouteLifecycle(this.parentModule);

  /// Módulo que está construindo estas rotas (usado para a proteção de transição).
  final Module parentModule;

  FutureOr<String?> redirectAndInjectBinds(
    BuildContext context,
    GoRouterState state, {
    required Module module,
    FutureOr<String?> Function(BuildContext, GoRouterState)? redirect,
  }) async {
    final shouldShowLoader = !RouteWithCompleterService.hasRouteCompleter();

    try {
      final completer = RouteWithCompleterService.getLastCompleteRoute();
      if (shouldShowLoader) ModularLoader.show();
      await InjectionManager.instance.registerBindsModule(module);
      completer.complete();
    } catch (e) {
      if (e is ModularException) {
        log('${e.message}', name: 'GO_ROUTER_MODULAR');
        rethrow;
      }
    } finally {
      if (shouldShowLoader) ModularLoader.hide();
    }

    if (context.mounted) return redirect?.call(context, state);
    return null;
  }

  void disposeModule(Module mod) {
    if (parentModule.didChangeGoingReference.contains(mod)) return;
    InjectionManager.instance.unregisterModule(mod);
  }

  /// Descarta os módulos das branches e, em seguida, o próprio módulo do shell.
  void disposeStatefulShellModule(Module shellMod, List<Module> branchModules) {
    for (final branchModule in branchModules) {
      if (parentModule.didChangeGoingReference.contains(branchModule)) continue;
      InjectionManager.instance.unregisterModule(branchModule);
    }
    disposeModule(shellMod);
  }
}
