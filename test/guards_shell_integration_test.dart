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

/// Stateful shell montado por um ModuleRoute COM guards no próprio ModuleRoute:
/// prova que o guard barra antes do redirect de seleção da primeira branch.
class _ModuleGuardTabsModule extends Module {
  @override
  List<ModularRoute> get routes => [
        StatefulShellModularRoute(
          builder: (_, __, shell) => shell,
          branches: [
            ModularBranch(routes: [ChildRoute('/ma', child: (_, __) => const _P('MA'))]),
            ModularBranch(routes: [ChildRoute('/mb', child: (_, __) => const _P('MB'))]),
          ],
        ),
      ];
}

/// Stateful shell com guards no PRÓPRIO StatefulShellModularRoute (resolvido no
/// shell_route_builder), sem guards no ModuleRoute que o monta.
class _ShellGuardTabsModule extends Module {
  @override
  List<ModularRoute> get routes => [
        StatefulShellModularRoute(
          guards: [GuardFn((_, __) => '/login')],
          builder: (_, __, shell) => shell,
          branches: [
            ModularBranch(routes: [ChildRoute('/sa', child: (_, __) => const _P('SA'))]),
            ModularBranch(routes: [ChildRoute('/sb', child: (_, __) => const _P('SB'))]),
          ],
        ),
      ];
}

/// Módulo cujo conteúdo é um shell — montado por um ModuleRoute COM guards:
/// cobre o ramo `isShell` do ModuleRouteBuilder (onde os guards do módulo viram
/// o redirect do GoRoute do shell).
class _ShellViaModule extends Module {
  @override
  List<ModularRoute> get routes => [
        ShellModularRoute(
          builder: (_, __, child) => child,
          routes: [ChildRoute('/sm-inner', child: (_, __) => const _P('SmInner'))],
        ),
      ];
}

class _ShellGuardsAppModule extends Module {
  @override
  List<ModularRoute> get routes => [
        ChildRoute('/', child: (_, __) => const _P('Home')),
        ChildRoute('/login', child: (_, __) => const _P('Login')),
        // Shell que LIBERA: o builder do ShellRoute realmente renderiza.
        ShellModularRoute(
          guards: [GuardFn((_, __) => null)],
          builder: (_, __, child) => Column(children: [const Text('Chrome'), Expanded(child: child)]),
          routes: [ChildRoute('/open-shell', child: (_, __) => const _P('OpenShell'))],
        ),
        // ShellModularRoute.guards → slot redirect do ShellRoute (barra).
        ShellModularRoute(
          guards: [GuardFn((_, __) => '/login')],
          builder: (_, __, child) => child,
          routes: [ChildRoute('/in-shell', child: (_, __) => const _P('InShell'))],
        ),
        // ModuleRoute.guards barra antes da seleção da primeira branch.
        ModuleRoute(
          '/mtabs',
          module: _ModuleGuardTabsModule(),
          guards: [GuardFn((_, __) => '/login')],
        ),
        // StatefulShellModularRoute.guards barra ao chegar na branch.
        ModuleRoute('/stabs', module: _ShellGuardTabsModule()),
        // Shell montado via ModuleRoute COM guards → ramo isShell do builder.
        ModuleRoute(
          '/smod',
          module: _ShellViaModule(),
          guards: [GuardFn((_, __) => '/login')],
        ),
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

Future<void> _goAndPump(WidgetTester tester, String location) async {
  Modular.routerConfig.go('/');
  await tester.pumpAndSettle();
  Modular.routerConfig.go(location);
  for (var frame = 0; frame < 12; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Modular.configure(
      appModule: _ShellGuardsAppModule(),
      initialRoute: '/',
      debugLogDiagnostics: false,
      debugLogDiagnosticsGoRouter: false,
      debugLogEventBus: false,
    );
  });

  testWidgets('ShellModularRoute.guards redireciona', (tester) async {
    await _bootstrap(tester);
    await _goAndPump(tester, '/in-shell');
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('InShell'), findsNothing);
  });

  testWidgets('ModuleRoute.guards barra antes da seleção da primeira branch',
      (tester) async {
    await _bootstrap(tester);
    await _goAndPump(tester, '/mtabs');
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('MA'), findsNothing);
  });

  testWidgets('StatefulShellModularRoute.guards redireciona', (tester) async {
    await _bootstrap(tester);
    await _goAndPump(tester, '/stabs');
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('SA'), findsNothing);
  });

  testWidgets('shell que libera renderiza o builder do shell', (tester) async {
    await _bootstrap(tester);
    await _goAndPump(tester, '/open-shell');
    expect(find.text('Chrome'), findsOneWidget);
    expect(find.text('OpenShell'), findsOneWidget);
  });

  testWidgets('ModuleRoute.guards num módulo-shell barra (ramo isShell)',
      (tester) async {
    await _bootstrap(tester);
    await _goAndPump(tester, '/smod/sm-inner');
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('SmInner'), findsNothing);
  });
}
