import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/src/core/bind/bind.dart';
import 'package:go_router_modular/src/di/injector.dart';
import 'package:go_router_modular/src/exceptions/exception.dart';

/// Regressão: padrão clássico "factory sem tipo + get<Interface>" deve
/// continuar funcionando sem breaking change.
///
/// Problema reportado pelo usuário: após Change #3, o padrão abaixo passou a
/// lançar NotFound (breaking change indesejado):
///
/// ```dart
/// i.addFactory((i) => ServiceImpl()); // Dart infere T = ServiceImpl
/// i.get<IService>();                   // ❌ lançava GoRouterModularException
/// ```
///
/// Ao mesmo tempo, o motor NÃO deve invocar o factory durante lookups
/// não relacionados (o bug de instâncias fantasmas que motivou a Change #3).
///
/// Meta desta suíte: AMBAS as propriedades devem ser verdadeiras
/// simultaneamente — sem breaking change E sem phantom instances.

abstract interface class IService {
  String get name;
}

abstract interface class IRepository {
  String get data;
}

abstract interface class IUnrelated {
  void doSomething();
}

class ServiceImpl implements IService {
  static int constructed = 0;
  static final List<String> sideEffectsLog = [];

  ServiceImpl() {
    constructed++;
    sideEffectsLog.add('ServiceImpl-built-$constructed');
  }

  @override
  String get name => 'service-impl';
}

class RepositoryImpl implements IRepository {
  static int constructed = 0;
  RepositoryImpl() {
    constructed++;
  }

  @override
  String get data => 'repo-data';
}

class MultiImpl implements IService, IRepository {
  static int constructed = 0;
  MultiImpl() {
    constructed++;
  }

  @override
  String get name => 'multi-impl';

  @override
  String get data => 'multi-repo-data';
}

void main() {
  final injector = Injector();

  setUp(() {
    Bind.clearAll();
    ServiceImpl.constructed = 0;
    ServiceImpl.sideEffectsLog.clear();
    RepositoryImpl.constructed = 0;
    MultiImpl.constructed = 0;
  });
  tearDown(Bind.clearAll);

  // ══════════════════════════════════════════════════════════════════════════
  // Grupo 1: padrão sem tipo deve funcionar (era o breaking change)
  // ══════════════════════════════════════════════════════════════════════════

  group('factory sem tipo resolve pela interface (sem breaking change)', () {
    test('addFactory untyped + get<IService> deve funcionar', () {
      injector.startRegistering();
      // Dart infere T = ServiceImpl — bind fica Bind<ServiceImpl>
      injector.add((i) => ServiceImpl());
      final binds = injector.finishRegistering();
      Bind.registerBatch(binds);
      Bind.commitBatch(injector);

      // Deve resolver sem lançar — este era o breaking change
      final svc = Bind.get<IService>();
      expect(svc, isA<ServiceImpl>());
      expect(svc.name, 'service-impl');
    });

    test('addFactory untyped + get<IRepository> deve funcionar', () {
      injector.startRegistering();
      injector.add((i) => RepositoryImpl());
      final binds = injector.finishRegistering();
      Bind.registerBatch(binds);
      Bind.commitBatch(injector);

      final repo = Bind.get<IRepository>();
      expect(repo, isA<RepositoryImpl>());
      expect(repo.data, 'repo-data');
    });

    test('factory explicitamente tipado pela interface ainda funciona', () {
      injector.startRegistering();
      injector.add<IService>((i) => ServiceImpl());
      final binds = injector.finishRegistering();
      Bind.registerBatch(binds);
      Bind.commitBatch(injector);

      final svc = Bind.get<IService>();
      expect(svc, isA<ServiceImpl>());
    });

    test('implementação de múltiplas interfaces resolve ambas', () {
      injector.startRegistering();
      injector.addSingleton((i) => MultiImpl());
      final binds = injector.finishRegistering();
      Bind.registerBatch(binds);
      Bind.commitBatch(injector);

      final svc = Bind.get<IService>();
      final repo = Bind.get<IRepository>();
      expect(svc, isA<MultiImpl>());
      expect(repo, isA<MultiImpl>());
      // Deve ser a MESMA instância (singleton)
      expect(identical(svc, repo), isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Grupo 2: factory NÃO deve ser invocado para lookups não relacionados
  // (o bug original de phantom instances que motivou a Change #3)
  // ══════════════════════════════════════════════════════════════════════════

  group('factory não é invocado para lookups não relacionados', () {
    test('get<IUnrelated> não deve invocar factory de ServiceImpl', () {
      injector.startRegistering();
      injector.add((i) => ServiceImpl());
      final binds = injector.finishRegistering();
      Bind.registerBatch(binds);
      Bind.commitBatch(injector);

      expect(ServiceImpl.constructed, 0, reason: 'zero invocações na inicialização');

      expect(
        () => Bind.get<IUnrelated>(),
        throwsA(isA<GoRouterModularException>()),
      );

      expect(ServiceImpl.constructed, 0,
          reason: 'factory NÃO deve ser invocado para lookup de tipo não relacionado');
      expect(ServiceImpl.sideEffectsLog, isEmpty,
          reason: 'nenhum efeito colateral deve vazar');
    });

    test('múltiplos lookups não relacionados: zero invocações acumuladas', () {
      injector.startRegistering();
      injector.add((i) => ServiceImpl());
      injector.add((i) => RepositoryImpl());
      final binds = injector.finishRegistering();
      Bind.registerBatch(binds);
      Bind.commitBatch(injector);

      for (var i = 0; i < 5; i++) {
        try {
          Bind.get<IUnrelated>();
        } catch (_) {}
      }

      expect(ServiceImpl.constructed, 0);
      expect(RepositoryImpl.constructed, 0);
    });

    test('lookup legítimo por tipo concreto ainda invoca o factory', () {
      injector.startRegistering();
      injector.add((i) => ServiceImpl());
      final binds = injector.finishRegistering();
      Bind.registerBatch(binds);
      Bind.commitBatch(injector);

      final svc = Bind.get<ServiceImpl>();
      expect(svc, isA<ServiceImpl>());
      expect(ServiceImpl.constructed, 1);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Grupo 3: singleton — comportamento de cache preservado
  // ══════════════════════════════════════════════════════════════════════════

  group('singleton via interface preserva identidade', () {
    test('singleton untyped resolve pela interface e retorna mesma instância', () {
      injector.startRegistering();
      injector.addSingleton((i) => ServiceImpl());
      final binds = injector.finishRegistering();
      Bind.registerBatch(binds);
      Bind.commitBatch(injector);

      final a = Bind.get<IService>();
      final b = Bind.get<IService>();
      expect(identical(a, b), isTrue, reason: 'singleton deve retornar mesma instância');
    });

    test('singleton não é invocado durante lookup não relacionado', () {
      injector.startRegistering();
      injector.addSingleton((i) => ServiceImpl());
      final binds = injector.finishRegistering();
      Bind.registerBatch(binds);
      Bind.commitBatch(injector);

      final builtInCommit = ServiceImpl.constructed;

      try {
        Bind.get<IUnrelated>();
      } catch (_) {}

      expect(ServiceImpl.constructed, builtInCommit,
          reason: 'singleton não deve ser reinvocado para lookup não relacionado');
    });
  });
}
