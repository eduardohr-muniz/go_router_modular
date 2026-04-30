/// Regression: AppModule binds instanciados 3x quando um RouteModule importa o AppModule.
///
/// Causa:
///   _collectImportedBinds chama module.binds(injector) novamente para cada módulo
///   importado, criando NOVOS objetos Bind com cachedInstance == null.
///   commitBatch pula esses novos Bind (já existe o tipo em bindsMap — fast-path),
///   mas não propaga cachedInstance para o novo objeto.
///   Resultado: _mapBindsToIdentifiers e _validateModuleBinds encontram
///   cachedInstance == null e chamam factoryFunction → construtor executado 2x extra.

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/src/core/bind/bind.dart';
import 'package:go_router_modular/src/di/injector.dart';

// ======================== CLASSES DE TESTE ========================

class UserBloc {
  static int constructorCalls = 0;
  UserBloc() {
    constructorCalls++;
  }
}

class SupabaseClient {
  static int constructorCalls = 0;
  SupabaseClient() {
    constructorCalls++;
  }
}

// ======================== HELPER ========================

List<Bind<Object>> _collectBinds(Injector injector, void Function() register) {
  injector.startRegistering();
  register();
  return injector.finishRegistering();
}

// ======================== TESTES ========================

void main() {
  final injector = Injector();

  setUp(() {
    Bind.clearAll();
    UserBloc.constructorCalls = 0;
    SupabaseClient.constructorCalls = 0;
  });

  tearDown(() {
    Bind.clearAll();
    UserBloc.constructorCalls = 0;
    SupabaseClient.constructorCalls = 0;
  });

  group('AppModule bind 3x regression', () {
    test(
      'bind duplicado (novo objeto Bind via import) deve ter cachedInstance propagado no fast-path',
      () {
        // === Simula: AppModule é registrado na inicialização do app ===
        // InjectionManager._registerBindsModuleInternal → registerBatch + commitBatch
        final appModuleBinds = _collectBinds(injector, () {
          injector.addSingleton((i) => UserBloc());
        });
        Bind.registerBatch(appModuleBinds);
        Bind.commitBatch(injector);

        expect(UserBloc.constructorCalls, 1, reason: 'baseline: AppModule registra 1x');

        // === Simula: RouteModule importa AppModule ===
        // _collectImportedBinds chama AppModule.binds(injector) de novo →
        // novos objetos Bind com cachedInstance == null
        final routeImportedBinds = _collectBinds(injector, () {
          injector.addSingleton((i) => UserBloc()); // mesmo tipo, novo objeto Bind
        });
        Bind.registerBatch(routeImportedBinds);
        // fast-path: tipo já em bindsMap → skipa factory, MAS deve propagar cachedInstance
        Bind.commitBatch(injector);

        // O novo objeto Bind deve ter cachedInstance != null após o fast-path
        for (final bind in routeImportedBinds) {
          expect(
            bind.cachedInstance,
            isNotNull,
            reason:
                'Bind duplicado pulado pelo fast-path deve ter cachedInstance propagado do '
                'bind já registrado. Sem isso, _mapBindsToIdentifiers e _validateModuleBinds '
                'chamam factoryFunction novamente.',
          );
        }

        // Total: apenas 1 construção
        expect(UserBloc.constructorCalls, 1);
      },
    );

    test(
      'simula _mapBindsToIdentifiers: não deve chamar factory para binds duplicados após commitBatch',
      () {
        // Registro inicial (AppModule)
        final appModuleBinds = _collectBinds(injector, () {
          injector.addSingleton((i) => UserBloc());
          injector.addSingleton((i) => SupabaseClient());
        });
        Bind.registerBatch(appModuleBinds);
        Bind.commitBatch(injector);

        // Registro via RouteModule que importa AppModule (novos Bind objects)
        final routeImportedBinds = _collectBinds(injector, () {
          injector.addSingleton((i) => UserBloc());
          injector.addSingleton((i) => SupabaseClient());
        });
        Bind.registerBatch(routeImportedBinds);
        Bind.commitBatch(injector);

        // Reset para medir somente chamadas pós-commitBatch
        UserBloc.constructorCalls = 0;
        SupabaseClient.constructorCalls = 0;

        // Simula o que _mapBindsToIdentifiers e _validateModuleBinds fazem:
        // bind.cachedInstance ?? bind.factoryFunction(injector)
        final allRouteBinds = [...appModuleBinds, ...routeImportedBinds];
        for (final bind in allRouteBinds) {
          bind.cachedInstance ?? bind.factoryFunction(injector);
        }

        expect(
          UserBloc.constructorCalls,
          0,
          reason:
              'Nenhuma chamada extra deve ocorrer: cachedInstance propagado no fast-path '
              'evita o fallback para factoryFunction em _mapBindsToIdentifiers',
        );
        expect(SupabaseClient.constructorCalls, 0);
      },
    );

    test(
      'simula _validateModuleBinds: bind duplicado não deve acionar factory após commitBatch',
      () {
        // Registro inicial (AppModule)
        final appModuleBinds = _collectBinds(injector, () {
          injector.addSingleton((i) => UserBloc());
        });
        Bind.registerBatch(appModuleBinds);
        Bind.commitBatch(injector);

        // Simula RouteModule importando AppModule (novo Bind object)
        final routeImportedBinds = _collectBinds(injector, () {
          injector.addSingleton((i) => UserBloc());
        });
        Bind.registerBatch(routeImportedBinds);
        Bind.commitBatch(injector);

        // Reset
        UserBloc.constructorCalls = 0;

        // _validateModuleBinds itera sobre allBinds do RouteModule (inclui os imports):
        final allRouteModuleBinds = [...routeImportedBinds]; // equivalente ao allBinds do route
        for (final bind in allRouteModuleBinds) {
          // Reproduz exatamente o que _validateModuleBinds faz:
          final _ = bind.cachedInstance ?? bind.factoryFunction(injector);
        }

        expect(
          UserBloc.constructorCalls,
          0,
          reason:
              '_validateModuleBinds não deve chamar factory se cachedInstance '
              'foi propagado durante o fast-path do commitBatch',
        );
      },
    );

    test(
      'cenário completo: 3 etapas (commitBatch + _mapBindsToIdentifiers + _validateModuleBinds) '
      'devem resultar em exatamente 1 construção',
      () {
        // Etapa 1: AppModule registrado → commitBatch
        final appBinds = _collectBinds(injector, () {
          injector.addSingleton((i) => UserBloc());
        });
        Bind.registerBatch(appBinds);
        Bind.commitBatch(injector); // call 1 (correta)

        // Etapa 2: RouteModule importa AppModule → novos Bind objects
        final routeBinds = _collectBinds(injector, () {
          injector.addSingleton((i) => UserBloc());
        });
        Bind.registerBatch(routeBinds);
        Bind.commitBatch(injector); // fast-path: deve pular SEM criar instância

        // Etapa 3: _mapBindsToIdentifiers no RouteModule
        for (final bind in routeBinds) {
          bind.cachedInstance ?? bind.factoryFunction(injector); // não deve chamar factory
        }

        // Etapa 4: _validateModuleBinds no RouteModule
        for (final bind in routeBinds) {
          bind.cachedInstance ?? bind.factoryFunction(injector); // não deve chamar factory
        }

        expect(
          UserBloc.constructorCalls,
          1,
          reason:
              'UserBloc deve ser instanciado exatamente 1x em todo o ciclo '
              '(commitBatch + _mapBindsToIdentifiers + _validateModuleBinds)',
        );
      },
    );
  });
}
