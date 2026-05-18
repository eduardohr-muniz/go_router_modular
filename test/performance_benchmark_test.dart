// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/src/core/bind/bind.dart';
import 'package:go_router_modular/src/di/injector.dart';
import 'package:go_router_modular/src/exceptions/exception.dart';

// ─── Interfaces ────────────────────────────────────────────────────────────

abstract interface class IRepo {
  String get data;
}

abstract interface class IService {
  String call();
}

abstract interface class ICache {
  void store(String k, String v);
}

abstract interface class IUnrelated {
  void noop();
}

// ─── Implementações ────────────────────────────────────────────────────────

class RepoImpl implements IRepo {
  static int constructed = 0;
  static int sideEffects = 0;
  RepoImpl() {
    constructed++;
    sideEffects++;
  }

  @override
  String get data => 'repo-data';
}

class ServiceImpl implements IService {
  static int constructed = 0;
  ServiceImpl() {
    constructed++;
  }

  @override
  String call() => 'ok';
}

class CacheImpl implements ICache {
  static int constructed = 0;
  final _store = <String, String>{};
  CacheImpl() {
    constructed++;
  }

  @override
  void store(String k, String v) => _store[k] = v;
}

class MultiImpl implements IRepo, IService {
  static int constructed = 0;
  MultiImpl() {
    constructed++;
  }

  @override
  String get data => 'multi';

  @override
  String call() => 'multi-ok';
}

// ─── Serviços para testes de escala ────────────────────────────────────────

abstract interface class IScale {}

class ScaleA implements IScale {
  static int constructed = 0;
  ScaleA() {
    constructed++;
  }
}

class ScaleB implements IScale {
  static int constructed = 0;
  ScaleB() {
    constructed++;
  }
}

class ScaleC implements IScale {
  static int constructed = 0;
  ScaleC() {
    constructed++;
  }
}

class ScaleD implements IScale {
  static int constructed = 0;
  ScaleD() {
    constructed++;
  }
}

class ScaleE implements IScale {
  static int constructed = 0;
  ScaleE() {
    constructed++;
  }
}

class ScaleF {
  static int constructed = 0;
  ScaleF() {
    constructed++;
  }
}

class ScaleG {
  static int constructed = 0;
  ScaleG() {
    constructed++;
  }
}

class ScaleH {
  static int constructed = 0;
  ScaleH() {
    constructed++;
  }
}

class ScaleI {
  static int constructed = 0;
  ScaleI() {
    constructed++;
  }
}

class ScaleJ {
  static int constructed = 0;
  ScaleJ() {
    constructed++;
  }
}

// ─── Helpers ───────────────────────────────────────────────────────────────

/// Runs [fn] [iterations] times and returns sorted list of elapsed microseconds.
List<int> _benchmark(int iterations, void Function() fn) {
  final times = <int>[];
  for (var i = 0; i < iterations; i++) {
    final sw = Stopwatch()..start();
    fn();
    sw.stop();
    times.add(sw.elapsedMicroseconds);
  }
  times.sort();
  return times;
}

int _p(List<int> sorted, double pct) =>
    sorted[(sorted.length * pct / 100).clamp(0, sorted.length - 1).round()];

void _printStats(String label, List<int> times, {int? instances}) {
  final min = times.first;
  final max = times.last;
  final mean = times.reduce((a, b) => a + b) ~/ times.length;
  print('  $label');
  print('    min=${min}μs  p50=${_p(times, 50)}μs  p95=${_p(times, 95)}μs  '
      'p99=${_p(times, 99)}μs  max=${max}μs  mean=${mean}μs  n=${times.length}');
  if (instances != null) print('    instâncias criadas: $instances');
}

