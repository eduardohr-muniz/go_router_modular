import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';
// `ModularTelemetry` não é exportado no barril de propósito (estado estático
// interno); o teste alcança o src para conferir que nenhum listener ficou preso.
import 'package:go_router_modular/src/shared/telemetry.dart' show ModularTelemetry;

class HomeService {}

class DetailService {}

class HomeModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<HomeService>((i) => HomeService());
  }

  @override
  List<ModularRoute> get routes => [ChildRoute('/', name: 'home', child: (c, s) => const _Page('Home'))];
}

class DetailModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<DetailService>((i) => DetailService());
  }

  @override
  List<ModularRoute> get routes => [ChildRoute('/', name: 'detail', child: (c, s) => const _Page('Detail'))];
}

class GuardedService {}

/// Módulo cujo guard sempre redireciona: os binds são registrados pelo redirect,
/// mas nenhuma página do módulo chega a existir.
class GuardedModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<GuardedService>((i) => GuardedService());
  }

  @override
  List<ModularRoute> get routes => [
        ChildRoute(
          '/',
          name: 'guarded',
          guards: [GuardFn((context, state) => '/home')],
          child: (c, s) => const _Page('Guarded'),
        ),
      ];
}

class TelemetryAppModule extends Module {
  @override
  List<ModularRoute> get routes => [
        ModuleRoute('/home', module: HomeModule()),
        ModuleRoute('/detail', module: DetailModule()),
        ModuleRoute('/guarded', module: GuardedModule()),
      ];
}

class _Page extends StatelessWidget {
  const _Page(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text(title)));
}

class UserLoggedIn {}

class CartUpdated {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<ModularTelemetryEvent> events;

  Iterable<ModularModuleTelemetryEvent> of(String module) => events.whereType<ModularModuleTelemetryEvent>().where((e) => e.module == module);

  Iterable<ModularBusTelemetryEvent> busEvents() => events.whereType<ModularBusTelemetryEvent>();

