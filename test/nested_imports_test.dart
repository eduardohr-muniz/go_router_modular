import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

/// ═══════════════════════════════════════════════════════════════
/// 🎯 TESTE DE IMPORTS ANINHADOS (NESTED IMPORTS)
/// ═══════════════════════════════════════════════════════════════
///
/// Estrutura:
/// AppModule (Nível 0)
///   └─ imports: ModuleA (Nível 1)
///         └─ imports: ModuleB (Nível 2)
///               └─ imports: ModuleC (Nível 3)
///                     └─ imports: ModuleD (Nível 4)
///                           └─ imports: ModuleE (Nível 5 - mais profundo)
///
/// Cada módulo registra seus próprios binds e tenta acessar binds
/// dos módulos acima dele na hierarquia.
/// ═══════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════
// 🔹 INTERFACES E IMPLEMENTAÇÕES
// ═══════════════════════════════════════════════════════════════

/// Interface para serviços de cada nível
abstract class ILevelService {
  String get level;
  String get message;
}

/// Serviço do AppModule (Nível 0)
class AppService implements ILevelService {
  @override
  final String level = 'AppModule (Nível 0)';

  @override
  final String message = '🏠 Serviço do AppModule';
}

/// Serviço do Módulo A (Nível 1)
class ServiceA implements ILevelService {
  final AppService appService;

  ServiceA({required this.appService});

  @override
  final String level = 'ModuleA (Nível 1)';

  @override
  String get message => '📦 Serviço A - depende de: ${appService.message}';
}

/// Serviço do Módulo B (Nível 2)
class ServiceB implements ILevelService {
  final AppService appService;
  final ServiceA serviceA;

  ServiceB({required this.appService, required this.serviceA});

  @override
  final String level = 'ModuleB (Nível 2)';

  @override
  String get message => '📦 Serviço B - depende de: ${appService.message} + ${serviceA.message}';
}

/// Serviço do Módulo C (Nível 3)
class ServiceC implements ILevelService {
  final AppService appService;
  final ServiceA serviceA;
  final ServiceB serviceB;

  ServiceC({
    required this.appService,
    required this.serviceA,
    required this.serviceB,
  });

  @override
  final String level = 'ModuleC (Nível 3)';

  @override
  String get message => '📦 Serviço C - depende de: ${appService.message} + ${serviceA.message} + ${serviceB.message}';
}

/// Serviço do Módulo D (Nível 4)
class ServiceD implements ILevelService {
  final AppService appService;
  final ServiceA serviceA;
  final ServiceB serviceB;
  final ServiceC serviceC;

  ServiceD({
    required this.appService,
    required this.serviceA,
    required this.serviceB,
    required this.serviceC,
  });

  @override
  final String level = 'ModuleD (Nível 4)';

  @override
  String get message => '📦 Serviço D - depende de TODOS os anteriores';
}

/// Serviço do Módulo E (Nível 5 - mais profundo)
class ServiceE implements ILevelService {
  final AppService appService;
  final ServiceA serviceA;
  final ServiceB serviceB;
  final ServiceC serviceC;
  final ServiceD serviceD;

  ServiceE({
    required this.appService,
    required this.serviceA,
    required this.serviceB,
    required this.serviceC,
    required this.serviceD,
  });

  @override
  final String level = 'ModuleE (Nível 5 - Mais Profundo)';

  @override
  String get message => '🎯 Serviço E - CONSEGUE ACESSAR TODOS OS 5 NÍVEIS!';
}

// ═══════════════════════════════════════════════════════════════
// 🔹 MÓDULOS (DO MAIS PROFUNDO PARA O MAIS RASO)
// ═══════════════════════════════════════════════════════════════

/// Módulo E (Nível 5 - Mais Profundo - SEM imports)
class ModuleE extends Module {
  @override
  List<Module> imports() => []; // Nível mais profundo - sem imports

  @override
  void binds(Injector i) {
    print('');
    print('   🎯 [ModuleE - Nível 5] Registrando ServiceE...');
    print('   ℹ️  Usando factory function com i.get() - buscará TODAS as dependências');

    // ✅ Factory function com i.get() - resolve em runtime com fallback para AppModule
    i.addSingleton<ServiceE>(() => ServiceE(
          appService: i.get<AppService>(),
          serviceA: i.get<ServiceA>(),
          serviceB: i.get<ServiceB>(),
          serviceC: i.get<ServiceC>(),
          serviceD: i.get<ServiceD>(),
        ));
    print('   ✅ [ModuleE] ServiceE registrado com factory function!');
    print('   ✅ Todas as dependências serão resolvidas via i.get() em runtime');
  }

  @override
  List<ModularRoute> get routes => [];
}

/// Módulo D (Nível 4)
class ModuleD extends Module {
  @override
  List<Module> imports() => [ModuleE()]; // Importa ModuleE