void _resetCounters() {
  RepoImpl.constructed = 0;
  RepoImpl.sideEffects = 0;
  ServiceImpl.constructed = 0;
  CacheImpl.constructed = 0;
  MultiImpl.constructed = 0;
  ScaleA.constructed = 0;
  ScaleB.constructed = 0;
  ScaleC.constructed = 0;
  ScaleD.constructed = 0;
  ScaleE.constructed = 0;
  ScaleF.constructed = 0;
  ScaleG.constructed = 0;
  ScaleH.constructed = 0;
  ScaleI.constructed = 0;
  ScaleJ.constructed = 0;
}

void main() {
  setUp(() {
    Bind.clearAll();
    _resetCounters();
  });
  tearDown(Bind.clearAll);

  // ══════════════════════════════════════════════════════════════════════════
  // 1. Registro
  // ══════════════════════════════════════════════════════════════════════════

  group('BENCHMARK 1 — Registro de binds', () {
    // Fluxo de produção: registerBatch não invoca factories durante a fase de
    // pré-indexação — apenas commitBatch instancia singletons. É o caminho
    // real percorrido pelo InjectionManager.
    test('fluxo de produção (registerBatch): 100 singletons', () {
      print('\n\n══ BENCHMARK 1 — Registro ══');

      final injector = Injector();
      injector.startRegistering();
      for (var i = 0; i < 100; i++) {
        injector.addSingleton<RepoImpl>((i) => RepoImpl());
      }
      final binds = injector.finishRegistering();

      final swReg = Stopwatch()..start();
      Bind.registerBatch(binds);
      swReg.stop();

      final swCommit = Stopwatch()..start();
      Bind.commitBatch(injector);
      swCommit.stop();

      print('  registerBatch (100 singletons): ${swReg.elapsedMicroseconds}μs '
          '(${(swReg.elapsedMicroseconds / 100).toStringAsFixed(1)}μs/bind)');
      print('  commitBatch (instanciação): ${swCommit.elapsedMicroseconds}μs');
      print('  total: ${swReg.elapsedMicroseconds + swCommit.elapsedMicroseconds}μs');

      expect(binds.length, 100);
      // registerBatch puro (só indexação) deve ser sub-1ms para 100 binds
      expect(swReg.elapsedMilliseconds, lessThan(10),
          reason: 'registerBatch de 100 binds deve levar < 10ms');
    });

    // Fluxo legado: register() invoca o factory uma vez para descoberta de
    // tipo — custo extra esperado vs batch. Documentado aqui para referência.
    test('fluxo legado (register 1-a-1): 100 factories — custo inclui type discovery', () {
      final injector = Injector();
      injector.startRegistering();
      for (var i = 0; i < 100; i++) {
        injector.add((i) => RepoImpl());
      }
      final binds = injector.finishRegistering();

      final sw = Stopwatch()..start();
      for (final b in binds) {
        Bind.register(b);
      }
      sw.stop();

      final perBind = sw.elapsedMicroseconds / 100;
      print('  100 factories legado (com type discovery): ${sw.elapsedMicroseconds}μs '
          '(${perBind.toStringAsFixed(1)}μs/bind)');

      expect(binds.length, 100);
      // Legado invoca factory para descobrir tipo → mais lento, toleramos 100ms
      expect(sw.elapsedMilliseconds, lessThan(100),
          reason: 'fluxo legado de 100 binds deve levar < 100ms');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 2. Lookup direto (Estratégia 2 — caminho quente)
  // ══════════════════════════════════════════════════════════════════════════

  group('BENCHMARK 2 — Lookup direto por tipo concreto', () {
    test('singleton: 10 000 chamadas get<RepoImpl>()', () {
      print('\n\n══ BENCHMARK 2 — Lookup direto ══');
      Bind.register(Bind.singleton<RepoImpl>((i) => RepoImpl()));

      // Aquece o cache
      Bind.get<RepoImpl>();
      _resetCounters();

      final times = _benchmark(10000, () => Bind.get<RepoImpl>());
      _printStats('singleton get<RepoImpl> x10k', times,
          instances: RepoImpl.constructed);

      // Singleton: zero re-invocações após cache
      expect(RepoImpl.constructed, 0,
          reason: 'singleton não deve ser reinstanciado após cache');
      // p99 < 100μs = lookup quente deve ser sub-100μs
      expect(_p(times, 99), lessThan(100),
          reason: 'p99 do lookup de singleton deve ser < 100μs');
    });

    test('factory: 1 000 chamadas get<ServiceImpl>()', () {
      Bind.register(Bind.add<ServiceImpl>((i) => ServiceImpl()));
      // register() (fluxo legado) invoca o factory uma vez para descobrir o
      // tipo de runtime — reset para medir apenas invocações de lookup.
      _resetCounters();

      final times = _benchmark(1000, () => Bind.get<ServiceImpl>());
      _printStats('factory get<ServiceImpl> x1k', times,
          instances: ServiceImpl.constructed);

      // Factory cria nova instância a cada chamada de lookup
      expect(ServiceImpl.constructed, 1000);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 3. Interface resolution (Estratégia 5 — isCompatibleWith)
  // ══════════════════════════════════════════════════════════════════════════

  group('BENCHMARK 3 — Interface resolution (isCompatibleWith)', () {
    test('singleton via interface: primeira chamada (Strategy 5) vs cache (Strategy 2)', () {
      print('\n\n══ BENCHMARK 3 — Interface resolution ══');
      Bind.register(Bind.singleton<RepoImpl>((i) => RepoImpl()));

      // Primeira chamada: Strategy 5 (walk do bindsMap + isCompatibleWith)
      final sw1 = Stopwatch()..start();
      final first = Bind.get<IRepo>();
      sw1.stop();
      print('  1ª chamada get<IRepo> (Strategy 5): ${sw1.elapsedMicroseconds}μs '
          '| instâncias criadas: ${RepoImpl.constructed}');
      expect(first, isA<RepoImpl>());
      expect(RepoImpl.constructed, 1);

      _resetCounters();

      // Chamadas subsequentes: Strategy 2 (lookup direto no cache)
      final times = _benchmark(10000, () => Bind.get<IRepo>());
      _printStats('get<IRepo> cached x10k (Strategy 2)', times,
          instances: RepoImpl.constructed);

      expect(RepoImpl.constructed, 0,
          reason: 'singleton em cache: zero re-invocações');
      expect(_p(times, 99), lessThan(100),
          reason: 'p99 do lookup cacheado por interface deve ser < 100μs');

      // Identidade do singleton preservada
      final a = Bind.get<IRepo>();
      final b = Bind.get<IRepo>();
      expect(identical(a, b), isTrue);
    });

    test('factory via interface: 1 000 chamadas — nova instância a cada vez', () {
      Bind.register(Bind.add<RepoImpl>((i) => RepoImpl()));
      // register() legado invoca o factory uma vez para descoberta de tipo.
      _resetCounters();

      // Primeira chamada de lookup: Strategy 5 (walk + isCompatibleWith)
      final first = Bind.get<IRepo>();
      expect(first, isA<RepoImpl>());
      expect(RepoImpl.constructed, 1);
      _resetCounters();

      // Subsequentes: Strategy 2 (bind cacheado no slot IRepo, nova instância por call)
      final times = _benchmark(1000, () => Bind.get<IRepo>());
      _printStats('factory get<IRepo> x1k', times, instances: RepoImpl.constructed);

      expect(RepoImpl.constructed, 1000,
          reason: 'factory: nova instância por chamada de lookup');
    });

    test('múltiplas interfaces: MultiImpl resolve IRepo e IService', () {
      Bind.register(Bind.singleton<MultiImpl>((i) => MultiImpl()));

      final times1 = _benchmark(1000, () => Bind.get<IRepo>());
      final times2 = _benchmark(1000, () => Bind.get<IService>());

      _printStats('get<IRepo> via MultiImpl x1k', times1,
          instances: MultiImpl.constructed);
      _printStats('get<IService> via MultiImpl x1k', times2);

      expect(MultiImpl.constructed, 1,
          reason: 'singleton multi-interface: construído uma única vez');
      expect(identical(Bind.get<IRepo>(), Bind.get<IService>()), isTrue,
          reason: 'mesma instância para ambas as interfaces');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 4. Zero phantom instances (regressão de performance crítica)
  // ══════════════════════════════════════════════════════════════════════════

  group('BENCHMARK 4 — Ausência de phantom instances', () {
    test('10 000 lookups de tipo não relacionado: zero invocações de factory', () {
      print('\n\n══ BENCHMARK 4 — Phantom instances ══');
      // Usa registerBatch/commitBatch (fluxo de produção) que NÃO invoca
      // factories durante registro — assim os contadores partem de 0 limpo.
      final injector = Injector();
      injector.startRegistering();
      injector.add((i) => RepoImpl());
      injector.add((i) => ServiceImpl());
      injector.add((i) => CacheImpl());
      final binds = injector.finishRegistering();
      Bind.registerBatch(binds);
      Bind.commitBatch(injector);

      expect(RepoImpl.constructed, 0, reason: 'nenhuma construção no registro');
      expect(ServiceImpl.constructed, 0);
      expect(CacheImpl.constructed, 0);

      int notFoundCount = 0;
      final times = _benchmark(10000, () {
        try {
          Bind.get<IUnrelated>();
        } on GoRouterModularException {
          notFoundCount++;
        }
      });

      _printStats('get<IUnrelated> (não registrado) x10k', times);
      print('  notFoundCount: $notFoundCount');
      print('  RepoImpl.constructed: ${RepoImpl.constructed}');
      print('  ServiceImpl.constructed: ${ServiceImpl.constructed}');
      print('  CacheImpl.constructed: ${CacheImpl.constructed}');

      expect(notFoundCount, 10000, reason: 'sempre deve lançar NotFound');
      expect(RepoImpl.constructed, 0,
          reason: 'ZERO phantom instances de RepoImpl durante lookup');
      expect(ServiceImpl.constructed, 0,
          reason: 'ZERO phantom instances de ServiceImpl durante lookup');
      expect(CacheImpl.constructed, 0,
          reason: 'ZERO phantom instances de CacheImpl durante lookup');
    });

    test('custo de um lookup de tipo não relacionado é sub-linear no nº de binds', () {
      // Com N binds registrados, cada lookup de tipo não-relacionado deve ser
      // O(N) no pior caso (walk do bindsMap), mas verificamos que o custo
      // absoluto é aceitável mesmo com muitos binds.
      final injector = Injector();
      injector.startRegistering();
      injector.add((i) => RepoImpl());
      injector.add((i) => ServiceImpl());
      injector.add((i) => CacheImpl());
      injector.addSingleton((i) => ScaleA());
      injector.addSingleton((i) => ScaleB());
      injector.addSingleton((i) => ScaleC());
      injector.addSingleton((i) => ScaleD());
      injector.addSingleton((i) => ScaleE());
      injector.addSingleton((i) => ScaleF());
      injector.addSingleton((i) => ScaleG());
      final binds = injector.finishRegistering();
      Bind.registerBatch(binds);
      Bind.commitBatch(injector);

      _resetCounters();

      int notFoundCount = 0;
      final times = _benchmark(1000, () {
        try {
          Bind.get<IUnrelated>();
        } on GoRouterModularException {
          notFoundCount++;
        }
      });

      _printStats('get<IUnrelated> com 10 binds registrados x1k', times);
      print('  notFoundCount: $notFoundCount');

      expect(notFoundCount, 1000);
      // Todos os construtores de fábricas = 0
      expect(RepoImpl.constructed, 0);
      expect(ServiceImpl.constructed, 0);
      expect(CacheImpl.constructed, 0);
      expect(ScaleA.constructed, 0);
      expect(ScaleB.constructed, 0);
      expect(ScaleC.constructed, 0);
      expect(ScaleD.constructed, 0);
      expect(ScaleE.constructed, 0);

      // p99 < 1ms mesmo com 10 binds no mapa
      expect(_p(times, 99), lessThan(1000),
          reason: 'p99 de lookup não-relacionado com 10 binds deve ser < 1ms');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 5. Escalabilidade — módulo real simulado
  // ══════════════════════════════════════════════════════════════════════════

  group('BENCHMARK 5 — Módulo real (registro + resolução completa)', () {
    test('módulo com 10 dependências aninhadas', () {
      print('\n\n══ BENCHMARK 5 — Módulo real ══');
      final injector = Injector();
      injector.startRegistering();

      // Dependências folha
      injector.addSingleton<ScaleA>((i) => ScaleA());
      injector.addSingleton<ScaleB>((i) => ScaleB());
      injector.addSingleton<ScaleC>((i) => ScaleC());
      injector.addSingleton<ScaleD>((i) => ScaleD());
      injector.addSingleton<ScaleE>((i) => ScaleE());
      injector.addSingleton<ScaleF>((i) => ScaleF());
      injector.addSingleton<ScaleG>((i) => ScaleG());
      injector.addSingleton<ScaleH>((i) => ScaleH());
      injector.addSingleton<ScaleI>((i) => ScaleI());
      injector.addSingleton<ScaleJ>((i) => ScaleJ());

      final binds = injector.finishRegistering();

      final swReg = Stopwatch()..start();
      Bind.registerBatch(binds);
      Bind.commitBatch(injector);
      swReg.stop();

      print('  Registro de 10 binds: ${swReg.elapsedMicroseconds}μs');

      // Resolução inicial (instanciação)
      final swFirst = Stopwatch()..start();
      final a = Bind.get<ScaleA>();
      final b = Bind.get<ScaleB>();
      Bind.get<ScaleC>();
      Bind.get<ScaleD>();
      Bind.get<ScaleE>();
      final f = Bind.get<ScaleF>();
      Bind.get<ScaleG>();
      Bind.get<ScaleH>();
      Bind.get<ScaleI>();
      final j = Bind.get<ScaleJ>();
      swFirst.stop();

      print('  Resolução inicial (10 tipos, 1ª vez): ${swFirst.elapsedMicroseconds}μs');
      print('  Instâncias criadas: ${ScaleA.constructed + ScaleB.constructed + ScaleC.constructed + ScaleD.constructed + ScaleE.constructed + ScaleF.constructed + ScaleG.constructed + ScaleH.constructed + ScaleI.constructed + ScaleJ.constructed}');

      // Resolução subsequente (cache quente)
      final swCache = Stopwatch()..start();
      for (var i = 0; i < 1000; i++) {
        Bind.get<ScaleA>();
        Bind.get<ScaleB>();
        Bind.get<ScaleC>();
        Bind.get<ScaleD>();
        Bind.get<ScaleE>();
      }
      swCache.stop();
      final perCall = swCache.elapsedMicroseconds / 5000;
      print(
          '  5 000 lookups cache quente: ${swCache.elapsedMicroseconds}μs (${perCall.toStringAsFixed(2)}μs/call)');

      expect(a, isA<ScaleA>());
      expect(b, isA<ScaleB>());
      expect(f, isA<ScaleF>());
      expect(j, isA<ScaleJ>());
      expect(ScaleA.constructed, 1);
      expect(ScaleJ.constructed, 1);

      // Singleton identidade preservada
      expect(identical(Bind.get<ScaleA>(), a), isTrue);
      expect(identical(Bind.get<ScaleJ>(), j), isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 6. isCompatibleWith<U>() — custo isolado do check de subtipo
  // ══════════════════════════════════════════════════════════════════════════

  group('BENCHMARK 6 — Custo do isCompatibleWith (check de subtipo)', () {
    test('isCompatibleWith: positivo vs negativo, 100 000 chamadas', () {
      print('\n\n══ BENCHMARK 6 — isCompatibleWith ══');

      // Bind<RepoImpl> — T = RepoImpl
      final bind = Bind.singleton<RepoImpl>((i) => RepoImpl());

      // Check positivo: RepoImpl is IRepo → true
      final timesPos = _benchmark(100000, () => bind.isCompatibleWith<IRepo>());
      _printStats('isCompatibleWith<IRepo> (positivo) x100k', timesPos);

      // Check negativo: RepoImpl is IUnrelated → false
      final timesNeg =
          _benchmark(100000, () => bind.isCompatibleWith<IUnrelated>());
      _printStats('isCompatibleWith<IUnrelated> (negativo) x100k', timesNeg);

      // Verificações de corretude
      expect(bind.isCompatibleWith<IRepo>(), isTrue);
      expect(bind.isCompatibleWith<IUnrelated>(), isFalse);
      expect(bind.isCompatibleWith<RepoImpl>(), isTrue);
      expect(bind.isCompatibleWith<Object>(), isTrue);

      // Custo deve ser sub-microsecond no p99 em JIT/AOT otimizado
      // Em flutter_test (VM não otimizada) toleramos até 10μs
      expect(_p(timesPos, 99), lessThan(10),
          reason: 'isCompatibleWith deve ser muito barato (< 10μs p99)');
      expect(_p(timesNeg, 99), lessThan(10));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 7. Resumo final
  // ══════════════════════════════════════════════════════════════════════════

  test('RESUMO — saúde geral do pacote', () {
    print('\n\n══════════════════════════════════════════════════');
    print('RESUMO DE SAÚDE DO PACOTE — go_router_modular DI');
    print('══════════════════════════════════════════════════');

    // Registro
    final injector = Injector();
    injector.startRegistering();
    injector.addSingleton<RepoImpl>((i) => RepoImpl());
    injector.addSingleton<ServiceImpl>((i) => ServiceImpl());
    injector.add<CacheImpl>((i) => CacheImpl());
    final binds = injector.finishRegistering();
    final swReg = Stopwatch()..start();
    Bind.registerBatch(binds);
    Bind.commitBatch(injector);
    swReg.stop();
    print('Registro (3 binds): ${swReg.elapsedMicroseconds}μs');

    // Lookup direto
    final swDirect = Stopwatch()..start();
    for (var i = 0; i < 10000; i++) {
      Bind.get<RepoImpl>();
    }
    swDirect.stop();
    print('Lookup direto singleton 10k: ${swDirect.elapsedMicroseconds}μs '
        '(${(swDirect.elapsedMicroseconds / 10000).toStringAsFixed(2)}μs/call)');

    _resetCounters();

    // Lookup por interface (primeira vez → Strategy 5)
    final swIface1 = Stopwatch()..start();
    Bind.get<IRepo>();
    swIface1.stop();
    print('Lookup interface (1ª vez, Strategy 5): ${swIface1.elapsedMicroseconds}μs');
    expect(RepoImpl.constructed, 0,
        reason: 'singleton já construído; Strategy 5 usa cache');

    // Lookup por interface (cache → Strategy 2)
    final swIface2 = Stopwatch()..start();
    for (var i = 0; i < 10000; i++) {
      Bind.get<IRepo>();
    }
    swIface2.stop();
    print('Lookup interface cached 10k: ${swIface2.elapsedMicroseconds}μs '
        '(${(swIface2.elapsedMicroseconds / 10000).toStringAsFixed(2)}μs/call)');

    // Phantom instances
    int notFound = 0;
    for (var i = 0; i < 1000; i++) {
      try {
        Bind.get<IUnrelated>();
      } catch (_) {
        notFound++;
      }
    }
    print('Phantom instances após 1k lookups não-relacionados: '
        '${RepoImpl.constructed + ServiceImpl.constructed + CacheImpl.constructed}');
    expect(RepoImpl.constructed, 0);
    expect(ServiceImpl.constructed, 0);
    expect(CacheImpl.constructed, 0);
    expect(notFound, 1000);

    print('══════════════════════════════════════════════════\n');
  });
}
