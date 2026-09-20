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
  const ModuleRouteLifecycle();

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

  /// The module's page was created: claim the reference the redirect opened.
  void claimModule(Module mod) {
    InjectionManager.instance.claimModuleReference(mod);
  }

  /// The module's page was disposed: release the reference.
  ///
  /// [InjectionManager]'s reference counting is what keeps a module that is
  /// still on the stack (A to B back to A, or a running transition) from being
  /// disposed too early.
  void disposeModule(Module mod) {
    InjectionManager.instance.unregisterModule(mod);
  }
}
