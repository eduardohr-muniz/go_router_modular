import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/src/routing/guards/guard_fn.dart';
import 'package:go_router_modular/src/routing/guards/guard_resolver.dart';
import 'package:go_router_modular/src/routing/guards/route_guard.dart';

/// Guard síncrono que sempre devolve [target] (use `null` para liberar) e
/// registra seu [label] em [evaluations] ao ser avaliado.
class _FixedGuard extends RouteGuard {
  _FixedGuard.named(this.target, this.evaluations, this.label);
  final String? target;
  final List<String> evaluations;
  final String label;

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    evaluations.add(label);
    return target;
  }
}

/// Guard assíncrono que resolve para [target] após um microtask.
class _AsyncGuard extends RouteGuard {
  _AsyncGuard(this.target, this.evaluations, this.label);
  final String? target;
  final List<String> evaluations;
  final String label;

  @override
  Future<String?> redirect(BuildContext context, GoRouterState state) async {
    await Future<void>.delayed(Duration.zero);
    evaluations.add(label);
    return target;
  }
}

/// Estado mínimo só para satisfazer a assinatura — os guards de teste não o leem.
final GoRouterState _state = _fakeState();

GoRouterState _fakeState() {
  // GoRouterState não tem construtor público trivial; os guards de teste
  // ignoram o state, então um valor nulo via cast é suficiente aqui.
  return _NullState();
}

class _NullState implements GoRouterState {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  const BuildContext context = _NullContext();

  group('RouteGuard / GuardFn', () {
    test('GuardFn delega exatamente para a função fornecida', () async {
      final guard = GuardFn((_, __) => '/login');
      expect(await guard.redirect(context, _state), '/login');
    });

    test('GuardFn que libera retorna null', () async {
      final guard = GuardFn((_, __) => null);
      expect(await guard.redirect(context, _state), isNull);
    });

    test('GuardFn é um RouteGuard (substituível na cadeia)', () {
      final GuardFn guard = GuardFn((_, __) => null);
      expect(guard, isA<RouteGuard>());
    });
  });

  group('resolveGuards', () {
    test('lista vazia sem redirect legado retorna null (sem redirect)', () {
      expect(resolveGuards(const []), isNull);
    });

    test('guard único que libera resolve para null', () async {
      final evaluations = <String>[];
      final composed = resolveGuards([
        _FixedGuard.named(null, evaluations, 'a'),
      ]);
      expect(composed, isNotNull);
      expect(await composed!(context, _state), isNull);
      expect(evaluations, ['a']);
    });

    test('guard único que barra resolve para a rota de destino', () async {
      final evaluations = <String>[];
      final composed = resolveGuards([
        _FixedGuard.named('/home', evaluations, 'a'),
      ]);
      expect(await composed!(context, _state), '/home');
    });

    test('curto-circuito: primeiro que barra interrompe os seguintes',
        () async {
      final evaluations = <String>[];
      final composed = resolveGuards([
        _FixedGuard.named(null, evaluations, 'a'),
        _FixedGuard.named('/home', evaluations, 'b'),
        _FixedGuard.named('/never', evaluations, 'c'),
      ]);
      expect(await composed!(context, _state), '/home');
      expect(evaluations, ['a', 'b']);
    });

    test('todos liberam: resolve para null avaliando todos', () async {
      final evaluations = <String>[];
      final composed = resolveGuards([
        _FixedGuard.named(null, evaluations, 'a'),
        _FixedGuard.named(null, evaluations, 'b'),
      ]);
      expect(await composed!(context, _state), isNull);
      expect(evaluations, ['a', 'b']);
    });

    test('guard assíncrono é aguardado antes do próximo', () async {
      final evaluations = <String>[];
      final composed = resolveGuards([
        _AsyncGuard(null, evaluations, 'async-a'),
        _FixedGuard.named('/login', evaluations, 'b'),
        _FixedGuard.named('/never', evaluations, 'c'),
      ]);
      expect(await composed!(context, _state), '/login');
      expect(evaluations, ['async-a', 'b']);
    });

    group('composição com redirect legado [...guards, GuardFn(redirect)]', () {
      test('guards têm prioridade: legado não roda quando um guard barra',
          () async {
        final evaluations = <String>[];
        final composed = resolveGuards(
          [_FixedGuard.named('/guard', evaluations, 'a')],
          legacyRedirect: (_, __) {
            evaluations.add('legacy');
            return '/legacy';
          },
        );
        expect(await composed!(context, _state), '/guard');
        expect(evaluations, ['a']);
      });

      test('legado roda quando todos os guards liberam', () async {
        final evaluations = <String>[];
        final composed = resolveGuards(
          [_FixedGuard.named(null, evaluations, 'a')],
          legacyRedirect: (_, __) {
            evaluations.add('legacy');
            return '/home';
          },
        );
        expect(await composed!(context, _state), '/home');
        expect(evaluations, ['a', 'legacy']);
      });

      test('apenas redirect legado preserva comportamento (sem guards)',
          () async {
        final composed = resolveGuards(
          const [],
          legacyRedirect: (_, __) => '/legacy-only',
        );
        expect(composed, isNotNull);
        expect(await composed!(context, _state), '/legacy-only');
      });

      test('apenas redirect legado que libera resolve para null', () async {
        final composed = resolveGuards(
          const [],
          legacyRedirect: (_, __) => null,
        );
        expect(await composed!(context, _state), isNull);
      });
    });
  });
}

class _NullContext implements BuildContext {
  const _NullContext();
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
