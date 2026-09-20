import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart' show GoRouter;
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/routing/history/browser_history.dart';
import 'package:go_router_modular/src/routing/history/modular_route_information_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Módulos de teste
// ─────────────────────────────────────────────────────────────────────────────

class ServiceA {}

class ServiceB {}

class ServiceC {}

/// How many times A's index-route guard ran, which is how many times go_router
/// re-parsed a navigation going through /a.
int aGuardRuns = 0;

class AModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<ServiceA>((i) => ServiceA());
  }

  @override
  List<ModularRoute> get routes => [
        ChildRoute(
          '/',
          guards: [
            GuardFn((context, state) {
              aGuardRuns++;
              return null;
            }),
          ],
          child: (c, s) => const _Page('PageA'),
        ),
        ChildRoute('/x', child: (c, s) => const _Page('PageAX')),
        ChildRoute('/y', child: (c, s) => const _Page('PageAY')),
      ];
}

class BModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<ServiceB>((i) => ServiceB());
  }

  @override
  List<ModularRoute> get routes => [ChildRoute('/', child: (c, s) => const _Page('PageB'))];
}

/// Module whose guard always redirects to /a: the binds are registered by the
/// redirect, but no page of the module ever exists.
class CModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<ServiceC>((i) => ServiceC());
  }

  @override
  List<ModularRoute> get routes => [
        ChildRoute(
          '/',
          guards: [GuardFn((context, state) => '/a')],
          child: (c, s) => const _Page('PageC'),
        ),
      ];
}

class ServiceShared {}

/// Instance deliberately shared by a stateful shell branch and a top-level
/// route, so that both hold a reference to the very same module at once.
final sharedLeafModule = SharedLeafModule();

class SharedLeafModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<ServiceShared>((i) => ServiceShared());
  }

  @override
  List<ModularRoute> get routes => [ChildRoute('/', child: (c, s) => const _Page('PageShared'))];
}

class TabsModule extends Module {
  @override
  List<ModularRoute> get routes => [
        StatefulShellModularRoute(
          branches: [
            ModularBranch(routes: [ModuleRoute('/one', module: sharedLeafModule)]),
          ],
        ),
      ];
}

class ShellAppModule extends Module {
  @override
  List<ModularRoute> get routes => [
        ModuleRoute('/shared', module: sharedLeafModule),
        ModuleRoute('/tabs', module: TabsModule()),
      ];
}

class WebAppModule extends Module {
  @override
  List<ModularRoute> get routes => [
        ModuleRoute('/a', module: AModule()),
        ModuleRoute('/b', module: BModule()),
        ModuleRoute('/c', module: CModule()),
      ];
}

class _Page extends StatelessWidget {
  final String title;
  const _Page(this.title);
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text(title)));
}

// ─────────────────────────────────────────────────────────────────────────────
// Navegador falso: histórico de sessão + popstate
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryEntry {
  final String location;
  final Object? state;
  const _HistoryEntry(this.location, this.state);
  @override
  String toString() => location;
}

/// Emulates the `window.history` of Flutter's web engine:
/// `routeInformationUpdated` becomes `pushState`/`replaceState`, and
/// `go(delta)` fires an asynchronous `popstate` that the engine turns into
/// `pushRouteInformation`.
class FakeBrowser implements BrowserHistory {
  /// As in a real browser, the loaded page already occupies one entry.
  final List<_HistoryEntry> entries = [const _HistoryEntry('/', null)];
  int index = 0;

  /// Operations received, in order: `push:/x`, `replace:/x`, `go:-1`.
  final List<String> ops = [];

  /// When false, `go` is accepted but no `popstate` ever arrives, which is what
  /// a real browser does when the target entry already left the session
  /// history.
  bool deliverPopstate = true;

  List<String> get locations => entries.map((e) => e.location).toList();

  /// Entries reachable with the back button, from the oldest to the current
  /// one. The forward entries left over after a step back are normal on any
  /// site and are not part of the stack.
  List<String> get backStack => locations.sublist(0, index + 1);

