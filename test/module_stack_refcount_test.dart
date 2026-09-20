import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/routing/history/browser_history.dart';

/// Regressão: a MESMA instância de módulo empilhada mais de uma vez na pilha de
/// navegação (A → B → A) não deve ter seus binds descartados ao dar pop na
/// entrada de cima — a entrada de baixo ainda os usa.
///
/// Causa do bug original: registro idempotente (1×) vs descarte por página (N×).
/// Correção: contagem de referências por instância de módulo.

class ServiceA {}

class ServiceB {}

class AModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<ServiceA>((i) => ServiceA());
  }

  @override
  List<ModularRoute> get routes =>
      [ChildRoute('/', child: (c, s) => const _Page('PageA'))];
}

class BModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<ServiceB>((i) => ServiceB());
  }

  @override
  List<ModularRoute> get routes =>
      [ChildRoute('/', child: (c, s) => const _Page('PageB'))];
}

class StackAppModule extends Module {
  @override
  List<ModularRoute> get routes => [
        ModuleRoute('/a', module: AModule()),
        ModuleRoute('/b', module: BModule()),
      ];
}

class _Page extends StatelessWidget {
  final String title;
  const _Page(this.title);
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(title)));
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

  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  testWidgets('pilha A → B → A: pop da entrada de cima preserva binds de A',
      (tester) async {
    InjectionManager.instance.resetForTesting();
    await Modular.configure(
      appModule: StackAppModule(),
      initialRoute: '/a',
      debugLogDiagnostics: false,
      delayDisposeMilliseconds: 600,
    );

    await tester.pumpWidget(MaterialApp.router(
      routerConfig: Modular.routerConfig,
      builder: (c, child) => ModularLoader.builder(c, child),
    ));
    await tester.pumpAndSettle();
    final router = Modular.routerConfig;

    // [1] A base
    expect(Modular.tryGet<ServiceA>(), isNotNull);

    // [2] push B → A,B
    router.push('/b');
    await tester.pumpAndSettle();
    expect(Modular.tryGet<ServiceA>(), isNotNull);
    expect(Modular.tryGet<ServiceB>(), isNotNull);

    // [3] push A → A,B,A (mesma instância de A)
    router.push('/a');
    await tester.pumpAndSettle();
    expect(Modular.tryGet<ServiceA>(), isNotNull);

    // [4] pop topo A → A,B — A de baixo ainda precisa de ServiceA
    router.pop();
    await settle(tester);
    expect(Modular.tryGet<ServiceA>(), isNotNull,
        reason:
            'ServiceA não pode ser descartado: a entrada de baixo de A ainda está na pilha');
    expect(Modular.tryGet<ServiceB>(), isNotNull);

    // [5] pop B → A base; ServiceA segue válido, ServiceB descartado
    router.pop();
    await settle(tester);
    expect(Modular.tryGet<ServiceA>(), isNotNull);
  });

  testWidgets('pilha A → A: pop da entrada de cima preserva binds de A',
      (tester) async {
    InjectionManager.instance.resetForTesting();
    await Modular.configure(
      appModule: StackAppModule(),
      initialRoute: '/a',
      debugLogDiagnostics: false,
      delayDisposeMilliseconds: 600,
    );

    await tester.pumpWidget(MaterialApp.router(
      routerConfig: Modular.routerConfig,
      builder: (c, child) => ModularLoader.builder(c, child),
    ));
    await tester.pumpAndSettle();
    final router = Modular.routerConfig;

    expect(Modular.tryGet<ServiceA>(), isNotNull);

    // push A sobre A → A,A (mesma instância)
    router.push('/a');
    await tester.pumpAndSettle();
    expect(Modular.tryGet<ServiceA>(), isNotNull);

    // pop topo A → A base ainda viva
    router.pop();
    await settle(tester);
    expect(Modular.tryGet<ServiceA>(), isNotNull,
        reason: 'A de baixo ainda referencia ServiceA');
  });
}
