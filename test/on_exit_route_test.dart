import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

/// Módulo de teste para validar que onExit não interfere na navegação.
class OnExitTestModule extends Module {
  @override
  List<ModularRoute> get routes => [
        ChildRoute(
          '/',
          child: (context, state) => const _TestPage(title: 'Home'),
        ),
        ChildRoute(
          '/without-exit',
          child: (context, state) => const _TestPage(title: 'Sem onExit'),
        ),
        ChildRoute(
          '/with-exit-allow',
          child: (context, state) => const _TestPage(title: 'Com onExit allow'),
          onExit: (_, __) async => true,
        ),
        ChildRoute(
          '/with-exit-block',
          child: (context, state) => const _TestPage(title: 'Com onExit block'),
          onExit: (_, __) async => false,
        ),
        ChildRoute(
          '/with-transition-and-exit',
          child: (context, state) =>
              const _TestPage(title: 'Com transition e onExit'),
          transition: GoTransitions.fade,
          onExit: (_, __) async => true,
        ),
      ];
}

class _TestPage extends StatelessWidget {
  final String title;

  const _TestPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(title)),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('onExit em ChildRoute', () {
    setUpAll(() async {
      await Modular.configure(
        appModule: OnExitTestModule(),
        initialRoute: '/',
        debugLogDiagnostics: false,
        debugLogDiagnosticsGoRouter: false,
        debugLogEventBus: false,
        delayDisposeMilliseconds: 600,
      );
    });

    testWidgets('rota sem onExit permite navegação normalmente', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: Modular.routerConfig,
          builder: (context, child) => ModularLoader.builder(context, child),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);

      // Navega para rota sem onExit
      Modular.routerConfig.go('/without-exit');
      await tester.pumpAndSettle();

      expect(find.text('Sem onExit'), findsOneWidget);

      // Volta para home
      Modular.routerConfig.go('/');
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('rota com onExit retornando true permite sair', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: Modular.routerConfig,
          builder: (context, child) => ModularLoader.builder(context, child),
        ),
      );
      await tester.pumpAndSettle();

      // Navega para rota com onExit que permite sair
      Modular.routerConfig.go('/with-exit-allow');
      await tester.pumpAndSettle();

      expect(find.text('Com onExit allow'), findsOneWidget);

      // onExit retorna true - deve permitir voltar
      Modular.routerConfig.go('/');
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('onExit não interfere em rotas que não o possuem', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: Modular.routerConfig,
          builder: (context, child) => ModularLoader.builder(context, child),
        ),
      );
      await tester.pumpAndSettle();

      // Navega: home -> without-exit -> home -> with-exit-allow -> home
      Modular.routerConfig.go('/without-exit');
      await tester.pumpAndSettle();
      expect(find.text('Sem onExit'), findsOneWidget);

      Modular.routerConfig.go('/');
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);

      Modular.routerConfig.go('/with-exit-allow');
      await tester.pumpAndSettle();
      expect(find.text('Com onExit allow'), findsOneWidget);

      Modular.routerConfig.go('/');
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets(
      'rota com transition e onExit permite sair normalmente',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: Modular.routerConfig,
            builder: (context, child) => ModularLoader.builder(context, child),
          ),
        );
        await tester.pumpAndSettle();

        Modular.routerConfig.go('/with-transition-and-exit');
        await tester.pumpAndSettle();

        expect(find.text('Com transition e onExit'), findsOneWidget);

        Modular.routerConfig.go('/');
        await tester.pumpAndSettle();

        expect(find.text('Home'), findsOneWidget);
      },
    );

    testWidgets('rota com onExit retornando false impede saída', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: Modular.routerConfig,
          builder: (context, child) => ModularLoader.builder(context, child),
        ),
      );
      await tester.pumpAndSettle();

      // Navega para rota com onExit que bloqueia saída
      Modular.routerConfig.go('/with-exit-block');
      await tester.pumpAndSettle();

      expect(find.text('Com onExit block'), findsOneWidget);

      // onExit retorna false - NÃO deve sair
      Modular.routerConfig.go('/');
      await tester.pumpAndSettle();

      // Deve continuar na mesma página
      expect(find.text('Com onExit block'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    });
  });
}
