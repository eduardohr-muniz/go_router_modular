import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

/// Escopo de binds por módulo (commit-time): ao registrar um módulo, validar
/// que seus binds resolvem dependências dentro do escopo (próprios + importados
/// + AppModule). Depender de bind de outro módulo não importado → erro no push.

class ServiceA {}

class ServiceB {}

/// Serviço de B que (erroneamente) depende de ServiceB sem B declarar/importar.
class BService {
  BService(this.dependency);
  final ServiceB dependency;
}

class EmptyAppModule extends Module {}

class FeatureAModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<ServiceA>((i) => ServiceA());
    i.addSingleton<ServiceB>((i) => ServiceB());
  }
}

/// B depende de ServiceB (de A), mas NÃO importa A nem injeta ServiceB.
class FeatureBBadModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<BService>((i) => BService(i.get<ServiceB>()));
  }
}

/// B correto: importa A, então enxerga ServiceB.
class FeatureBGoodModule extends Module {
  @override
  FutureOr<List<Module>> imports() => [FeatureAModule()];
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<BService>((i) => BService(i.get<ServiceB>()));
  }
}

// ---- Binds por INTERFACE → IMPLEMENTAÇÃO ----

abstract class IRepository {
  String load();
}

class RepositoryImpl implements IRepository {
  @override
  String load() => 'dados';
}

/// Serviço que depende da INTERFACE IRepository.
class ConsumerService {
  ConsumerService(this.repository);
  final IRepository repository;
}

/// Dono do bind registrado por interface (`addSingleton<IRepository>`).
class RepositoryOwnerModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<IRepository>((i) => RepositoryImpl());
  }
}

/// Módulo autocontido: declara a interface E o serviço que a usa.
class SelfContainedModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<IRepository>((i) => RepositoryImpl());
    i.addSingleton<ConsumerService>((i) => ConsumerService(i.get<IRepository>()));
  }
}

/// Consome IRepository de outro módulo SEM importar (má prática).
class ConsumerBadModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<ConsumerService>((i) => ConsumerService(i.get<IRepository>()));
  }
}

/// Consome IRepository importando o dono (correto).
class ConsumerGoodModule extends Module {
  @override
  FutureOr<List<Module>> imports() => [RepositoryOwnerModule()];
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<ConsumerService>((i) => ConsumerService(i.get<IRepository>()));
  }
}

void main() {
  final manager = InjectionManager.instance;

  setUp(() => manager.resetForTesting());

  test('B depende de ServiceB sem importar A → lança no registro de B', () async {
    await manager.registerAppModule(EmptyAppModule());
    await manager.registerBindsModule(FeatureAModule()); // A vivo (push anterior)

    await expectLater(
      manager.registerBindsModule(FeatureBBadModule()),
      throwsA(isA<GoRouterModularException>()),
    );
  });

  test('B importando A → registra sem erro', () async {
    await manager.registerAppModule(EmptyAppModule());
    await manager.registerBindsModule(FeatureBGoodModule());
    expect(Modular.tryGet<BService>(), isNotNull);
  });

  group('binds por interface → implementação', () {
    test('interface + serviço no MESMO módulo → sem erro', () async {
      await manager.registerAppModule(EmptyAppModule());
      await manager.registerBindsModule(SelfContainedModule());
      final service = Modular.get<ConsumerService>();
      expect(service.repository.load(), 'dados');
    });

    test('depende de IRepository de outro módulo SEM importar → lança', () async {
      await manager.registerAppModule(EmptyAppModule());
      await manager.registerBindsModule(RepositoryOwnerModule()); // dono vivo
      await expectLater(
        manager.registerBindsModule(ConsumerBadModule()),
        throwsA(isA<GoRouterModularException>()),
      );
    });

    test('depende de IRepository IMPORTANDO o dono → sem erro', () async {
      await manager.registerAppModule(EmptyAppModule());
      await manager.registerBindsModule(ConsumerGoodModule());
      final service = Modular.get<ConsumerService>();
      expect(service.repository.load(), 'dados');
    });

    test('IRepository fornecida pelo AppModule (global) → qualquer módulo enxerga', () async {
      await manager.registerAppModule(RepositoryOwnerModule()); // agora é o global
      await manager.registerBindsModule(ConsumerBadModule()); // não importa, mas é do AppModule
      final service = Modular.get<ConsumerService>();
      expect(service.repository.load(), 'dados');
    });
  });
}
