import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/src/core/bind.dart';
import 'package:go_router_modular/src/di/injector.dart';

// 50 classes diferentes para teste de performance
class ServiceA {}

class ServiceB {}

class ServiceC {}

class ServiceD {}

class ServiceE {}

class ServiceF {}

class ServiceG {}

class ServiceH {}

class ServiceI {}

class ServiceJ {}

class ServiceK {}

class ServiceL {}

class ServiceM {}

class ServiceN {}

class ServiceO {}

class ServiceP {}

class ServiceQ {}

class ServiceR {}

class ServiceS {}

class ServiceT {}

class ServiceU {}

class ServiceV {}

class ServiceW {}

class ServiceX {}

class ServiceY {}

class ServiceZ {}

class ServiceAA {}

class ServiceAB {}

class ServiceAC {}

class ServiceAD {}

class ServiceAE {}

class ServiceAF {}

class ServiceAG {}

class ServiceAH {}

class ServiceAI {}

class ServiceAJ {}

class ServiceAK {}

class ServiceAL {}

class ServiceAM {}

class ServiceAN {}

class ServiceAO {}

class ServiceAP {}

class ServiceAQ {}

class ServiceAR {}

class ServiceAS {}

class ServiceAT {}

class ServiceAU {}

class ServiceAV {}

class ServiceAW {}

class ServiceAX {}

// Classes com dependências complexas e desorganizadas
class ComplexService1 {
  final ServiceA a;
  final ServiceB b;
  final ServiceC c;
  ComplexService1(this.a, this.b, this.c);
}

class ComplexService2 {
  final ServiceD d;
  final ServiceE e;
  final ComplexService1 complex1;
  ComplexService2(this.d, this.e, this.complex1);
}

class ComplexService3 {
  final ServiceF f;
  final ServiceG g;
  final ServiceH h;
  final ComplexService2 complex2;
  ComplexService3(this.f, this.g, this.h, this.complex2);
}

class ComplexService4 {
  final ServiceI i;
  final ServiceJ j;
  final ServiceK k;
  final ServiceL l;
  final ComplexService3 complex3;
  ComplexService4(this.i, this.j, this.k, this.l, this.complex3);
}

class ComplexService5 {
  final ServiceM m;
  final ServiceN n;
  final ServiceO o;
  final ServiceP p;
  final ServiceQ q;
  final ComplexService4 complex4;
  ComplexService5(this.m, this.n, this.o, this.p, this.q, this.complex4);
}

// Classes intermediárias com 3 ou mais dependências
class MidLevelService1 {
  final ServiceAA aa;
  final ServiceAB ab;
  final ServiceAC ac;
  final ServiceAD ad;
  MidLevelService1(this.aa, this.ab, this.ac, this.ad);
}

class MidLevelService2 {
  final ServiceAE ae;
  final ServiceAF af;
  final ServiceAG ag;
  final MidLevelService1 mid1;
  MidLevelService2(this.ae, this.af, this.ag, this.mid1);
}

class MidLevelService3 {
  final ServiceAH ah;
  final ServiceAI ai;
  final ServiceAJ aj;
  final ServiceAK ak;
  final ServiceAL al;
  final MidLevelService2 mid2;
  MidLevelService3(this.ah, this.ai, this.aj, this.ak, this.al, this.mid2);
}

class MidLevelService4 {
  final ServiceAM am;
  final ServiceAN an;
  final ServiceAO ao;
  final ServiceAP ap;
  final ServiceAQ aq;
  final ServiceAR ar;
  final MidLevelService3 mid3;
  MidLevelService4(this.am, this.an, this.ao, this.ap, this.aq, this.ar, this.mid3);
}

class MidLevelService5 {
  final ServiceAS as_;
  final ServiceAT at;
  final ServiceAU au;
  final ServiceAV av;
  final ServiceAW aw;
  final ServiceAX ax;
  final MidLevelService4 mid4;
  MidLevelService5(this.as_, this.at, this.au, this.av, this.aw, this.ax, this.mid4);
}

// Classes que dependem de múltiplas classes de diferentes níveis
class CrossDependencyService1 {
  final ServiceA a;
  final ServiceZ z;
  final ServiceM m;
  final ComplexService1 complex1;
  final MidLevelService1 mid1;
  CrossDependencyService1(this.a, this.z, this.m, this.complex1, this.mid1);
}

class CrossDependencyService2 {
  final ServiceB b;
  final ServiceY y;
  final ServiceN n;
  final ServiceAA aa;
  final ComplexService2 complex2;
  final MidLevelService2 mid2;
  CrossDependencyService2(this.b, this.y, this.n, this.aa, this.complex2, this.mid2);
}

class CrossDependencyService3 {
  final ServiceC c;
  final ServiceX x;
  final ServiceO o;
  final ServiceAB ab;
  final ComplexService3 complex3;
  final MidLevelService3 mid3;
  final CrossDependencyService1 cross1;
  CrossDependencyService3(this.c, this.x, this.o, this.ab, this.complex3, this.mid3, this.cross1);
}