  void install() {
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.navigation, (call) async {
      if (call.method != 'routeInformationUpdated') return null;
      final args = call.arguments as Map<Object?, Object?>;
      final location = (args['uri'] ?? args['location']) as String;
      final entry = _HistoryEntry(location, args['state']);
      if (args['replace'] as bool) {
        ops.add('replace:$location');
        entries[index] = entry;
      } else {
        ops.add('push:$location');
        entries.removeRange(index + 1, entries.length);
        entries.add(entry);
        index++;
      }
      return null;
    });
  }

  @override
  bool go(int delta) {
    ops.add('go:$delta');
    if (deliverPopstate) scheduleMicrotask(() => _traverse(delta));
    return true;
  }

  /// Back and forward triggered by the user, with the browser's own arrows.
  Future<void> userBack() => _traverse(-1);
  Future<void> userForward() => _traverse(1);

  Future<void> _traverse(int delta) async {
    final target = (index + delta).clamp(0, entries.length - 1);
    if (target == index) return;
    index = target;
    final entry = entries[index];
    await TestWidgetsFlutterBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.navigation.name,
      SystemChannels.navigation.codec.encodeMethodCall(
        MethodCall('pushRouteInformation', <String, dynamic>{'location': entry.location, 'state': entry.state}),
      ),
      (_) {},
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeBrowser browser;

  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  Future<GoRouter> boot(WidgetTester tester, {String initialRoute = '/a', Module? appModule}) async {
    Modular.resetForTesting();
    browser = FakeBrowser()..install();
    debugBrowserHistoryOverride = browser;
    aGuardRuns = 0;
    await Modular.configure(
      appModule: appModule ?? WebAppModule(),
      initialRoute: initialRoute,
      debugLogDiagnostics: false,
    );
    await tester.pumpWidget(MaterialApp.router(
      routerConfig: Modular.routerConfig,
      builder: (c, child) => ModularLoader.builder(c, child),
    ));
    await settle(tester);
    return Modular.routerConfig;
  }

  ModularRouteInformationProvider provider() => Modular.routerConfig.routeInformationProvider as ModularRouteInformationProvider;

  tearDown(() {
    debugBrowserHistoryOverride = null;
  });

  group('histórico do navegador espelha a pilha de páginas', () {
    testWidgets('a primeira rota substitui a entrada inicial do navegador', (tester) async {
      await boot(tester);
      expect(browser.ops, ['replace:/a']);
      expect(browser.backStack, ['/a']);
      expect(provider().debugEntries, [
        ['/a']
      ]);
    });

    testWidgets('go() para outra rota substitui a entrada: o voltar não reabre a rota descartada', (tester) async {
      final router = await boot(tester);

      router.go('/b');
      await settle(tester);

      expect(find.text('PageB'), findsOneWidget);
      expect(Modular.tryGet<ServiceA>(), isNull, reason: 'AModule saiu da pilha');
      expect(browser.ops, ['replace:/a', 'replace:/b']);
      expect(browser.backStack, ['/b'], reason: 'não sobra entrada de /a para o voltar do navegador');
    });

    testWidgets('push() cria entrada e pop() recua o navegador (history.go(-1)) em vez de empilhar', (tester) async {
      final router = await boot(tester);

      router.push('/b');
      await settle(tester);
      expect(browser.ops, ['replace:/a', 'push:/b']);
      expect(browser.backStack, ['/a', '/b']);

      router.pop();
      await settle(tester);

      expect(find.text('PageA'), findsOneWidget);
      expect(Modular.tryGet<ServiceB>(), isNull, reason: 'BModule saiu da pilha');
      expect(Modular.tryGet<ServiceA>(), isNotNull);
      expect(browser.ops, contains('go:-1'));
      expect(browser.ops.where((op) => op.startsWith('push:')).length, 1, reason: 'o pop não cria entrada nova');
      expect(browser.backStack, ['/a']);
      expect(provider().debugIndex, 0);
    });

    testWidgets('pop numa pilha de três níveis recua exatamente uma entrada', (tester) async {
      final router = await boot(tester);

      router.go('/a/x');
      await settle(tester);
      router.push('/b');
      await settle(tester);
      expect(browser.backStack, ['/a', '/a/x', '/b']);
      browser.ops.clear();

      router.pop();
      await settle(tester);

      expect(find.text('PageAX'), findsOneWidget);
      expect(browser.ops.first, 'go:-1', reason: 'a entrada [/a, /a/x] já existe: basta recuar uma');
      expect(browser.ops.where((op) => op.startsWith('push:')), isEmpty, reason: 'nenhuma entrada nova deve ser criada num pop');
      expect(browser.backStack, ['/a', '/a/x']);
    });

    testWidgets('o popstate provocado pelo pop é engolido: nada é re-parseado e guards não reexecutam', (tester) async {
      final router = await boot(tester);

      router.push('/b');
      await settle(tester);
      final guardRunsBeforePop = aGuardRuns;

      // Pop pelo Navigator (AppBar/gesto): muda a configuração sem `restore`,
      // então qualquer reexecução de guard só poderia vir do popstate.
      router.routerDelegate.navigatorKey.currentState!.pop();
      await settle(tester);

      expect(find.text('PageA'), findsOneWidget);
      expect(browser.ops, contains('go:-1'));
      expect(browser.backStack, ['/a']);
      expect(aGuardRuns, guardRunsBeforePop, reason: 'sem restore e com o popstate engolido, o guard de /a não roda');
    });

    testWidgets('go() para rota aninhada cresce a pilha (entrada nova) e go() de volta ao pai recua', (tester) async {
      final router = await boot(tester);

      router.go('/a/x');
      await settle(tester);
      expect(find.text('PageAX'), findsOneWidget);
      expect(browser.ops, ['replace:/a', 'push:/a/x']);

      router.go('/a');
      await settle(tester);
      expect(find.text('PageA'), findsOneWidget);
      expect(browser.ops, contains('go:-1'));
      expect(browser.backStack, ['/a']);
      expect(Modular.tryGet<ServiceA>(), isNotNull);
    });

    testWidgets('go() para rota irmã substitui a entrada do topo (pilha: [/a, /a/y])', (tester) async {
      final router = await boot(tester);

      router.go('/a/x');
      await settle(tester);
      router.go('/a/y');
      await settle(tester);

      expect(find.text('PageAY'), findsOneWidget);
      expect(browser.ops, ['replace:/a', 'push:/a/x', 'go:-1', 'push:/a/y']);
      expect(browser.backStack, ['/a', '/a/y']);
    });

    testWidgets('go() para rota de outro módulo a partir de pilha profunda colapsa o histórico', (tester) async {
      final router = await boot(tester);

      router.go('/a/x');
      await settle(tester);
      router.go('/b');
      await settle(tester);

      expect(find.text('PageB'), findsOneWidget);
      expect(Modular.tryGet<ServiceA>(), isNull);
      expect(browser.ops, ['replace:/a', 'push:/a/x', 'go:-1', 'replace:/b']);
      expect(browser.backStack, ['/b'], reason: 'como no nativo, a pilha é só [/b]: o voltar sai do app');
    });

    testWidgets('push() seguido de go() colapsa: o voltar não volta à página empurrada', (tester) async {
      final router = await boot(tester);

      router.push('/a/x');
      await settle(tester);
      expect(browser.locations, ['/a', '/a/x']);

      router.go('/b');
      await settle(tester);

      expect(find.text('PageB'), findsOneWidget);
      expect(browser.ops, ['replace:/a', 'push:/a/x', 'go:-1', 'replace:/b']);
      expect(browser.backStack, ['/b']);
    });

    testWidgets('voltar real do usuário faz pop (restore) sem criar entradas', (tester) async {
      final router = await boot(tester);

      router.push('/b');
      await settle(tester);
      expect(browser.locations, ['/a', '/b']);
      final guardRunsBeforeBack = aGuardRuns;

      await browser.userBack();
      await settle(tester);
      expect(find.text('PageA'), findsOneWidget);
      expect(Modular.tryGet<ServiceB>(), isNull, reason: 'BModule saiu da pilha ao voltar');
      expect(Modular.tryGet<ServiceA>(), isNotNull);
      expect(aGuardRuns, greaterThan(guardRunsBeforeBack), reason: 'voltar real = restore do go_router: guards rodam');
      expect(browser.ops.where((op) => op.startsWith('push:')).length, 1, reason: 'nenhuma entrada nova foi criada pelo restore');
      expect(browser.backStack, ['/a']);
      expect(provider().debugIndex, 0);
    });

    testWidgets('avançar real do usuário navega pela URL: redirects rodam e o módulo da página com push volta com binds', (tester) async {
      final router = await boot(tester);

      router.push('/b');
      await settle(tester);
      await browser.userBack();
      await settle(tester);
      expect(Modular.tryGet<ServiceB>(), isNull);

      await browser.userForward();
      await settle(tester);

      expect(find.text('PageB'), findsOneWidget);
      expect(Modular.tryGet<ServiceB>(), isNotNull,
          reason: 'o go_router não roda redirects ao restaurar páginas de push; navegando pela URL o módulo é registrado');
      expect(browser.ops.last, 'replace:/b', reason: 'o report substitui a entrada em que o navegador já está');
      expect(browser.backStack, ['/a', '/b']);
      expect(provider().debugIndex, 1);
    });

    testWidgets('entrada de histórico desconhecida (criada antes de um reload) é tratada como deep link', (tester) async {
      final router = await boot(tester);
      router.go('/b');
      await settle(tester);

      // Simula uma entrada anterior ao boot deste router (ex.: antes de um F5).
      browser.entries.insert(0, const _HistoryEntry('/a/x', <String, Object?>{'stale': true}));
      browser.index = 1;
      await browser.userBack();
      await settle(tester);

      expect(find.text('PageAX'), findsOneWidget);
      expect(Modular.tryGet<ServiceA>(), isNotNull);
      expect(Modular.tryGet<ServiceB>(), isNull);
      expect(browser.ops.last, 'replace:/a/x');
      expect(browser.backStack, ['/a/x']);
    });

    testWidgets('pop mantém o value do provider em dia: refresh não ressuscita a página', (tester) async {
      final router = await boot(tester);

      router.push('/b');
      await settle(tester);
      expect(provider().value.uri.path, '/b');

      // Pop pelo Navigator (AppBar/gesto/botão do sistema): não passa pelo
      // `restore` do GoRouter, então só o report mantém o `value` em dia.
      router.routerDelegate.navigatorKey.currentState!.pop();
      await settle(tester);
      expect(find.text('PageA'), findsOneWidget);
      expect(provider().value.uri.path, '/a', reason: 'o provider não pode continuar apontando para a página que saiu');

      router.refresh();
      await settle(tester);

      expect(find.text('PageA'), findsOneWidget, reason: 'um refresh re-parseia o value: se estivesse velho, PageB voltaria');
      expect(Modular.tryGet<ServiceB>(), isNull, reason: 'BModule continua descartado');
    });

    testWidgets('recuo sem popstate se destrava e volta a reportar a URL', (tester) async {
      final router = await boot(tester);

      router.go('/a/x');
      await settle(tester);
      browser.deliverPopstate = false;

      // Encolhe a pilha: pede history.go(-1), que o navegador engole.
      router.go('/a');
      await settle(tester);
      browser.deliverPopstate = true;
      browser.ops.clear();

      router.go('/b');
      await settle(tester);

      expect(find.text('PageB'), findsOneWidget);
      expect(browser.ops, isNotEmpty, reason: 'a URL precisa voltar a ser reportada depois do prazo');
      expect(browser.backStack.last, '/b');
    });
  });

  group('contagem de referências dos módulos fica balanceada', () {
    testWidgets('go() entre rotas irmãs do mesmo módulo não vaza o módulo', (tester) async {
      final router = await boot(tester);
      final aModule = WebAppModule().routes.whereType<ModuleRoute>().first.module;
      expect(aModule, isA<AModule>());

      router.go('/a/x');
      await settle(tester);
      router.go('/a/y');
      await settle(tester);
      router.go('/b');
      await settle(tester);

      expect(find.text('PageB'), findsOneWidget);
      expect(Modular.tryGet<ServiceA>(), isNull, reason: 'AModule saiu da pilha e deve ser descartado');
    });

    testWidgets('push() + pop() do mesmo módulo e depois go() para fora descarta o módulo', (tester) async {
      final router = await boot(tester);

      router.push('/a');
      await settle(tester);
      router.pop();
      await settle(tester);
      expect(Modular.tryGet<ServiceA>(), isNotNull, reason: 'a entrada de baixo ainda referencia A');

      router.go('/b');
      await settle(tester);
      expect(Modular.tryGet<ServiceA>(), isNull);
    });

    testWidgets('guard que desvia antes de criar a página não deixa o módulo registrado', (tester) async {
      final router = await boot(tester);

      router.go('/c');
      await settle(tester);

      expect(find.text('PageA'), findsOneWidget, reason: 'o guard de C desvia para /a');
      expect(Modular.tryGet<ServiceC>(), isNull, reason: 'CModule nunca virou página: a referência pendente expira');
      expect(Modular.tryGet<ServiceA>(), isNotNull);
    });

    testWidgets('shell stateful não descarta duas vezes o módulo de uma branch', (tester) async {
      final router = await boot(tester, initialRoute: '/shared', appModule: ShellAppModule());
      expect(find.text('PageShared'), findsOneWidget);
      expect(Modular.tryGet<ServiceShared>(), isNotNull);

      router.push('/tabs');
      await settle(tester);
      expect(InjectionManager.instance.referenceCountOf(sharedLeafModule), 2, reason: 'a branch e a rota de baixo referenciam a mesma instância');

      router.pop();
      await settle(tester);

      expect(find.text('PageShared'), findsOneWidget);
      expect(Modular.tryGet<ServiceShared>(), isNotNull, reason: 'a página de baixo ainda usa o módulo: os binds não podem sumir');
      expect(InjectionManager.instance.referenceCountOf(sharedLeafModule), 1);
    });

    testWidgets('A → B → A rápido (transição em andamento) não descarta os binds de A', (tester) async {
      final router = await boot(tester);

      router.go('/b');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      router.go('/a');
      await settle(tester);

      expect(find.text('PageA'), findsOneWidget);
      expect(Modular.tryGet<ServiceA>(), isNotNull);
      expect(Modular.tryGet<ServiceB>(), isNull);

      router.go('/b');
      await settle(tester);
      expect(Modular.tryGet<ServiceA>(), isNull, reason: 'sem referência fantasma: A é descartado ao sair');
    });
  });
}
