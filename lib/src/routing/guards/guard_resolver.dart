import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/src/routing/guards/guard_fn.dart';
import 'package:go_router_modular/src/routing/guards/modular_guard.dart';

/// Reduz uma lista de [ModularGuard] (mais um `redirect` legado opcional) a uma
/// única função de `redirect` do go_router, com resolução em curto-circuito:
/// "primeiro que barrar vence".
///
/// O `redirect` legado (`@Deprecated`), quando informado, é tratado como o
/// último elo da cadeia — equivale a `[...guards, GuardFn(legacyRedirect)]`.
///
/// Retorna `null` quando não há guard nem `redirect` legado, para que a rota
/// não receba um `redirect` desnecessário.
FutureOr<String?> Function(BuildContext context, GoRouterState state)?
    resolveGuards(
  List<ModularGuard> guards, {
  FutureOr<String?> Function(BuildContext context, GoRouterState state)?
      legacyRedirect,
}) {
  final chain = <ModularGuard>[
    ...guards,
    if (legacyRedirect != null) GuardFn(legacyRedirect),
  ];

  if (chain.isEmpty) return null;

  return (context, state) => _runChain(chain, context, state);
}

Future<String?> _runChain(
  List<ModularGuard> chain,
  BuildContext context,
  GoRouterState state,
) async {
  for (final guard in chain) {
    final redirectTarget = await guard.redirect(context, state);
    if (redirectTarget != null) return redirectTarget;
  }
  return null;
}
