// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

/// Serviço de exemplo registrado por um módulo, lido de dentro de um guard
/// para provar que os binds já estão disponíveis quando o guard roda.
class _SessionService {
  bool isLogged = false;
}

/// Registra, em ordem, os eventos observados durante a navegação para provar
/// que os binds do módulo são injetados ANTES de o guard rodar.
final List<String> _orderLog = <String>[];

/// Serviço cujo construtor marca o instante em que os binds foram registrados
/// e resolvidos. Como o guard o lê via [Modular.get], sua presença no log
/// antes da entrada `guard` prova a ordem binds → guard.
class _OrderMarkerService {
  _OrderMarkerService() {
    _orderLog.add('binds');
  }
}

class _OrderModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<_OrderMarkerService>((i) => _OrderMarkerService());
  }

  @override
  List<ModularRoute> get routes => [
        ChildRoute('/', child: (_, __) => const _TestPage('OrderHome')),
      ];
}

/// Guard que, ao rodar, resolve o serviço do módulo (forçando sua instância) e
/// registra `guard` no log. Se os binds rodassem depois, o `Modular.get`
/// lançaria — então o teste valida a ordem de duas formas.
class _OrderGuard extends ModularGuard {
  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    // Resolve o bind do módulo: precisa já estar registrado.
    Modular.get<_OrderMarkerService>();
    _orderLog.add('guard');
    return '/login';
  }
}

class _SessionGuard extends ModularGuard {
  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    final session = Modular.get<_SessionService>();
    if (session.isLogged) return null;
    return '/login';
  }
}

class _TestPage extends StatelessWidget {
  final String title;
  const _TestPage(this.title);

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(title)));
}

/// Módulo cuja rota índice tem transição — cobre o ramo com transição do
/// ModuleRouteBuilder (onde os guards do módulo viram o `indexRedirect`).
class _TransitionModule extends Module {
  @override
  List<ModularRoute> get routes => [
        ChildRoute(
          '/',
          transition: GoTransitions.fade,
          child: (_, __) => const _TestPage('TransitionHome'),
        ),
      ];
}

/// Submódulo protegido por guard no ModuleRoute, lendo serviço via Modular.get.
class _AdminModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<_SessionService>((i) => _SessionService());
  }

  @override
  List<ModularRoute> get routes => [
        ChildRoute('/', child: (_, __) => const _TestPage('AdminHome')),
        ChildRoute('/users', child: (_, __) => const _TestPage('AdminUsers')),
      ];
}

/// Módulo único do app (configure é uma vez só por processo: `_router != null`
/// faz a segunda chamada retornar o router antigo). Reunimos todas as rotas a
/// exercitar num só módulo, como em `on_exit_route_test`/`router_config_copy_with_test`.
class _GuardsAppModule extends Module {
  @override
  List<ModularRoute> get routes => [
        ChildRoute('/', child: (_, __) => const _TestPage('Home')),
        ChildRoute('/login', child: (_, __) => const _TestPage('Login')),
        ChildRoute(
          '/protected',
          guards: [GuardFn((_, __) => '/login')],
          child: (_, __) => const _TestPage('Protected'),
        ),
        ChildRoute(
          '/allowed',
          guards: [GuardFn((_, __) => null)],
          child: (_, __) => const _TestPage('Allowed'),
        ),
        ChildRoute(
          '/order',
          // Coexistência: guard libera (null), redirect legado decide.
          guards: [GuardFn((_, __) => null)],
          redirect: (_, __) => '/login',
          child: (_, __) => const _TestPage('Order'),
        ),
        ChildRoute(
          '/with-page-builder',
          // Ramo pageBuilder do ChildRouteBuilder + guard que barra.
          guards: [GuardFn((_, __) => '/login')],
          pageBuilder: (context, state) =>
              const MaterialPage(child: _TestPage('PageBuilder')),
          child: (_, __) => const _TestPage('PageBuilder'),
        ),
        ModuleRoute(
          '/admin',
          module: _AdminModule(),
          guards: [_SessionGuard()],
        ),
        ModuleRoute(
          '/transition',
          module: _TransitionModule(),
          // Guard libera → o módulo monta pelo ramo com transição.
          guards: [GuardFn((_, __) => null)],
        ),
        ModuleRoute(
          '/order-check',
          module: _OrderModule(),
          guards: [_OrderGuard()],
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

/// Vai para [location] e bombeia frames limitados — o ModularLoader anima
/// enquanto registra binds, então `pumpAndSettle` não estabiliza na janela do
/// redirect. Volta antes para `/` para isolar o estado entre testes.
Future<void> _goAndPump(WidgetTester tester, String location) async {
  Modular.routerConfig.go('/');
  await tester.pumpAndSettle();
  Modular.routerConfig.go(location);
  for (var frame = 0; frame < 10; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Modular.configure(
      appModule: _GuardsAppModule(),
      initialRoute: '/',
      debugLogDiagnostics: false,
      debugLogDiagnosticsGoRouter: false,
      debugLogEventBus: false,
    );
  });

  group('ChildRoute com guards', () {
    testWidgets('guard que barra redireciona para /login', (tester) async {
      await _bootstrap(tester);
      await _goAndPump(tester, '/protected');
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Protected'), findsNothing);
    });

    testWidgets('guard que libera deixa a tela montar', (tester) async {
      await _bootstrap(tester);
      await _goAndPump(tester, '/allowed');
      expect(find.text('Allowed'), findsOneWidget);
    });

    testWidgets('guards liberam e redirect legado decide (coexistência)',
        (tester) async {
      await _bootstrap(tester);
      await _goAndPump(tester, '/order');
      // guard retornou null → redirect legado ('/login') venceu.
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Order'), findsNothing);
    });

    testWidgets('guard barra rota com pageBuilder', (tester) async {
      await _bootstrap(tester);
      await _goAndPump(tester, '/with-page-builder');
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('PageBuilder'), findsNothing);
    });
  });

  group('ModuleRoute com transição na rota índice', () {
    testWidgets('guard libera e o módulo monta pelo ramo com transição',
        (tester) async {
      await _bootstrap(tester);
      await _goAndPump(tester, '/transition');
      expect(find.text('TransitionHome'), findsOneWidget);
    });
  });

  group('ModuleRoute com guards', () {
    testWidgets(
        'guard nega acesso (sessão deslogada) lendo binds via Modular.get',
        (tester) async {
      await _bootstrap(tester);
      await _goAndPump(tester, '/admin/users');
      // _SessionGuard leu _SessionService (binds já registrados) → deslogado.
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('AdminUsers'), findsNothing);
    });

    testWidgets('binds são injetados ANTES de o guard rodar (ordem)',
        (tester) async {
      _orderLog.clear();
      await _bootstrap(tester);
      await _goAndPump(tester, '/order-check');

      // Ordem explícita: o construtor do bind registrou 'binds' antes de o
      // guard registrar 'guard'. Se a ordem fosse inversa, Modular.get dentro
      // do guard lançaria e o teste falharia antes desta asserção.
      expect(_orderLog, ['binds', 'guard']);
      expect(_orderLog.indexOf('binds'), lessThan(_orderLog.indexOf('guard')));
      // E o guard redirecionou (todo o fluxo aconteceu no redirect do módulo).
      expect(find.text('Login'), findsOneWidget);
    });
  });
}
