import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/routing/history/browser_history.dart';

/// Reprodução: aba de navegador oculta por muito tempo.
///
/// Em Chrome, uma aba em background para de receber `requestAnimationFrame`
/// (nenhum frame Flutter) e tem os timers congelados/estrangulados. Quando o
/// usuário volta, os timers disparam em rajada e UM frame acontece.
///
/// Este teste modela exatamente isso:
///   - `tester.idle()`            → microtasks rodam (redirects resolvem), sem frame
///   - `tester.binding.delayed()` → o relógio avança e os timers disparam, sem frame
///   - `tester.pump()`            → a aba volta: o primeiro frame acontece

class ServiceA {}

class ServiceB {}

class AModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<ServiceA>((i) => ServiceA());
  }

  @override
  List<ModularRoute> get routes => [ChildRoute('/', name: 'a', child: (c, s) => const _Page('PageA'))];
}

class BModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<ServiceB>((i) => ServiceB());
  }

  @override
  List<ModularRoute> get routes => [ChildRoute('/', name: 'b', child: (c, s) => const _Page('PageB'))];
}

/// Instâncias do teste corrente. Recriadas a cada `bootAt` para que um teste
/// não herde a contagem de referências do anterior — o refcount é por
/// identidade de instância, não por tipo.
late AModule aModule;
late BModule bModule;

class AppModule extends Module {
  @override
  List<ModularRoute> get routes => [
        ModuleRoute('/a', module: aModule),
        ModuleRoute('/b', module: bModule),
      ];
}

class _Page extends StatelessWidget {
  const _Page(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text(title)));
}

/// Histórico inerte: `go` sempre recusa o movimento.
///
/// Sem isso, ao rodar em Chrome estes testes pegam a implementação REAL de
/// [BrowserHistory]. Aí `go(-1)` mexe no histórico da página de teste, retorna
/// `true`, e o provider arma o watchdog de 1s à espera de um `popstate` que o
/// relógio falso do `testWidgets` nunca entrega — o teste termina com timer
/// pendente. Estes testes são sobre contagem de referências, não sobre o
/// histórico do navegador, então a plataforma fica fixa nos dois alvos.
class _InertBrowserHistory extends BrowserHistory {
  const _InertBrowserHistory();

  @override
  bool go(int delta) => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => debugBrowserHistoryOverride = const _InertBrowserHistory());
  tearDownAll(() => debugBrowserHistoryOverride = null);

  Future<void> bootAt(WidgetTester tester, String initial, {Listenable? refresh}) async {
    // `Modular.resetForTesting` já limpa o InjectionManager.
    Modular.resetForTesting();
    aModule = AModule();
    bModule = BModule();
    await Modular.configure(
      appModule: AppModule(),
      initialRoute: initial,
      debugLogDiagnostics: false,
      refreshListenable: refresh,
    );
    await tester.pumpWidget(MaterialApp.router(
      routerConfig: Modular.routerConfig,
      builder: (c, child) => ModularLoader.builder(c, child),
    ));
    await tester.pumpAndSettle();
  }

  /// A aba fica oculta: nenhum frame, mas microtasks e (depois) timers rodam.
  Future<void> hide(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.idle();
  }

  Future<void> awayFor(WidgetTester tester, Duration d) async {
    await tester.binding.delayed(d);
  }

  Future<void> comeBack(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('A: refresh (refreshListenable) com a aba oculta por 30 min', (tester) async {
    final notifier = ChangeNotifier();
    await bootAt(tester, '/a', refresh: notifier);

    expect(Modular.tryGet<ServiceA>(), isNotNull);

    await hide(tester);
    // Algo dispara um refresh enquanto a aba está oculta (token expirando,
    // websocket, refreshListenable de auth...).
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    notifier.notifyListeners();
    await tester.idle();

    await awayFor(tester, const Duration(minutes: 30));

    await comeBack(tester);
    expect(Modular.tryGet<ServiceA>(), isNotNull, reason: 'ServiceA sumiu depois da aba voltar');
    expect(tester.takeException(), isNull);
  });

  testWidgets('B: muitos refreshes com a aba oculta, um frame na volta', (tester) async {
    final notifier = ChangeNotifier();
    await bootAt(tester, '/a', refresh: notifier);

    await hide(tester);
    for (var i = 0; i < 20; i++) {
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      notifier.notifyListeners();
      await tester.idle();
      await awayFor(tester, const Duration(minutes: 1));
    }

    await comeBack(tester);
    expect(Modular.tryGet<ServiceA>(), isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('C: navegação disparada com a aba oculta, frame só na volta', (tester) async {
    await bootAt(tester, '/a');
    final router = Modular.routerConfig;

    await hide(tester);
    router.go('/b');
    await tester.idle();

    await awayFor(tester, const Duration(minutes: 30));
    await comeBack(tester);
    expect(find.text('PageB'), findsOneWidget);
    expect(Modular.tryGet<ServiceB>(), isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('D: pilha A -> B, pop com a aba oculta, frame so na volta', (tester) async {
    await bootAt(tester, '/a');
    final router = Modular.routerConfig;
    router.push('/b');
    await tester.pumpAndSettle();
    expect(Modular.tryGet<ServiceB>(), isNotNull);

    await hide(tester);
    router.pop();
    await tester.idle();
    await awayFor(tester, const Duration(minutes: 30));
    await comeBack(tester);
    expect(find.text('PageA'), findsOneWidget);
    expect(Modular.tryGet<ServiceA>(), isNotNull, reason: 'ServiceA sumiu na volta');
    expect(tester.takeException(), isNull);
  });

  testWidgets('E: duas navegacoes com a aba oculta, um frame na volta', (tester) async {
    await bootAt(tester, '/a');
    final router = Modular.routerConfig;

    await hide(tester);
    router.go('/b');
    await tester.idle();
    router.go('/a');
    await tester.idle();
    await awayFor(tester, const Duration(minutes: 30));
    await comeBack(tester);
    expect(find.text('PageA'), findsOneWidget);
    expect(Modular.tryGet<ServiceA>(), isNotNull, reason: 'ServiceA sumiu na volta');
    expect(tester.takeException(), isNull);
  });

  testWidgets('F: refresh oculto + navegacao na volta (referencia pendente de 30 min)', (tester) async {
    final notifier = ChangeNotifier();
    await bootAt(tester, '/a', refresh: notifier);

    await hide(tester);
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    notifier.notifyListeners();
    await tester.idle();
    await awayFor(tester, const Duration(minutes: 30));

    // O usuario volta e navega imediatamente, no mesmo frame em que os
    // post-frame callbacks acumulados disparam.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    Modular.routerConfig.go('/b');
    await tester.pumpAndSettle();
    expect(find.text('PageB'), findsOneWidget);
    expect(Modular.tryGet<ServiceB>(), isNotNull);
    expect(tester.takeException(), isNull);

    // E volta para /a: os binds precisam ser reinjetados.
    Modular.routerConfig.go('/a');
    await tester.pumpAndSettle();
    expect(Modular.tryGet<ServiceA>(), isNotNull, reason: 'ServiceA nao foi reinjetado');
    expect(tester.takeException(), isNull);
  });
}
