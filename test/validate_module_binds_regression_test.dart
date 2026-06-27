/// TDD — reproduz o bug onde `_validateModuleBinds` lança
/// `GoRouterModularException` ao tentar instanciar um bind *factory* cujas
/// dependências já foram removidas (porque `_unregisterBinds` roda ANTES da
/// validação dentro de `_unregisterModuleInternal`).
///
/// Consequência no app:
///   1. A exceção propaga via `rethrow` na `OperationQueue`.
///   2. Operações subsequentes na fila (ex: `registerBindsModule`) nunca executam.
///   3. `_buildRedirectAndInjectBinds` fica aguardando o completer → loading infinito.
///
/// Cenário reproduzido:
///   - AppModule registra `SharedPreferences` (dependência raiz).
///   - RouteModule registra `PaineisRepository` (singleton) + `PaineisListCubit`
///     (factory que depende de PaineisRepository).
///   - RouteModule é desregistrado (usuário volta da tela) → validação roda
///     DEPOIS que PaineisRepository foi removido do bindsMap.
///   - Um novo `registerBindsModule` é enfileirado → DEVE concluir normalmente.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/shared/setup.dart';

// ---------------------------------------------------------------------------
// Tipos de teste
// ---------------------------------------------------------------------------

class FakePrefs {
  static int constructorCalls = 0;
  FakePrefs() {
    constructorCalls++;
  }
}

class FakeRepository {
  static int constructorCalls = 0;
  final FakePrefs prefs;
  FakeRepository({required this.prefs}) {
    constructorCalls++;
  }
}

class FakeCubit {
  static int constructorCalls = 0;
  final FakeRepository repository;
  FakeCubit({required this.repository}) {
    constructorCalls++;
  }
}

// ---------------------------------------------------------------------------
// Módulos
// ---------------------------------------------------------------------------

class FakeAppModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<FakePrefs>((_) => FakePrefs());
  }

  @override
  List<ModularRoute> get routes => const [];
}

class FakeRouteModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<FakeRepository>((i) => FakeRepository(prefs: i.get()));
    i.addFactory<FakeCubit>((i) => FakeCubit(repository: i.get()));
  }

  @override
  List<ModularRoute> get routes => const [];
}

void _resetCounters() {
  FakePrefs.constructorCalls = 0;
  FakeRepository.constructorCalls = 0;
  FakeCubit.constructorCalls = 0;
}

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    InjectionManager.instance.resetForTesting();
    _resetCounters();
  });

  tearDown(() {
    InjectionManager.instance.resetForTesting();
    _resetCounters();
  });

  group('_validateModuleBinds: não deve lançar exceção ao desregistrar módulo com factory bind', () {
    test(
      'sem debugLog: desregistrar RouteModule não lança exceção',
      () async {
        final appModule = FakeAppModule();
        final routeModule = FakeRouteModule();

        await InjectionManager.instance.registerAppModule(appModule);
        await InjectionManager.instance.registerBindsModule(routeModule);

        // Não deve lançar exceção ao desregistrar
        await expectLater(
          InjectionManager.instance.unregisterModule(routeModule),
          completes,
        );
      },
    );

    test(
      'COM debugLog ativo: desregistrar RouteModule não deve lançar GoRouterModularException',
      () async {
        // Este é o caso crítico: debugLogGoRouterModular=true ativa o `throw`
        // dentro de `_validateModuleBinds`, que interrompe a OperationQueue.
        SetupModular.instance.setDebugModel(
          SetupModel(
            debugLogEventBus: false,
            debugLogGoRouter: false,
            debugLogGoRouterModular: true,
            autoDisposeEvents: true,
          ),
        );

        final appModule = FakeAppModule();
        final routeModule = FakeRouteModule();

        await InjectionManager.instance.registerAppModule(appModule);
        await InjectionManager.instance.registerBindsModule(routeModule);

        // Não deve lançar GoRouterModularException — mesmo com debugLog ativo
        await expectLater(
          InjectionManager.instance.unregisterModule(routeModule),
          completes,
        );
      },
    );

    test(
      'COM debugLog: após desregistrar, novo registerBindsModule deve concluir (fila não trava)',
      () async {
        // Simula o cenário exato do bug no app:
        // 1. Navega para paineis → RouteModule registrado
        // 2. Volta da tela → RouteModule desregistrado (validação lança, interrompe fila)
        // 3. Navega para paineis novamente → registerBindsModule enfileirado
        //    → DEVE concluir (completer não pode ficar pendente para sempre)
        SetupModular.instance.setDebugModel(
          SetupModel(
            debugLogEventBus: false,
            debugLogGoRouter: false,
            debugLogGoRouterModular: true,
            autoDisposeEvents: true,
          ),
        );

        final appModule = FakeAppModule();
        final routeModule = FakeRouteModule();

        await InjectionManager.instance.registerAppModule(appModule);
        await InjectionManager.instance.registerBindsModule(routeModule);

        // Desregistra (dispara validação)
        await InjectionManager.instance.unregisterModule(routeModule);

        // Registra novamente — deve concluir sem timeout
        await expectLater(
          InjectionManager.instance.registerBindsModule(routeModule).timeout(
                const Duration(seconds: 2),
                onTimeout: () => fail(
                  'registerBindsModule travou: a exceção de validação interrompeu a '
                  'OperationQueue e o completer nunca foi completado.',
                ),
              ),
          completes,
        );

        // FakeRepository deve ter sido criado exatamente 2x (1 por registro)
        expect(FakeRepository.constructorCalls, 2,
            reason: 'FakeRepository deve ser re-instanciado no segundo registro');
      },
    );

    test(
      'validação não deve instanciar factory binds (apenas singletons devem ser validados)',
      () async {
        SetupModular.instance.setDebugModel(
          SetupModel(
            debugLogEventBus: false,
            debugLogGoRouter: false,
            debugLogGoRouterModular: true,
            autoDisposeEvents: true,
          ),
        );

        final appModule = FakeAppModule();
        final routeModule = FakeRouteModule();

        await InjectionManager.instance.registerAppModule(appModule);
        await InjectionManager.instance.registerBindsModule(routeModule);

        // Reset do contador APÓS o registro para medir apenas chamadas de validação
        FakeCubit.constructorCalls = 0;

        await InjectionManager.instance.unregisterModule(routeModule);

        expect(
          FakeCubit.constructorCalls,
          0,
          reason:
              'Factory binds não devem ser instanciados durante a validação — '
              'são transientes e suas dependências podem já ter sido dispostas.',
        );
      },
    );
  });
}
