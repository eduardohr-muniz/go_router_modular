import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/src/routing/guards/modular_guard.dart';

/// Adapta uma função `redirect` para um [ModularGuard].
///
/// Útil quando você não quer criar uma classe dedicada para uma regra simples:
/// ```dart
/// ChildRoute(
///   '/beta',
///   guards: [GuardFn((context, state) => isBeta ? null : '/home')],
///   child: (context, state) => const BetaPage(),
/// );
/// ```
///
/// Também é a ponte usada internamente para compor o parâmetro `redirect`
/// (deprecado) das rotas como o último elo da cadeia de guards.
class GuardFn extends ModularGuard {
  /// Função delegada que decide o destino da navegação.
  final FutureOr<String?> Function(BuildContext context, GoRouterState state) callback;

  const GuardFn(this.callback);

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) => callback(context, state);
}
