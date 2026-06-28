// Verifica que RouteGuard e GuardFn são acessíveis APENAS pelo barril
// principal, sem imports de `src/`. Se o export sumir, este arquivo não compila.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

/// Subclasse de RouteGuard declarada usando só o import do barril.
class _BarrelGuard extends RouteGuard {
  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) => null;
}

void main() {
  test('RouteGuard e GuardFn vêm do barril principal', () {
    expect(_BarrelGuard(), isA<RouteGuard>());
    expect(GuardFn((_, __) => null), isA<RouteGuard>());
  });

  test('GuardFn declarado a partir do barril é usável em guards: []', () {
    final route = ChildRoute(
      '/',
      child: (_, __) => const SizedBox(),
      guards: [GuardFn((_, __) => '/login'), _BarrelGuard()],
    );
    expect(route.guards, hasLength(2));
  });
}