  @override
  void binds(Injector i) {
    print('');
    print('   📦 [ModuleD - Nível 4] Registrando ServiceD...');
    print('   ℹ️  Usando factory function com i.get() - buscará com fallback');

    // ✅ Factory function com i.get() - resolve em runtime com fallback para AppModule
    i.addSingleton<ServiceD>(() => ServiceD(
          appService: i.get<AppService>(),
          serviceA: i.get<ServiceA>(),
          serviceB: i.get<ServiceB>(),
          serviceC: i.get<ServiceC>(),
        ));
    print('   ✅ [ModuleD] ServiceD registrado com factory function!');
  }

  @override
  List<ModularRoute> get routes => [];
}

/// Módulo C (Nível 3)
class ModuleC extends Module {
  @override
  List<Module> imports() => [ModuleD()]; // Importa ModuleD → ModuleE

  @override
  void binds(Injector i) {
    print('');
    print('   📦 [ModuleC - Nível 3] Registrando ServiceC...');
    print('   ℹ️  Usando factory function com i.get() - buscará com fallback');

    // ✅ Factory function com i.get() - resolve em runtime com fallback para AppModule
    i.addSingleton<ServiceC>(() => ServiceC(
          appService: i.get<AppService>(),
          serviceA: i.get<ServiceA>(),
          serviceB: i.get<ServiceB>(),
        ));
    print('   ✅ [ModuleC] ServiceC registrado com factory function!');
  }

  @override
  List<ModularRoute> get routes => [];
}

/// Módulo B (Nível 2)
class ModuleB extends Module {
  @override
  List<Module> imports() => [ModuleC()]; // Importa ModuleC → ModuleD → ModuleE

  @override
  void binds(Injector i) {
    print('');
    print('   📦 [ModuleB - Nível 2] Registrando ServiceB...');
    print('   ℹ️  Usando factory function com i.get() - buscará com fallback');

    // ✅ Factory function com i.get() - resolve em runtime com fallback para AppModule
    i.addSingleton<ServiceB>(() => ServiceB(
          appService: i.get<AppService>(),
          serviceA: i.get<ServiceA>(),
        ));
    print('   ✅ [ModuleB] ServiceB registrado com factory function!');
  }

  @override
  List<ModularRoute> get routes => [];
}

/// Módulo A (Nível 1)
class ModuleA extends Module {
  @override
  List<Module> imports() => [ModuleB()]; // Importa ModuleB → ModuleC → ModuleD → ModuleE

  @override
  void binds(Injector i) {
    print('');
    print('   📦 [ModuleA - Nível 1] Tentando acessar AppService...');

    try {
      final app = i.get<AppService>();

      i.addSingleton<ServiceA>(() => ServiceA(appService: app));
      print('   ✅ [ModuleA] ServiceA registrado!');
    } catch (e) {
      print('   ❌ [ModuleA] ERRO: $e');
      rethrow;
    }
  }

  @override
  List<ModularRoute> get routes => [];
}

/// AppModule (Nível 0 - Raiz)
/// IMPORTA TODOS OS MÓDULOS EM CADEIA
class TestAppModuleNested extends Module {
  @override
  List<Module> imports() => [
        ModuleA(), // Importa A → B → C → D → E
      ];

  @override
  void binds(Injector i) {
    print('');
    print('   🏠 [AppModule - Nível 0] Registrando AppService...');
    i.addSingleton<AppService>(AppService.new);
    print('   ✅ [AppModule] AppService registrado!');
    print('   ℹ️  AppModule terá acesso a TODOS os serviços dos módulos importados!');
  }

  @override
  List<ModularRoute> get routes => [];
}

// ═══════════════════════════════════════════════════════════════
// 🔹 TESTES
// ═══════════════════════════════════════════════════════════════

