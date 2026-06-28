// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

class _EmptyModule extends Module {
  @override
  List<ModularRoute> get routes => const [];
}

void main() {
  group('campo guards nos tipos de rota', () {
    test('ChildRoute: default const [] e aceita guards', () {
      final semGuards = ChildRoute('/', child: (_, __) => const SizedBox());
      expect(semGuards.guards, isEmpty);

      final guard = GuardFn((_, __) => null);
      final comGuards =
          ChildRoute('/', child: (_, __) => const SizedBox(), guards: [guard]);
      expect(comGuards.guards, [guard]);
    });

    test('ChildRoute: redirect legado continua aceito (compatibilidade)', () {
      final route = ChildRoute(
        '/',
        child: (_, __) => const SizedBox(),
        redirect: (_, __) => '/login',
      );
      expect(route.redirect, isNotNull);
      expect(route.guards, isEmpty);
    });

    test('ModuleRoute: default const [] e aceita guards', () {
      final route = ModuleRoute('/admin', module: _EmptyModule());
      expect(route.guards, isEmpty);

      final guard = GuardFn((_, __) => null);
      final guarded =
          ModuleRoute('/admin', module: _EmptyModule(), guards: [guard]);
      expect(guarded.guards, [guard]);
    });

    test('ShellModularRoute: default const [], aceita guards e redirect', () {
      final route = ShellModularRoute(
        builder: (_, __, child) => child,
        routes: const [],
      );
      expect(route.guards, isEmpty);

      final guard = GuardFn((_, __) => null);
      final guarded = ShellModularRoute(
        builder: (_, __, child) => child,
        routes: const [],
        guards: [guard],
        redirect: (_, __) => '/x',
      );
      expect(guarded.guards, [guard]);
      expect(guarded.redirect, isNotNull);
    });

    test('StatefulShellModularRoute: default const [], aceita guards e redirect',
        () {
      final guard = GuardFn((_, __) => null);
      final route = StatefulShellModularRoute(
        builder: (_, __, shell) => shell,
        guards: [guard],
        redirect: (_, __) => '/x',
        branches: [
          ModularBranch(
            routes: [ChildRoute('/home', child: (_, __) => const SizedBox())],
          ),
        ],
      );
      expect(route.guards, [guard]);
      expect(route.redirect, isNotNull);

      final semGuards = StatefulShellModularRoute(
        builder: (_, __, shell) => shell,
        branches: [
          ModularBranch(
            routes: [ChildRoute('/home', child: (_, __) => const SizedBox())],
          ),
        ],
      );
      expect(semGuards.guards, isEmpty);
    });

    test('guard concreto é um ModularGuard', () {
      expect(GuardFn((_, __) => null), isA<ModularGuard>());
    });
  });
}
