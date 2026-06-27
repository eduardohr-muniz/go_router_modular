import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/src/routing/route_with_completer_service.dart';

/// Centraliza o padrão de navegação assíncrona usado pelas variantes
/// (`goAsync`, `pushAsync`, `replaceAsync` e suas formas nomeadas):
/// registrar o completer, executar a navegação e completar invocando
/// `onComplete` quando a nova página é construída.
///
/// Extraído de `route_extension.dart` para eliminar a duplicação do mesmo
/// boilerplate em oito métodos (DRY).
class AsyncNavigationHelper {
  const AsyncNavigationHelper._();

  /// Executa [navigate] sob o protocolo de completer e retorna um [Future]
  /// que completa quando a navegação para [routeName] conclui.
  static Future<void> run(
    BuildContext context,
    String routeName, {
    required void Function(GoRouter router) navigate,
    VoidCallback? onComplete,
  }) {
    RouteWithCompleterService.setCompleteRoute(routeName);
    navigate(GoRouter.of(context));
    return RouteWithCompleterService.getLastCompleteRoute().future.then((_) {
      onComplete?.call();
    });
  }
}