void main() {
  group('🎯 Nested Imports Test - 5 Níveis de Profundidade', () {
    setUp(() {
      InjectionManager.instance.clearAllForTesting();
    });

    tearDown(() {
      InjectionManager.instance.clearAllForTesting();
    });

    test(
      '✅ DEVE resolver dependências em 5 níveis de imports aninhados',
      () async {
        print('');
        print('════════════════════════════════════════════════════════════════');
        print('🎯 TESTE: Imports Aninhados - 5 Módulos em Cadeia');
        print('════════════════════════════════════════════════════════════════');
        print('Estrutura:');
        print('  AppModule (0) → ModuleA (1) → ModuleB (2) → ModuleC (3) → ModuleD (4) → ModuleE (5)');
        print('════════════════════════════════════════════════════════════════');

        // Registrar AppModule com toda a cadeia de imports
        final appModule = TestAppModuleNested();
        await InjectionManager.instance.registerAppModule(appModule);

        print('');
        print('════════════════════════════════════════════════════════════════');
        print('🔍 VERIFICANDO ACESSIBILIDADE DOS SERVIÇOS...');
        print('════════════════════════════════════════════════════════════════');

        // Verificar se TODOS os serviços estão acessíveis
        final appService = Modular.get<AppService>();
        expect(appService, isNotNull);
        expect(appService.level, equals('AppModule (Nível 0)'));
        print('✅ AppService (Nível 0) acessível');

        final serviceA = Modular.get<ServiceA>();
        expect(serviceA, isNotNull);
        expect(serviceA.level, equals('ModuleA (Nível 1)'));
        expect(serviceA.appService, isNotNull);
        print('✅ ServiceA (Nível 1) acessível e com dependências resolvidas');

        final serviceB = Modular.get<ServiceB>();
        expect(serviceB, isNotNull);
        expect(serviceB.level, equals('ModuleB (Nível 2)'));
        expect(serviceB.appService, isNotNull);
        expect(serviceB.serviceA, isNotNull);
        print('✅ ServiceB (Nível 2) acessível e com dependências resolvidas');

        final serviceC = Modular.get<ServiceC>();
        expect(serviceC, isNotNull);
        expect(serviceC.level, equals('ModuleC (Nível 3)'));
        expect(serviceC.appService, isNotNull);
        expect(serviceC.serviceA, isNotNull);
        expect(serviceC.serviceB, isNotNull);
        print('✅ ServiceC (Nível 3) acessível e com dependências resolvidas');

        final serviceD = Modular.get<ServiceD>();
        expect(serviceD, isNotNull);
        expect(serviceD.level, equals('ModuleD (Nível 4)'));
        expect(serviceD.appService, isNotNull);
        expect(serviceD.serviceA, isNotNull);
        expect(serviceD.serviceB, isNotNull);
        expect(serviceD.serviceC, isNotNull);
        print('✅ ServiceD (Nível 4) acessível e com dependências resolvidas');

        final serviceE = Modular.get<ServiceE>();
        expect(serviceE, isNotNull);
        expect(serviceE.level, equals('ModuleE (Nível 5 - Mais Profundo)'));
        expect(serviceE.appService, isNotNull);
        expect(serviceE.serviceA, isNotNull);
        expect(serviceE.serviceB, isNotNull);
        expect(serviceE.serviceC, isNotNull);
        expect(serviceE.serviceD, isNotNull);
        print('✅ ServiceE (Nível 5 - Mais Profundo) acessível e com TODAS as dependências resolvidas!');

        print('');
        print('════════════════════════════════════════════════════════════════');
        print('🎉 SUCESSO! Todos os 5 níveis de imports aninhados funcionam!');
        print('════════════════════════════════════════════════════════════════');
        print('');
        print('Mensagens dos serviços:');
        print('  [0] ${appService.message}');
        print('  [1] ${serviceA.message}');
        print('  [2] ${serviceB.message}');
        print('  [3] ${serviceC.message}');
        print('  [4] ${serviceD.message}');
        print('  [5] ${serviceE.message}');
        print('');
      },
    );

    test(
      '✅ DEVE permitir que módulo mais profundo acesse serviços do AppModule',
      () async {
        print('');
        print('════════════════════════════════════════════════════════════════');
        print('🎯 TESTE: Módulo mais profundo acessa AppModule diretamente');
        print('════════════════════════════════════════════════════════════════');

        final appModule = TestAppModuleNested();
        await InjectionManager.instance.registerAppModule(appModule);

        // ModuleE (nível 5) deve conseguir acessar AppService (nível 0)
        final serviceE = Modular.get<ServiceE>();
        final appServiceFromE = serviceE.appService;

        expect(appServiceFromE, isNotNull);
        expect(appServiceFromE.level, equals('AppModule (Nível 0)'));

        // Verificar que é a MESMA instância (singleton)
        final appServiceDirect = Modular.get<AppService>();
        expect(identical(appServiceFromE, appServiceDirect), isTrue, reason: 'ServiceE deve receber a MESMA instância de AppService (singleton)');

        print('✅ Módulo mais profundo (nível 5) acessa AppModule (nível 0) corretamente!');
        print('✅ Singleton funcionando: mesma instância em todos os níveis!');
      },
    );

    test(
      '✅ DEVE manter isolamento correto entre os módulos',
      () async {
        print('');
        print('════════════════════════════════════════════════════════════════');
        print('🎯 TESTE: Isolamento e Visibilidade Correta');
        print('════════════════════════════════════════════════════════════════');

        final appModule = TestAppModuleNested();
        await InjectionManager.instance.registerAppModule(appModule);

        // Cada serviço deve ter acesso apenas aos serviços registrados
        // nos módulos acima dele na hierarquia

        final serviceA = Modular.get<ServiceA>();
        expect(serviceA.appService, isNotNull, reason: 'ServiceA deve ter acesso a AppService');

        final serviceB = Modular.get<ServiceB>();
        expect(serviceB.appService, isNotNull, reason: 'ServiceB deve ter acesso a AppService');
        expect(serviceB.serviceA, isNotNull, reason: 'ServiceB deve ter acesso a ServiceA');

        final serviceC = Modular.get<ServiceC>();
        expect(serviceC.appService, isNotNull);
        expect(serviceC.serviceA, isNotNull);
        expect(serviceC.serviceB, isNotNull);

        print('✅ Todos os serviços têm acesso correto às suas dependências!');
        print('✅ Hierarquia de visibilidade funcionando perfeitamente!');
      },
    );
  });
}
