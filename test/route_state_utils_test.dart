import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

/// Payload usado para validar `extraOf<T>` com tipo correto e tipo divergente.
class _Payload {
  final String value;

  const _Payload(this.value);
}

/// Captura o [BuildContext] da rota de detalhe para exercitar os utilitários
/// de leitura de estado da fachada [Modular].
BuildContext? capturedContext;

class UtilsModule extends Module {
  @override
  List<ModularRoute> get routes => [
        ChildRoute(
          '/',
          child: (context, state) => const Scaffold(body: Center(child: Text('Home'))),
        ),
        ChildRoute(
          '/usuario/:id',
          child: (context, state) {
            capturedContext = context;
            return const Scaffold(body: Center(child: Text('Detalhe')));
          },
        ),
      ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Modular.configure(
      appModule: UtilsModule(),
      initialRoute: '/',
      debugLogDiagnostics: false,
      debugLogDiagnosticsGoRouter: false,
      debugLogEventBus: false,
      delayDisposeMilliseconds: 600,
    );
  });

  Future<BuildContext> pumpAndNavigate(WidgetTester tester, {Object? extra}) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: Modular.routerConfig,
        builder: (context, child) => ModularLoader.builder(context, child),
      ),
    );
    await tester.pumpAndSettle();

    Modular.routerConfig.go('/usuario/42?termo=flutter', extra: extra);
    await tester.pumpAndSettle();

    expect(find.text('Detalhe'), findsOneWidget);
    return capturedContext!;
  }

  group('Modular: leitura de estado da rota', () {
    testWidgets('routerStateOf, currentPathOf e pathParamOf', (tester) async {
      final context = await pumpAndNavigate(tester);

      expect(Modular.routerStateOf(context), isA<GoRouterState>());
      expect(Modular.currentPathOf(context), '/usuario/:id');
      expect(Modular.pathParamOf(context, 'id'), '42');
      expect(Modular.pathParamOf(context, 'inexistente'), isNull);
    });

    testWidgets('pathParamsOf, queryParamsOf e queryParamOf', (tester) async {
      final context = await pumpAndNavigate(tester);

      expect(Modular.pathParamsOf(context), {'id': '42'});
      expect(Modular.queryParamsOf(context), {'termo': 'flutter'});
      expect(Modular.queryParamOf(context, 'termo'), 'flutter');
      expect(Modular.queryParamOf(context, 'ausente'), isNull);
    });

    testWidgets('currentUriOf e currentLocationOf', (tester) async {
      final context = await pumpAndNavigate(tester);

      expect(Modular.currentUriOf(context).toString(), '/usuario/42?termo=flutter');
      expect(Modular.currentLocationOf(context), '/usuario/42');
    });

    testWidgets('extraOf retorna o extra tipado e null em tipo divergente', (tester) async {
      const payload = _Payload('detalhe');
      final context = await pumpAndNavigate(tester, extra: payload);

      expect(Modular.extraOf<_Payload>(context), same(payload));
      expect(Modular.extraOf<String>(context), isNull);
    });

    testWidgets('extraOf retorna null quando não há extra', (tester) async {
      final context = await pumpAndNavigate(tester);

      expect(Modular.extraOf<_Payload>(context), isNull);
    });
  });

  group('Equivalência dos símbolos depreciados', () {
    testWidgets('fachada: getCurrentPathOf e stateOf delegam aos novos', (tester) async {
      final context = await pumpAndNavigate(tester);

      // ignore: deprecated_member_use_from_same_package
      expect(Modular.getCurrentPathOf(context), Modular.currentPathOf(context));
      // ignore: deprecated_member_use_from_same_package
      expect(Modular.stateOf(context), same(Modular.routerStateOf(context)));
    });

    testWidgets('extension: getPath, state e getPathParam delegam aos novos', (tester) async {
      final context = await pumpAndNavigate(tester);

      // ignore: deprecated_member_use_from_same_package
      expect(context.getPath, Modular.currentPathOf(context));
      // ignore: deprecated_member_use_from_same_package
      expect(context.getPathParam('id'), Modular.pathParamOf(context, 'id'));
      // ignore: deprecated_member_use_from_same_package
      expect(context.state, same(Modular.routerStateOf(context)));
    });
  });

  group('Superfície pública: utilitários do go_router', () {
    testWidgets('GoRouterState e GoRouterHelper acessíveis pelo barril', (tester) async {
      final context = await pumpAndNavigate(tester);

      // GoRouterState vem do re-export `hide GoRouter, ShellRoute` — acessível
      // sem importar `package:go_router/go_router.dart` neste arquivo.
      final GoRouterState state = GoRouterState.of(context);
      expect(state.matchedLocation, '/usuario/42');

      // GoRouterHelper (context.go) também chega pelo barril.
      context.go('/');
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });
  });
}