class UltimateService {
  final ComplexService5 complex5;
  final MidLevelService5 mid5;
  final CrossDependencyService3 cross3;
  final ServiceA a;
  final ServiceZ z;
  final ServiceAX ax;
  UltimateService(this.complex5, this.mid5, this.cross3, this.a, this.z, this.ax);
}

void main() {
  group('Type Inference Performance Tests', () {
    setUp(() {
      Bind.clearAll();
    });

    tearDown(() {
      Bind.clearAll();
    });

    test('Performance: 50 binds desorganizados COM tipagem explícita', () {
      final injector = Injector();
      injector.startRegistering();

      // Registra 50 binds de forma totalmente desorganizada COM tipagem explícita
      // Ordem aleatória proposital para simular código real
      injector.addSingleton<ServiceZ>((i) => ServiceZ());
      injector.addSingleton<ServiceM>((i) => ServiceM());
      injector.addSingleton<ServiceA>((i) => ServiceA());
      injector.addSingleton<ServiceY>((i) => ServiceY());
      injector.addSingleton<ServiceB>((i) => ServiceB());
      injector.addSingleton<ServiceX>((i) => ServiceX());
      injector.addSingleton<ServiceC>((i) => ServiceC());
      injector.addSingleton<ServiceW>((i) => ServiceW());
      injector.addSingleton<ServiceD>((i) => ServiceD());
      injector.addSingleton<ServiceV>((i) => ServiceV());
      injector.addSingleton<ServiceE>((i) => ServiceE());
      injector.addSingleton<ServiceU>((i) => ServiceU());
      injector.addSingleton<ServiceF>((i) => ServiceF());
      injector.addSingleton<ServiceT>((i) => ServiceT());
      injector.addSingleton<ServiceG>((i) => ServiceG());
      injector.addSingleton<ServiceS>((i) => ServiceS());
      injector.addSingleton<ServiceH>((i) => ServiceH());
      injector.addSingleton<ServiceR>((i) => ServiceR());
      injector.addSingleton<ServiceI>((i) => ServiceI());
      injector.addSingleton<ServiceQ>((i) => ServiceQ());
      injector.addSingleton<ServiceJ>((i) => ServiceJ());
      injector.addSingleton<ServiceP>((i) => ServiceP());
      injector.addSingleton<ServiceK>((i) => ServiceK());
      injector.addSingleton<ServiceO>((i) => ServiceO());
      injector.addSingleton<ServiceL>((i) => ServiceL());
      injector.addSingleton<ServiceN>((i) => ServiceN());
      injector.addSingleton<ServiceAA>((i) => ServiceAA());
      injector.addSingleton<ServiceAB>((i) => ServiceAB());
      injector.addSingleton<ServiceAC>((i) => ServiceAC());
      injector.addSingleton<ServiceAD>((i) => ServiceAD());
      injector.addSingleton<ServiceAE>((i) => ServiceAE());
      injector.addSingleton<ServiceAF>((i) => ServiceAF());
      injector.addSingleton<ServiceAG>((i) => ServiceAG());
      injector.addSingleton<ServiceAH>((i) => ServiceAH());
      injector.addSingleton<ServiceAI>((i) => ServiceAI());
      injector.addSingleton<ServiceAJ>((i) => ServiceAJ());
      injector.addSingleton<ServiceAK>((i) => ServiceAK());
      injector.addSingleton<ServiceAL>((i) => ServiceAL());
      injector.addSingleton<ServiceAM>((i) => ServiceAM());
      injector.addSingleton<ServiceAN>((i) => ServiceAN());
      injector.addSingleton<ServiceAO>((i) => ServiceAO());
      injector.addSingleton<ServiceAP>((i) => ServiceAP());
      injector.addSingleton<ServiceAQ>((i) => ServiceAQ());
      injector.addSingleton<ServiceAR>((i) => ServiceAR());
      injector.addSingleton<ServiceAS>((i) => ServiceAS());
      injector.addSingleton<ServiceAT>((i) => ServiceAT());
      injector.addSingleton<ServiceAU>((i) => ServiceAU());
      injector.addSingleton<ServiceAV>((i) => ServiceAV());
      injector.addSingleton<ServiceAW>((i) => ServiceAW());
      injector.addSingleton<ServiceAX>((i) => ServiceAX());

      // Registra binds complexos com dependências (também desorganizados)
      injector.addSingleton<ComplexService1>((i) => ComplexService1(i.get<ServiceA>(), i.get<ServiceB>(), i.get<ServiceC>()));
      injector.addSingleton<ComplexService3>((i) => ComplexService3(i.get<ServiceF>(), i.get<ServiceG>(), i.get<ServiceH>(), i.get<ComplexService2>()));
      injector.addSingleton<ComplexService2>((i) => ComplexService2(i.get<ServiceD>(), i.get<ServiceE>(), i.get<ComplexService1>()));
      injector.addSingleton<ComplexService5>((i) => ComplexService5(i.get<ServiceM>(), i.get<ServiceN>(), i.get<ServiceO>(), i.get<ServiceP>(), i.get<ServiceQ>(), i.get<ComplexService4>()));
      injector.addSingleton<ComplexService4>((i) => ComplexService4(i.get<ServiceI>(), i.get<ServiceJ>(), i.get<ServiceK>(), i.get<ServiceL>(), i.get<ComplexService3>()));

      // Registra classes intermediárias com múltiplas dependências (desorganizadas)
      injector.addSingleton<MidLevelService2>((i) => MidLevelService2(i.get<ServiceAE>(), i.get<ServiceAF>(), i.get<ServiceAG>(), i.get<MidLevelService1>()));
      injector.addSingleton<MidLevelService1>((i) => MidLevelService1(i.get<ServiceAA>(), i.get<ServiceAB>(), i.get<ServiceAC>(), i.get<ServiceAD>()));
      injector.addSingleton<MidLevelService4>((i) => MidLevelService4(i.get<ServiceAM>(), i.get<ServiceAN>(), i.get<ServiceAO>(), i.get<ServiceAP>(), i.get<ServiceAQ>(), i.get<ServiceAR>(), i.get<MidLevelService3>()));
      injector.addSingleton<MidLevelService3>((i) => MidLevelService3(i.get<ServiceAH>(), i.get<ServiceAI>(), i.get<ServiceAJ>(), i.get<ServiceAK>(), i.get<ServiceAL>(), i.get<MidLevelService2>()));
      injector.addSingleton<MidLevelService5>((i) => MidLevelService5(i.get<ServiceAS>(), i.get<ServiceAT>(), i.get<ServiceAU>(), i.get<ServiceAV>(), i.get<ServiceAW>(), i.get<ServiceAX>(), i.get<MidLevelService4>()));

      // Registra classes com dependências cruzadas (desorganizadas)
      injector.addSingleton<CrossDependencyService2>((i) => CrossDependencyService2(i.get<ServiceB>(), i.get<ServiceY>(), i.get<ServiceN>(), i.get<ServiceAA>(), i.get<ComplexService2>(), i.get<MidLevelService2>()));
      injector.addSingleton<CrossDependencyService1>((i) => CrossDependencyService1(i.get<ServiceA>(), i.get<ServiceZ>(), i.get<ServiceM>(), i.get<ComplexService1>(), i.get<MidLevelService1>()));
      injector.addSingleton<CrossDependencyService3>((i) => CrossDependencyService3(i.get<ServiceC>(), i.get<ServiceX>(), i.get<ServiceO>(), i.get<ServiceAB>(), i.get<ComplexService3>(), i.get<MidLevelService3>(), i.get<CrossDependencyService1>()));
      injector.addSingleton<UltimateService>((i) => UltimateService(i.get<ComplexService5>(), i.get<MidLevelService5>(), i.get<CrossDependencyService3>(), i.get<ServiceA>(), i.get<ServiceZ>(), i.get<ServiceAX>()));

      final binds = injector.finishRegistering();

      // Mede o tempo de registro COM tipagem explícita
      final stopwatch = Stopwatch()..start();

      for (final bind in binds) {
        // Como os binds foram criados com tipagem explícita, registra usando registerTyped
        // Mas como não temos o tipo genérico aqui, vamos usar register normal
        Bind.register(bind);
      }

      stopwatch.stop();
      final registrationTime = stopwatch.elapsedMicroseconds;

      // Mede o tempo de resolução de todas as dependências
      stopwatch.reset();
      stopwatch.start();

      // Resolve todas as dependências (simula uso real)
      final complex5 = Bind.get<ComplexService5>();
      final complex4 = Bind.get<ComplexService4>();
      final complex3 = Bind.get<ComplexService3>();
      final complex2 = Bind.get<ComplexService2>();
      final complex1 = Bind.get<ComplexService1>();

      // Resolve classes intermediárias
      final mid5 = Bind.get<MidLevelService5>();
      final mid4 = Bind.get<MidLevelService4>();
      final mid3 = Bind.get<MidLevelService3>();
      final mid2 = Bind.get<MidLevelService2>();
      final mid1 = Bind.get<MidLevelService1>();

      // Resolve classes com dependências cruzadas
      final cross3 = Bind.get<CrossDependencyService3>();
      final cross2 = Bind.get<CrossDependencyService2>();
      final cross1 = Bind.get<CrossDependencyService1>();

      // Resolve serviço final
      final ultimate = Bind.get<UltimateService>();

      // Resolve serviços individuais
      Bind.get<ServiceA>();
      Bind.get<ServiceB>();
      Bind.get<ServiceC>();
      Bind.get<ServiceZ>();
      Bind.get<ServiceAX>();

      stopwatch.stop();
      final resolutionTime = stopwatch.elapsedMicroseconds;

      print('\n📊 [COM TIPAGEM EXPLÍCITA]');
      print('⏱️  Tempo de registro: ${registrationTime}μs (${(registrationTime / 1000).toStringAsFixed(2)}ms)');
      print('⏱️  Tempo de resolução: ${resolutionTime}μs (${(resolutionTime / 1000).toStringAsFixed(2)}ms)');
      print('⏱️  Tempo total: ${registrationTime + resolutionTime}μs (${((registrationTime + resolutionTime) / 1000).toStringAsFixed(2)}ms)');
      print('✅ Total de binds: ${binds.length}');
      print('✅ ComplexService5 resolvido: ${complex5.runtimeType}');
      print('✅ ComplexService4 resolvido: ${complex4.runtimeType}');
      print('✅ MidLevelService5 resolvido: ${mid5.runtimeType}');
      print('✅ CrossDependencyService3 resolvido: ${cross3.runtimeType}');
      print('✅ UltimateService resolvido: ${ultimate.runtimeType}');

      // Verifica que tudo foi resolvido corretamente
      expect(complex5, isA<ComplexService5>());
      expect(complex4, isA<ComplexService4>());
      expect(complex3, isA<ComplexService3>());
      expect(complex2, isA<ComplexService2>());
      expect(complex1, isA<ComplexService1>());
      expect(mid5, isA<MidLevelService5>());
      expect(mid4, isA<MidLevelService4>());
      expect(mid3, isA<MidLevelService3>());
      expect(mid2, isA<MidLevelService2>());
      expect(mid1, isA<MidLevelService1>());
      expect(cross3, isA<CrossDependencyService3>());
      expect(cross2, isA<CrossDependencyService2>());
      expect(cross1, isA<CrossDependencyService1>());
      expect(ultimate, isA<UltimateService>());
    });

    test('Performance: 50 binds desorganizados SEM tipagem explícita (auto-resolve)', () {
      final injector = Injector();
      injector.startRegistering();

      // Registra 50 binds de forma totalmente desorganizada SEM tipagem explícita
      // O sistema deve inferir os tipos automaticamente
      injector.addSingleton((i) => ServiceZ());
      injector.addSingleton((i) => ServiceM());
      injector.addSingleton((i) => ServiceA());
      injector.addSingleton((i) => ServiceY());
      injector.addSingleton((i) => ServiceB());
      injector.addSingleton((i) => ServiceX());
      injector.addSingleton((i) => ServiceC());
      injector.addSingleton((i) => ServiceW());
      injector.addSingleton((i) => ServiceD());
      injector.addSingleton((i) => ServiceV());
      injector.addSingleton((i) => ServiceE());
      injector.addSingleton((i) => ServiceU());
      injector.addSingleton((i) => ServiceF());
      injector.addSingleton((i) => ServiceT());
      injector.addSingleton((i) => ServiceG());
      injector.addSingleton((i) => ServiceS());
      injector.addSingleton((i) => ServiceH());
      injector.addSingleton((i) => ServiceR());
      injector.addSingleton((i) => ServiceI());
      injector.addSingleton((i) => ServiceQ());
      injector.addSingleton((i) => ServiceJ());
      injector.addSingleton((i) => ServiceP());
      injector.addSingleton((i) => ServiceK());
      injector.addSingleton((i) => ServiceO());
      injector.addSingleton((i) => ServiceL());
      injector.addSingleton((i) => ServiceN());
      injector.addSingleton((i) => ServiceAA());
      injector.addSingleton((i) => ServiceAB());
      injector.addSingleton((i) => ServiceAC());
      injector.addSingleton((i) => ServiceAD());
      injector.addSingleton((i) => ServiceAE());
      injector.addSingleton((i) => ServiceAF());
      injector.addSingleton((i) => ServiceAG());
      injector.addSingleton((i) => ServiceAH());
      injector.addSingleton((i) => ServiceAI());
      injector.addSingleton((i) => ServiceAJ());
      injector.addSingleton((i) => ServiceAK());
      injector.addSingleton((i) => ServiceAL());
      injector.addSingleton((i) => ServiceAM());
      injector.addSingleton((i) => ServiceAN());
      injector.addSingleton((i) => ServiceAO());
      injector.addSingleton((i) => ServiceAP());
      injector.addSingleton((i) => ServiceAQ());
      injector.addSingleton((i) => ServiceAR());
      injector.addSingleton((i) => ServiceAS());
      injector.addSingleton((i) => ServiceAT());
      injector.addSingleton((i) => ServiceAU());
      injector.addSingleton((i) => ServiceAV());
      injector.addSingleton((i) => ServiceAW());
      injector.addSingleton((i) => ServiceAX());

      // Registra binds complexos com dependências (também desorganizados)
      injector.addSingleton((i) => ComplexService1(i.get<ServiceA>(), i.get<ServiceB>(), i.get<ServiceC>()));
      injector.addSingleton((i) => ComplexService3(i.get<ServiceF>(), i.get<ServiceG>(), i.get<ServiceH>(), i.get<ComplexService2>()));
      injector.addSingleton((i) => ComplexService2(i.get<ServiceD>(), i.get<ServiceE>(), i.get<ComplexService1>()));
      injector.addSingleton((i) => ComplexService5(i.get<ServiceM>(), i.get<ServiceN>(), i.get<ServiceO>(), i.get<ServiceP>(), i.get<ServiceQ>(), i.get<ComplexService4>()));
      injector.addSingleton((i) => ComplexService4(i.get<ServiceI>(), i.get<ServiceJ>(), i.get<ServiceK>(), i.get<ServiceL>(), i.get<ComplexService3>()));

      // Registra classes intermediárias com múltiplas dependências (desorganizadas)
      injector.addSingleton((i) => MidLevelService2(i.get<ServiceAE>(), i.get<ServiceAF>(), i.get<ServiceAG>(), i.get<MidLevelService1>()));
      injector.addSingleton((i) => MidLevelService1(i.get<ServiceAA>(), i.get<ServiceAB>(), i.get<ServiceAC>(), i.get<ServiceAD>()));
      injector.addSingleton((i) => MidLevelService4(i.get<ServiceAM>(), i.get<ServiceAN>(), i.get<ServiceAO>(), i.get<ServiceAP>(), i.get<ServiceAQ>(), i.get<ServiceAR>(), i.get<MidLevelService3>()));
      injector.addSingleton((i) => MidLevelService3(i.get<ServiceAH>(), i.get<ServiceAI>(), i.get<ServiceAJ>(), i.get<ServiceAK>(), i.get<ServiceAL>(), i.get<MidLevelService2>()));
      injector.addSingleton((i) => MidLevelService5(i.get<ServiceAS>(), i.get<ServiceAT>(), i.get<ServiceAU>(), i.get<ServiceAV>(), i.get<ServiceAW>(), i.get<ServiceAX>(), i.get<MidLevelService4>()));

      // Registra classes com dependências cruzadas (desorganizadas)
      injector.addSingleton((i) => CrossDependencyService2(i.get<ServiceB>(), i.get<ServiceY>(), i.get<ServiceN>(), i.get<ServiceAA>(), i.get<ComplexService2>(), i.get<MidLevelService2>()));
      injector.addSingleton((i) => CrossDependencyService1(i.get<ServiceA>(), i.get<ServiceZ>(), i.get<ServiceM>(), i.get<ComplexService1>(), i.get<MidLevelService1>()));
      injector.addSingleton((i) => CrossDependencyService3(i.get<ServiceC>(), i.get<ServiceX>(), i.get<ServiceO>(), i.get<ServiceAB>(), i.get<ComplexService3>(), i.get<MidLevelService3>(), i.get<CrossDependencyService1>()));
      injector.addSingleton((i) => UltimateService(i.get<ComplexService5>(), i.get<MidLevelService5>(), i.get<CrossDependencyService3>(), i.get<ServiceA>(), i.get<ServiceZ>(), i.get<ServiceAX>()));

      final binds = injector.finishRegistering();

      // Mede o tempo de registro SEM tipagem explícita (auto-resolve)
      final stopwatch = Stopwatch()..start();

      for (final bind in binds) {
        // Sem tipagem explícita, o sistema deve inferir automaticamente
        Bind.register(bind);
      }

      stopwatch.stop();
      final registrationTime = stopwatch.elapsedMicroseconds;

      // Mede o tempo de resolução de todas as dependências
      stopwatch.reset();
      stopwatch.start();

      // Resolve todas as dependências (simula uso real)
      final complex5 = Bind.get<ComplexService5>();
      final complex4 = Bind.get<ComplexService4>();
      final complex3 = Bind.get<ComplexService3>();
      final complex2 = Bind.get<ComplexService2>();
      final complex1 = Bind.get<ComplexService1>();

      // Resolve classes intermediárias
      final mid5 = Bind.get<MidLevelService5>();
      final mid4 = Bind.get<MidLevelService4>();
      final mid3 = Bind.get<MidLevelService3>();
      final mid2 = Bind.get<MidLevelService2>();
      final mid1 = Bind.get<MidLevelService1>();

      // Resolve classes com dependências cruzadas
      final cross3 = Bind.get<CrossDependencyService3>();
      final cross2 = Bind.get<CrossDependencyService2>();
      final cross1 = Bind.get<CrossDependencyService1>();

      // Resolve serviço final
      final ultimate = Bind.get<UltimateService>();

      // Resolve serviços individuais
      Bind.get<ServiceA>();
      Bind.get<ServiceB>();
      Bind.get<ServiceC>();
      Bind.get<ServiceZ>();
      Bind.get<ServiceAX>();

      stopwatch.stop();
      final resolutionTime = stopwatch.elapsedMicroseconds;

      print('\n📊 [SEM TIPAGEM EXPLÍCITA - AUTO-RESOLVE]');
      print('⏱️  Tempo de registro: ${registrationTime}μs (${(registrationTime / 1000).toStringAsFixed(2)}ms)');
      print('⏱️  Tempo de resolução: ${resolutionTime}μs (${(resolutionTime / 1000).toStringAsFixed(2)}ms)');
      print('⏱️  Tempo total: ${registrationTime + resolutionTime}μs (${((registrationTime + resolutionTime) / 1000).toStringAsFixed(2)}ms)');
      print('✅ Total de binds: ${binds.length}');
      print('✅ ComplexService5 resolvido: ${complex5.runtimeType}');
      print('✅ ComplexService4 resolvido: ${complex4.runtimeType}');
      print('✅ MidLevelService5 resolvido: ${mid5.runtimeType}');
      print('✅ CrossDependencyService3 resolvido: ${cross3.runtimeType}');
      print('✅ UltimateService resolvido: ${ultimate.runtimeType}');

      // Verifica que tudo foi resolvido corretamente
      expect(complex5, isA<ComplexService5>());
      expect(complex4, isA<ComplexService4>());
      expect(complex3, isA<ComplexService3>());
      expect(complex2, isA<ComplexService2>());
      expect(complex1, isA<ComplexService1>());
      expect(mid5, isA<MidLevelService5>());
      expect(mid4, isA<MidLevelService4>());
      expect(mid3, isA<MidLevelService3>());
      expect(mid2, isA<MidLevelService2>());
      expect(mid1, isA<MidLevelService1>());
      expect(cross3, isA<CrossDependencyService3>());
      expect(cross2, isA<CrossDependencyService2>());
      expect(cross1, isA<CrossDependencyService1>());
      expect(ultimate, isA<UltimateService>());
    });

    test('Performance: Comparação lado a lado COM e SEM tipagem (50 classes diferentes)', () {
      // Lista de todas as 50 classes
      final classes = [
        ServiceA,
        ServiceB,
        ServiceC,
        ServiceD,
        ServiceE,
        ServiceF,
        ServiceG,
        ServiceH,
        ServiceI,
        ServiceJ,
        ServiceK,
        ServiceL,
        ServiceM,
        ServiceN,
        ServiceO,
        ServiceP,
        ServiceQ,
        ServiceR,
        ServiceS,
        ServiceT,
        ServiceU,
        ServiceV,
        ServiceW,
        ServiceX,
        ServiceY,
        ServiceZ,
        ServiceAA,
        ServiceAB,
        ServiceAC,
        ServiceAD,
        ServiceAE,
        ServiceAF,
        ServiceAG,
        ServiceAH,
        ServiceAI,
        ServiceAJ,
        ServiceAK,
        ServiceAL,
        ServiceAM,
        ServiceAN,
        ServiceAO,
        ServiceAP,
        ServiceAQ,
        ServiceAR,
        ServiceAS,
        ServiceAT,
        ServiceAU,
        ServiceAV,
        ServiceAW,
        ServiceAX,
      ];

      // Teste COM tipagem explícita
      Bind.clearAll();
      final injector1 = Injector();
      injector1.startRegistering();

      // Registra 50 classes diferentes COM tipagem explícita em ordem aleatória
      final order1 = [26, 15, 0, 24, 1, 23, 2, 22, 3, 21, 4, 20, 5, 19, 6, 18, 7, 17, 8, 16, 9, 25, 10, 14, 11, 13, 12, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49];
      for (final idx in order1) {
        switch (idx) {
          case 0:
            injector1.addSingleton<ServiceA>((i) => ServiceA());
            break;
          case 1:
            injector1.addSingleton<ServiceB>((i) => ServiceB());
            break;
          case 2:
            injector1.addSingleton<ServiceC>((i) => ServiceC());
            break;
          case 3:
            injector1.addSingleton<ServiceD>((i) => ServiceD());
            break;
          case 4:
            injector1.addSingleton<ServiceE>((i) => ServiceE());
            break;
          case 5:
            injector1.addSingleton<ServiceF>((i) => ServiceF());
            break;
          case 6:
            injector1.addSingleton<ServiceG>((i) => ServiceG());
            break;
          case 7:
            injector1.addSingleton<ServiceH>((i) => ServiceH());
            break;
          case 8:
            injector1.addSingleton<ServiceI>((i) => ServiceI());
            break;
          case 9:
            injector1.addSingleton<ServiceJ>((i) => ServiceJ());
            break;
          case 10:
            injector1.addSingleton<ServiceK>((i) => ServiceK());
            break;
          case 11:
            injector1.addSingleton<ServiceL>((i) => ServiceL());
            break;
          case 12:
            injector1.addSingleton<ServiceM>((i) => ServiceM());
            break;
          case 13:
            injector1.addSingleton<ServiceN>((i) => ServiceN());
            break;
          case 14:
            injector1.addSingleton<ServiceO>((i) => ServiceO());
            break;
          case 15:
            injector1.addSingleton<ServiceP>((i) => ServiceP());
            break;
          case 16:
            injector1.addSingleton<ServiceQ>((i) => ServiceQ());
            break;
          case 17:
            injector1.addSingleton<ServiceR>((i) => ServiceR());
            break;
          case 18:
            injector1.addSingleton<ServiceS>((i) => ServiceS());
            break;
          case 19:
            injector1.addSingleton<ServiceT>((i) => ServiceT());
            break;
          case 20:
            injector1.addSingleton<ServiceU>((i) => ServiceU());
            break;
          case 21:
            injector1.addSingleton<ServiceV>((i) => ServiceV());
            break;
          case 22:
            injector1.addSingleton<ServiceW>((i) => ServiceW());
            break;
          case 23:
            injector1.addSingleton<ServiceX>((i) => ServiceX());
            break;
          case 24:
            injector1.addSingleton<ServiceY>((i) => ServiceY());
            break;
          case 25:
            injector1.addSingleton<ServiceZ>((i) => ServiceZ());
            break;
          case 26:
            injector1.addSingleton<ServiceAA>((i) => ServiceAA());
            break;
          case 27:
            injector1.addSingleton<ServiceAB>((i) => ServiceAB());
            break;
          case 28:
            injector1.addSingleton<ServiceAC>((i) => ServiceAC());
            break;
          case 29:
            injector1.addSingleton<ServiceAD>((i) => ServiceAD());
            break;
          case 30:
            injector1.addSingleton<ServiceAE>((i) => ServiceAE());
            break;
          case 31:
            injector1.addSingleton<ServiceAF>((i) => ServiceAF());
            break;
          case 32:
            injector1.addSingleton<ServiceAG>((i) => ServiceAG());
            break;
          case 33:
            injector1.addSingleton<ServiceAH>((i) => ServiceAH());
            break;
          case 34:
            injector1.addSingleton<ServiceAI>((i) => ServiceAI());
            break;
          case 35:
            injector1.addSingleton<ServiceAJ>((i) => ServiceAJ());
            break;
          case 36:
            injector1.addSingleton<ServiceAK>((i) => ServiceAK());
            break;
          case 37:
            injector1.addSingleton<ServiceAL>((i) => ServiceAL());
            break;
          case 38:
            injector1.addSingleton<ServiceAM>((i) => ServiceAM());
            break;
          case 39:
            injector1.addSingleton<ServiceAN>((i) => ServiceAN());
            break;
          case 40:
            injector1.addSingleton<ServiceAO>((i) => ServiceAO());
            break;
          case 41:
            injector1.addSingleton<ServiceAP>((i) => ServiceAP());
            break;
          case 42:
            injector1.addSingleton<ServiceAQ>((i) => ServiceAQ());
            break;
          case 43:
            injector1.addSingleton<ServiceAR>((i) => ServiceAR());
            break;
          case 44:
            injector1.addSingleton<ServiceAS>((i) => ServiceAS());
            break;
          case 45:
            injector1.addSingleton<ServiceAT>((i) => ServiceAT());
            break;
          case 46:
            injector1.addSingleton<ServiceAU>((i) => ServiceAU());
            break;
          case 47:
            injector1.addSingleton<ServiceAV>((i) => ServiceAV());
            break;
          case 48:
            injector1.addSingleton<ServiceAW>((i) => ServiceAW());
            break;
          case 49:
            injector1.addSingleton<ServiceAX>((i) => ServiceAX());
            break;
        }
      }

      final binds1 = injector1.finishRegistering();
      final stopwatch1 = Stopwatch()..start();
      for (final bind in binds1) {
        Bind.register(bind);
      }
      stopwatch1.stop();
      final timeWithType = stopwatch1.elapsedMicroseconds;

      // Teste SEM tipagem
      Bind.clearAll();
      final injector2 = Injector();
      injector2.startRegistering();

      // Registra 50 classes diferentes SEM tipagem explícita na mesma ordem aleatória
      for (final idx in order1) {
        switch (idx) {
          case 0:
            injector2.addSingleton((i) => ServiceA());
            break;
          case 1:
            injector2.addSingleton((i) => ServiceB());
            break;
          case 2:
            injector2.addSingleton((i) => ServiceC());
            break;
          case 3:
            injector2.addSingleton((i) => ServiceD());
            break;
          case 4:
            injector2.addSingleton((i) => ServiceE());
            break;
          case 5:
            injector2.addSingleton((i) => ServiceF());
            break;
          case 6:
            injector2.addSingleton((i) => ServiceG());
            break;
          case 7:
            injector2.addSingleton((i) => ServiceH());
            break;
          case 8:
            injector2.addSingleton((i) => ServiceI());
            break;
          case 9:
            injector2.addSingleton((i) => ServiceJ());
            break;
          case 10:
            injector2.addSingleton((i) => ServiceK());
            break;
          case 11:
            injector2.addSingleton((i) => ServiceL());
            break;
          case 12:
            injector2.addSingleton((i) => ServiceM());
            break;
          case 13:
            injector2.addSingleton((i) => ServiceN());
            break;
          case 14:
            injector2.addSingleton((i) => ServiceO());
            break;
          case 15:
            injector2.addSingleton((i) => ServiceP());
            break;
          case 16:
            injector2.addSingleton((i) => ServiceQ());
            break;
          case 17:
            injector2.addSingleton((i) => ServiceR());
            break;
          case 18:
            injector2.addSingleton((i) => ServiceS());
            break;
          case 19:
            injector2.addSingleton((i) => ServiceT());
            break;
          case 20:
            injector2.addSingleton((i) => ServiceU());
            break;
          case 21:
            injector2.addSingleton((i) => ServiceV());
            break;
          case 22:
            injector2.addSingleton((i) => ServiceW());
            break;
          case 23:
            injector2.addSingleton((i) => ServiceX());
            break;
          case 24:
            injector2.addSingleton((i) => ServiceY());
            break;
          case 25:
            injector2.addSingleton((i) => ServiceZ());
            break;
          case 26:
            injector2.addSingleton((i) => ServiceAA());
            break;
          case 27:
            injector2.addSingleton((i) => ServiceAB());
            break;
          case 28:
            injector2.addSingleton((i) => ServiceAC());
            break;
          case 29:
            injector2.addSingleton((i) => ServiceAD());
            break;
          case 30:
            injector2.addSingleton((i) => ServiceAE());
            break;
          case 31:
            injector2.addSingleton((i) => ServiceAF());
            break;
          case 32:
            injector2.addSingleton((i) => ServiceAG());
            break;
          case 33:
            injector2.addSingleton((i) => ServiceAH());
            break;
          case 34:
            injector2.addSingleton((i) => ServiceAI());
            break;
          case 35:
            injector2.addSingleton((i) => ServiceAJ());
            break;
          case 36:
            injector2.addSingleton((i) => ServiceAK());
            break;
          case 37:
            injector2.addSingleton((i) => ServiceAL());
            break;
          case 38:
            injector2.addSingleton((i) => ServiceAM());
            break;
          case 39:
            injector2.addSingleton((i) => ServiceAN());
            break;
          case 40:
            injector2.addSingleton((i) => ServiceAO());
            break;
          case 41:
            injector2.addSingleton((i) => ServiceAP());
            break;
          case 42:
            injector2.addSingleton((i) => ServiceAQ());
            break;
          case 43:
            injector2.addSingleton((i) => ServiceAR());
            break;
          case 44:
            injector2.addSingleton((i) => ServiceAS());
            break;
          case 45:
            injector2.addSingleton((i) => ServiceAT());
            break;
          case 46:
            injector2.addSingleton((i) => ServiceAU());
            break;
          case 47:
            injector2.addSingleton((i) => ServiceAV());
            break;
          case 48:
            injector2.addSingleton((i) => ServiceAW());
            break;
          case 49:
            injector2.addSingleton((i) => ServiceAX());
            break;
        }
      }

      final binds2 = injector2.finishRegistering();
      final stopwatch2 = Stopwatch()..start();
      for (final bind in binds2) {
        Bind.register(bind);
      }
      stopwatch2.stop();
      final timeWithoutType = stopwatch2.elapsedMicroseconds;

      // Calcula diferença percentual
      final difference = timeWithoutType - timeWithType;
      final percentDiff = (difference / timeWithType) * 100;

      print('\n📊 [COMPARAÇÃO DE PERFORMANCE - 50 CLASSES DIFERENTES]');
      print('═══════════════════════════════════════════════════════════════');
      print('COM tipagem explícita:    ${timeWithType}μs (${(timeWithType / 1000).toStringAsFixed(2)}ms)');
      print('SEM tipagem (auto-resolve): ${timeWithoutType}μs (${(timeWithoutType / 1000).toStringAsFixed(2)}ms)');
      print('───────────────────────────────────────────────────────────────');
      print('Diferença: ${difference}μs (${percentDiff.toStringAsFixed(2)}%)');
      if (percentDiff > 0) {
        print('⚠️  Auto-resolve é ${percentDiff.toStringAsFixed(2)}% mais lento');
      } else {
        print('✅ Auto-resolve é ${(-percentDiff).toStringAsFixed(2)}% mais rápido');
      }
      print('═══════════════════════════════════════════════════════════════\n');

      // Verifica que ambos funcionam resolvendo algumas classes
      Bind.clearAll();
      final injector3 = Injector();
      injector3.startRegistering();
      injector3.addSingleton<ServiceA>((i) => ServiceA());
      injector3.addSingleton((i) => ServiceB());
      final binds3 = injector3.finishRegistering();
      for (final bind in binds3) {
        Bind.register(bind);
      }
      expect(Bind.get<ServiceA>(), isA<ServiceA>());
      expect(Bind.get<ServiceB>(), isA<ServiceB>());
    });
  });
}