  /// Drena o timer de 500 ms do agendamento de validação de binds, para que o
  /// teste não termine com timers pendentes.
  Future<void> drain(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  Future<void> boot(
    WidgetTester tester, {
    ModularTelemetryCallback? onTelemetry,
    ModularTelemetryFilter? filter,
  }) async {
    Modular.resetForTesting();
    events = <ModularTelemetryEvent>[];
    await Modular.configure(
      appModule: TelemetryAppModule(),
      initialRoute: '/home',
      debugLogDiagnostics: false,
      onTelemetry: onTelemetry ?? events.add,
      telemetryFilter: filter,
    );
    await tester.pumpWidget(MaterialApp.router(
      routerConfig: Modular.routerConfig,
      builder: (c, child) => ModularLoader.builder(c, child),
    ));
    await tester.pumpAndSettle();
    await drain(tester);
  }

  tearDown(Modular.resetForTesting);

  // ── Ciclo de vida dos módulos ──────────────────────────────────────────────

  testWidgets('reporta a injeção do AppModule e do módulo da rota inicial', (tester) async {
    await boot(tester);

    final injectedApp = of('TelemetryAppModule').firstWhere((e) => e.kind == ModularTelemetryKind.injected);
    expect(injectedApp.trigger, ModularTelemetryTrigger.bootstrap, reason: 'o AppModule não vem de uma navegação');

    final injectedHome = of('HomeModule').firstWhere((e) => e.kind == ModularTelemetryKind.injected);
    expect(injectedHome.trigger, ModularTelemetryTrigger.navigation);
    expect(injectedHome.referenceCount, 1);
    expect(injectedHome.binds, contains('HomeService'));

    // A página assumiu a referência que o redirect abriu.
    expect(of('HomeModule').map((e) => e.kind), contains(ModularTelemetryKind.referenceClaimed));
  });

  testWidgets('reporta o dispose com os binds descartados', (tester) async {
    await boot(tester);
    events.clear();

    Modular.routerConfig.go('/detail');
    await tester.pumpAndSettle();
    await drain(tester);

    final injectedDetail = of('DetailModule').firstWhere((e) => e.kind == ModularTelemetryKind.injected);
    expect(injectedDetail.binds, contains('DetailService'));

    final disposedHome = of('HomeModule').firstWhere((e) => e.kind == ModularTelemetryKind.disposed);
    expect(disposedHome.trigger, ModularTelemetryTrigger.pageDisposed);
    expect(disposedHome.referenceCount, 0);
    expect(disposedHome.binds, contains('HomeService'));
  });

  testWidgets('referência que nenhuma página reclamou vem marcada como expirada', (tester) async {
    await boot(tester);
    events.clear();

    // O guard de /guarded redireciona para /home: os binds são registrados pelo
    // redirect, mas nenhuma página do módulo existe para reclamar a referência.
    Modular.routerConfig.go('/guarded');
    await tester.pumpAndSettle();
    await drain(tester);

    expect(of('GuardedModule').map((e) => e.kind), contains(ModularTelemetryKind.injected));
    final expired = of('GuardedModule').firstWhere((e) => e.trigger == ModularTelemetryTrigger.unclaimedNavigationExpired);
    expect(expired.kind, ModularTelemetryKind.disposed);
    expect(expired.referenceCount, 0);
    expect(expired.binds, contains('GuardedService'));
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('toMap serve de breadcrumb', (tester) async {
    await boot(tester);

    final injected = of('HomeModule').firstWhere((e) => e.kind == ModularTelemetryKind.injected);
    final map = injected.toMap();
    expect(map['kind'], 'injected');
    expect(map['trigger'], 'navigation');
    expect(map['module'], 'HomeModule');
    expect(map['instanceId'], injected.instanceId);
    expect(map['referenceCount'], 1);
    expect(map['binds'], contains('HomeService'));
    expect(DateTime.tryParse(map['timestamp']! as String), isNotNull);
  });

  testWidgets('instâncias diferentes do mesmo módulo têm instanceId diferente', (tester) async {
    await boot(tester);

    final home = of('HomeModule').first;
    final app = of('TelemetryAppModule').first;
    expect(home.instanceId, isNot(app.instanceId));

    // Todo evento da MESMA instância carrega o mesmo id: é o que permite
    // distinguir um módulo reentrado (mesmo objeto, contagem 1 → 2) de um
    // recém-construído (outro objeto, contagem própria começando em 1).
    expect(of('HomeModule').map((e) => e.instanceId).toSet(), hasLength(1));
  });

  testWidgets('exceção no callback não quebra a navegação', (tester) async {
    await boot(tester, onTelemetry: (e) => throw StateError('sentry caiu'));

    expect(Modular.tryGet<HomeService>(), isNotNull);
    expect(tester.takeException(), isNull);

    Modular.routerConfig.go('/detail');
    await tester.pumpAndSettle();
    await drain(tester);
    expect(find.text('Detail'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sem onTelemetry nenhum listener fica registrado', (tester) async {
    Modular.resetForTesting();
    await Modular.configure(
      appModule: TelemetryAppModule(),
      initialRoute: '/home',
      debugLogDiagnostics: false,
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: Modular.routerConfig));
    await tester.pumpAndSettle();
    await drain(tester);

    expect(ModularTelemetry.hasListener, isFalse);
    expect(find.text('Home'), findsOneWidget, reason: 'a navegação roda normalmente sem telemetria');
  });

  // ── Event bus ──────────────────────────────────────────────────────────────

  testWidgets('fire e entrega no bus são reportados', (tester) async {
    await boot(tester);
    ModularEvent.instance.on<UserLoggedIn>((e, c) {});
    events.clear();

    ModularEvent.fire(UserLoggedIn());
    await tester.pumpAndSettle();

    final kinds = busEvents().where((e) => e.event == 'UserLoggedIn').map((e) => e.kind);
    expect(kinds, contains(ModularTelemetryKind.eventFired));
    expect(kinds, contains(ModularTelemetryKind.eventReceived), reason: 'havia um listener inscrito');

    final fired = busEvents().firstWhere((e) => e.kind == ModularTelemetryKind.eventFired);
    expect(fired.busId, defaultModularEventBus.hashCode);
    expect(fired.toMap()['event'], 'UserLoggedIn');
  });

  testWidgets('evento sem ninguém escutando aparece só como eventFired', (tester) async {
    await boot(tester);
    events.clear();

    ModularEvent.fire(CartUpdated());
    await tester.pumpAndSettle();

    final kinds = busEvents().where((e) => e.event == 'CartUpdated').map((e) => e.kind).toList();
    expect(kinds, [ModularTelemetryKind.eventFired], reason: 'publicado sem listener: nada foi recebido');
  });

  testWidgets('bus customizado é distinguido pelo busId', (tester) async {
    await boot(tester);
    final custom = EventBus();
    events.clear();

    ModularEvent.fire(CartUpdated(), eventBus: custom);
    await tester.pumpAndSettle();

    final fired = busEvents().firstWhere((e) => e.kind == ModularTelemetryKind.eventFired);
    expect(fired.busId, custom.hashCode);
    expect(fired.busId, isNot(defaultModularEventBus.hashCode));
  });

  // ── Filtro ─────────────────────────────────────────────────────────────────

  testWidgets('filtro .injections(): só injected/disposed e sem binds', (tester) async {
    await boot(tester, filter: const ModularTelemetryFilter.injections());
    ModularEvent.instance.on<UserLoggedIn>((e, c) {});

    Modular.routerConfig.go('/detail');
    await tester.pumpAndSettle();
    await drain(tester);
    ModularEvent.fire(UserLoggedIn());
    await tester.pumpAndSettle();

    expect(
      events.map((e) => e.kind).toSet(),
      {ModularTelemetryKind.injected, ModularTelemetryKind.disposed},
      reason: 'referências e eventos de bus ficam de fora',
    );
    expect(
      events.whereType<ModularModuleTelemetryEvent>().every((e) => e.binds.isEmpty),
      isTrue,
      reason: 'includeBinds: false — os binds nem chegam a ser nomeados',
    );
  });

  testWidgets('filtro por módulo deixa passar só a feature vigiada', (tester) async {
    await boot(tester, filter: ModularTelemetryFilter(module: (name) => name == 'DetailModule'));

    Modular.routerConfig.go('/detail');
    await tester.pumpAndSettle();
    await drain(tester);

    expect(events, isNotEmpty);
    expect(
      events.whereType<ModularModuleTelemetryEvent>().map((e) => e.module).toSet(),
      {'DetailModule'},
    );
  });

  testWidgets('filtro .events(): nada de módulo, só o bus', (tester) async {
    await boot(tester, filter: const ModularTelemetryFilter.events());
    expect(events, isEmpty, reason: 'o bootstrap não emite evento de bus');

    ModularEvent.fire(UserLoggedIn());
    await tester.pumpAndSettle();

    expect(events, isNotEmpty);
    expect(events.every((e) => e.kind.isEvent), isTrue);
    expect(events.whereType<ModularModuleTelemetryEvent>(), isEmpty);
  });

  testWidgets('filtro .injections() aceita recorte por módulo', (tester) async {
    await boot(tester, filter: ModularTelemetryFilter.injections(module: (name) => name == 'DetailModule'));

    Modular.routerConfig.go('/detail');
    await tester.pumpAndSettle();
    await drain(tester);

    expect(events, isNotEmpty);
    final modules = events.whereType<ModularModuleTelemetryEvent>();
    expect(modules.map((e) => e.module).toSet(), {'DetailModule'});
    expect(modules.map((e) => e.kind).toSet(), everyElement(isIn(ModularTelemetryKind.injectionKinds)));
  });

  testWidgets('filtro por tipo de evento ignora os demais', (tester) async {
    await boot(tester, filter: ModularTelemetryFilter.events(event: (name) => name == 'CartUpdated'));

    ModularEvent.fire(UserLoggedIn());
    ModularEvent.fire(CartUpdated());
    await tester.pumpAndSettle();

    expect(busEvents().map((e) => e.event).toSet(), {'CartUpdated'});
  });

  testWidgets('sem filtro, as duas famílias chegam', (tester) async {
    await boot(tester);
    ModularEvent.fire(UserLoggedIn());
    await tester.pumpAndSettle();

    expect(events.whereType<ModularModuleTelemetryEvent>(), isNotEmpty);
    expect(events.whereType<ModularBusTelemetryEvent>(), isNotEmpty);
  });
}
