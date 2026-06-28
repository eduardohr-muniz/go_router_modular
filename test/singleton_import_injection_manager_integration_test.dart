/// TDD / integration: reproduz o caso em que o AppModule (ou equivalente) já foi
/// registrado e um módulo de rota chama `imports()` com um **novo** `AppModule()`,
/// gerando novos objetos [Bind] para os mesmos tipos — o cenário típico de
/// `AppConfigBloc created` 3–4× no console.
///
/// Os testes abaixo usam o [InjectionManager] real (não só registerBatch isolado)
/// para emular navegação: `registerAppModule` depois `registerBindsModule` no filho.
///
/// **Importante:** com `i.addSingleton<Object>(() => AppConfigBloc(...))` o batch
/// precisa executar a factory para inferir o tipo; por isso use
/// `i.addSingleton<AppConfigBloc>(...)` em código real para o fast-path de
/// singleton duplicado funcionar.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/shared/setup.dart';

// ---------------------------------------------------------------------------
// Tipos de teste (contagem de construções)
// ---------------------------------------------------------------------------

class AppConfigBloc {
  static int constructorCalls = 0;

  final AppRepository repository;
  final PushNotificationStub push;

  AppConfigBloc({required this.repository, required this.push}) {
    constructorCalls++;
  }
}

class AppRepository {
  static int constructorCalls = 0;

  AppRepository() {
    constructorCalls++;
  }
}

class PushNotificationStub {
  static int constructorCalls = 0;

  PushNotificationStub() {
    constructorCalls++;
  }
}

class HomeBloc {
  static int constructorCalls = 0;

  HomeBloc() {
    constructorCalls++;
  }
}

// ---------------------------------------------------------------------------
// Módulos
// ---------------------------------------------------------------------------

class TestAppModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<AppRepository>((_) => AppRepository());
    i.addSingleton<PushNotificationStub>((_) => PushNotificationStub());
    i.addSingleton<AppConfigBloc>(
      (i) => AppConfigBloc(
        repository: i.get<AppRepository>(),
        push: i.get<PushNotificationStub>(),
      ),
    );
  }

  @override
  List<ModularRoute> get routes => const [];
}

class TestHomeModule extends Module {
  @override
  FutureOr<List<Module>> imports() => [TestAppModule()];

  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<HomeBloc>((_) => HomeBloc());
  }

  @override
  List<ModularRoute> get routes => const [];
}

class TestCoreModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<AppRepository>((_) => AppRepository());
  }

  @override
  List<ModularRoute> get routes => const [];
}

/// App que importa Core — árvore semelhante ao app real (Core + Auth + ...).
/// Shell do app: importa Core (repos) antes do módulo que declara push + bloc,
/// para que `_collectImportedBinds` produza [AppRepository, Push, AppConfig].
/// Isto espelha um app real (Core → feature) sem violar a ordem de dependências.
class TestAppWithCoreModule extends Module {
  @override
  FutureOr<List<Module>> imports() => [
        TestCoreModule(),
        _TestAppShellBodyModule(),
      ];

  @override
  FutureOr<void> binds(Injector i) {}

  @override
  List<ModularRoute> get routes => const [];
}

class _TestAppShellBodyModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<PushNotificationStub>((_) => PushNotificationStub());
    i.addSingleton<AppConfigBloc>(
      (i) => AppConfigBloc(
        repository: i.get<AppRepository>(),
        push: i.get<PushNotificationStub>(),
      ),
    );
  }

  @override
  List<ModularRoute> get routes => const [];
}

class TestHomeImportingNestedAppModule extends Module {
  @override
  FutureOr<List<Module>> imports() => [TestAppWithCoreModule()];

  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<HomeBloc>((_) => HomeBloc());
  }

  @override
  List<ModularRoute> get routes => const [];
}

void _resetCounters() {
  AppConfigBloc.constructorCalls = 0;
  AppRepository.constructorCalls = 0;
  PushNotificationStub.constructorCalls = 0;
  HomeBloc.constructorCalls = 0;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    InjectionManager.instance.resetForTesting();
    SetupModular.instance.setDebugModel(
      SetupModel(
        debugLogEventBus: false,
        debugLogGoRouter: false,
        autoDisposeEvents: true,
        debugLogGoRouterModular: false,
      ),
    );
    _resetCounters();
  });

  setUp(() {
    InjectionManager.instance.resetForTesting();
    _resetCounters();
  });

  group('InjectionManager: singleton não deve ser construído 3× ao importar App de novo', () {
    test(
      'registerAppModule(TestApp) + registerBindsModule(Home importa TestApp) — tipos explícitos',
      () async {
        await InjectionManager.instance.registerAppModule(TestAppModule());
        expect(AppConfigBloc.constructorCalls, 1);
        expect(AppRepository.constructorCalls, 1);
        expect(PushNotificationStub.constructorCalls, 1);

        await InjectionManager.instance.registerBindsModule(TestHomeModule());

        expect(
          AppConfigBloc.constructorCalls,
          1,
          reason: 'Binds duplicados via imports() não devem chamar o construtor de novo',
        );
        expect(AppRepository.constructorCalls, 1);
        expect(PushNotificationStub.constructorCalls, 1);
        expect(HomeBloc.constructorCalls, 1);

        final bloc = Bind.get<AppConfigBloc>();
        expect(bloc, isA<AppConfigBloc>());
      },
    );

    test(
      'com debugLogModular ligado — logging não pode reinstanciar singleton duplicado',
      () async {
        SetupModular.instance.setDebugModel(
          SetupModel(
            debugLogEventBus: false,
            debugLogGoRouter: false,
            autoDisposeEvents: true,
            debugLogGoRouterModular: false,
          ),
        );

        await InjectionManager.instance.registerAppModule(TestAppModule());
        await InjectionManager.instance.registerBindsModule(TestHomeModule());

        expect(AppConfigBloc.constructorCalls, 1);
      },
    );

    test(
      'imports em árvore (Core ← App) — uma única construção por singleton',
      () async {
        await InjectionManager.instance.registerAppModule(TestAppWithCoreModule());
        expect(AppConfigBloc.constructorCalls, 1);
        expect(AppRepository.constructorCalls, 1);

        await InjectionManager.instance.registerBindsModule(TestHomeImportingNestedAppModule());

        expect(AppConfigBloc.constructorCalls, 1);
        expect(AppRepository.constructorCalls, 1);
        expect(HomeBloc.constructorCalls, 1);
      },
    );
  });
}
