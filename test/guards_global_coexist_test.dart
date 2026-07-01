// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

class _P extends StatelessWidget {
  final String title;
  const _P(this.title);
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(title)));
}

class _AppModule extends Module {
  @override
  List<ModularRoute> get routes => [
        ChildRoute('/', child: (_, __) => const _P('Home')),
        ChildRoute('/guard', child: (_, __) => const _P('GuardTarget')),
        ChildRoute('/legacy', child: (_, __) => const _P('LegacyTarget')),
      ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // guard global libera ('/' não barra) mas para '/' redireciona via guard;
    // aqui o guard SEMPRE libera (null) e o redirect legado decide → prova a
    // ordem [...guards, GuardFn(redirect)] no nível global.
    await Modular.configure(
      appModule: _AppModule(),
      initialRoute: '/',
      guards: [GuardFn((_, state) => null)],
      redirect: (context, state) {
        if (state.matchedLocation == '/') return '/legacy';
        return null;
      },
      debugLogDiagnostics: false,
      debugLogDiagnosticsGoRouter: false,
      debugLogEventBus: false,
    );
  });

  testWidgets('guards globais liberam → redirect legado decide (coexistência)',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: Modular.routerConfig,
        builder: (context, child) => ModularLoader.builder(context, child),
      ),
    );
    await tester.pumpAndSettle();
    // '/' → guard global retornou null → redirect legado → '/legacy'.
    expect(find.text('LegacyTarget'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });
}
