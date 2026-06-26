import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

/// Módulo simples para validar o `copyWith` em `Modular.routerConfig`.
class CopyWithModule extends Module {
  @override
  List<ModularRoute> get routes => [
        ChildRoute(
          '/',
          child: (context, state) => const _TestPage(title: 'Home'),
        ),
        ChildRoute(
          '/second',
          child: (context, state) => const _TestPage(title: 'Second'),
        ),
      ];
}

class _TestPage extends StatelessWidget {
  final String title;

  const _TestPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(title)));
  }
}

/// Observer que conta os pushes recebidos, para provar que os observers
/// passados via `copyWith` realmente são ligados ao Navigator.
class _CountingObserver extends NavigatorObserver {
  int didPushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    didPushCount++;
    super.didPush(route, previousRoute);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final observer = _CountingObserver();

  group('Modular.routerConfig.copyWith', () {
    setUpAll(() async {
      await Modular.configure(
        appModule: CopyWithModule(),
        initialRoute: '/',
        debugLogDiagnostics: false,
        debugLogDiagnosticsGoRouter: false,
        debugLogEventBus: false,
        delayDisposeMilliseconds: 600,
      );
    });

    testWidgets('reaproveita as rotas do configure e liga os observers passados',
        (tester) async {
      // Primeira chamada de copyWith no arquivo: define o observer derivado.
      final router = Modular.routerConfig.copyWith(observers: [observer]);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => ModularLoader.builder(context, child),
        ),
      );
      await tester.pumpAndSettle();

      // Rotas vieram do configure() — sem precisar redeclarar nada.
      expect(find.text('Home'), findsOneWidget);
      // O observer foi ligado: o push inicial já foi contabilizado.
      expect(observer.didPushCount, greaterThan(0));

      final pushesBeforeNav = observer.didPushCount;

      // Navega usando o router derivado — deve funcionar normalmente.
      router.go('/second');
      await tester.pumpAndSettle();

      expect(find.text('Second'), findsOneWidget);
      // Navegação disparou novo push no observer override.
      expect(observer.didPushCount, greaterThan(pushesBeforeNav));
    });

    testWidgets('é memoizado: retorna sempre a mesma instância (preserva estado)',
        (tester) async {
      final a = Modular.routerConfig.copyWith(observers: [observer]);
      final b = Modular.routerConfig.copyWith();
      final c = Modular.routerConfig.copyWith(observers: [_CountingObserver()]);

      // Memoização "primeira chamada vence": todas devolvem o mesmo GoRouter,
      // garantindo que rebuilds do widget não recriem o router (sem perda de
      // estado de navegação).
      expect(identical(a, b), isTrue);
      expect(identical(a, c), isTrue);
    });

    testWidgets('o router derivado é distinto do routerConfig base',
        (tester) async {
      final derived = Modular.routerConfig.copyWith();

      // copyWith não muta o router base retornado por routerConfig.
      expect(identical(derived, Modular.routerConfig), isFalse);
    });

    testWidgets('routerConfig base continua funcionando (sem regressão)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: Modular.routerConfig,
          builder: (context, child) => ModularLoader.builder(context, child),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);

      Modular.routerConfig.go('/second');
      await tester.pumpAndSettle();

      expect(find.text('Second'), findsOneWidget);
    });
  });
}
