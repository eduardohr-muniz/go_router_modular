import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Proteção de rota declarativa e reutilizável.
///
/// Um [ModularGuard] é o `redirect` do go_router encapsulado e nomeado: ele
/// decide se a navegação para uma rota é liberada ou desviada. Declare uma
/// subclasse uma vez e reutilize-a em quantas rotas precisar, passando-a na
/// lista `guards` de `ChildRoute`, `ModuleRoute`, `ShellModularRoute` ou
/// `StatefulShellModularRoute`.
///
/// O método [redirect] recebe os mesmos argumentos que o go_router entrega ao
/// seu `redirect`:
/// - `context`: dá acesso ao container de injeção (`Modular.get<T>()`) — os
///   binds do módulo já estão registrados quando o guard roda — e à árvore de
///   widgets.
/// - `state`: dá acesso aos dados da navegação (`state.uri`,
///   `state.pathParameters`, `state.uri.queryParameters`, `state.extra`,
///   `state.matchedLocation`).
///
/// Retornar `null` libera a navegação; retornar uma rota redireciona para ela.
///
/// Exemplo:
/// ```dart
/// class AuthGuard extends ModularGuard {
///   @override
///   FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
///     final authService = Modular.get<AuthService>();
///     if (authService.isLogged) return null;
///     return '/login?from=${state.uri.path}';
///   }
/// }
/// ```
abstract class ModularGuard {
  const ModularGuard();

  /// Decide o destino da navegação para a rota protegida.
  ///
  /// Retorna `null` para liberar, ou a rota de destino para redirecionar.
  FutureOr<String?> redirect(BuildContext context, GoRouterState state);
}
