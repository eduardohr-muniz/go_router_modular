// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';

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

/// Guard global: bloqueia qualquer rota que não seja /login.
class _GlobalAuthGuard extends ModularGuard {
  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    if (state.matchedLocation == '/login') return null;
    return '/login';
  }
}

class _AppModule extends Module {
  @override
  List<ModularRoute> get routes => [
        ChildRoute('/', child: (_, __) => const _P('Home')),
        ChildRoute('/login', child: (_, __) => const _P('Login')),
        ChildRoute('/profile', child: (_, __) => const _P('Profile')),
      ];
}

Future<void> _bootstrap(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: Modular.routerConfig,
      builder: (context, child) => ModularLoader.builder(context, child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Modular.configure(
      appModule: _AppModule(),
      initialRoute: '/',
      guards: [_GlobalAuthGuard()],
      debugLogDiagnostics: false,
      debugLogDiagnosticsGoRouter: false,
      debugLogEventBus: false,
    );
  });

  testWidgets('guard global desvia a rota inicial para /login', (tester) async {
    await _bootstrap(tester);
    // Mesmo iniciando em '/', o guard global redireciona para /login.
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });

  testWidgets('guard global bloqueia navegação para outra rota', (tester) async {
    await _bootstrap(tester);
    Modular.routerConfig.go('/profile');
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Profile'), findsNothing);
  });

  testWidgets('guard global libera a rota isenta (/login)', (tester) async {
    await _bootstrap(tester);
    Modular.routerConfig.go('/login');
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);
  });
}
