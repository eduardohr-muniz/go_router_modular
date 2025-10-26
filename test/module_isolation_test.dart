import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

/// Teste para verificar isolamento entre módulos
///
/// REGRAS DE ACESSO A BINDS:
/// 1. ✅ PERMITIDO: Acessar binds do AppModule (disponíveis globalmente)
/// 2. ✅ PERMITIDO: Acessar binds de módulos importados via imports()
/// 3. ❌ PROIBIDO: Acessar binds de módulos não importados (mesmo que inicializados antes)
///
/// PROBLEMA ATUAL: Módulo B consegue acessar binds de Módulo A mesmo sem importar,
/// apenas porque A foi inicializado antes (vazamento de dependências).
void main() {
  group('Module Isolation Tests - Vazamento de Dependências', () {
    setUp(() {
      // Limpar estado antes de cada teste
      InjectionManager.instance.clearAllForTesting();
    });

    tearDown(() {
      // Limpar estado após cada teste
      InjectionManager.instance.clearAllForTesting();
    });

    test('✅ CASO PERMITIDO #1: Módulos podem acessar binds do AppModule', () async {
      // Arrange: Criar AppModule e ModuleB
      final appModule = AppModuleTest();
      final moduleB = ModuleB();

      // Act: Registrar AppModule e ModuleB
      await InjectionManager.instance.registerAppModule(appModule);
      await InjectionManager.instance.registerBindsModule(moduleB);

      // Assert: ModuleB deve conseguir acessar GlobalService do AppModule
      final globalService = Modular.get<GlobalService>();
      expect(globalService, isNotNull);
      print('✅ CORRETO: ModuleB conseguiu acessar GlobalService do AppModule');
      print('✅ Binds do AppModule são GLOBAIS e devem estar disponíveis para todos os módulos');
    });

    test('✅ CASO PERMITIDO #2: Módulo B importa A e acessa seus binds', () async {
      // Arrange: Criar módulos
      final moduleA = ModuleA();
      final moduleBWithImports = ModuleBWithImports();

      // Act: Registrar módulo A como AppModule
      await InjectionManager.instance.registerAppModule(moduleA);

      // Registrar módulo B que IMPORTA A
      await InjectionManager.instance.registerBindsModule(moduleBWithImports);

      // Definir contexto do módulo B (simular navegação para rota de B)
      InjectionManager.instance.setModuleContext(ModuleBWithImports);

      // Assert: ModuleB deve conseguir acessar ServiceA (importou A) e ServiceB (próprio)
      final serviceA = Modular.get<ServiceA>();
      final serviceB = Modular.get<ServiceB>();

      expect(serviceA, isNotNull);
      expect(serviceB, isNotNull);
      expect(serviceB.serviceA, isNotNull);
      print('✅ CORRETO: ModuleBWithImports importou ModuleA e acessa ServiceA');
    });

    test('❌ CASO PROIBIDO: Módulo B acessa binds de A sem declarar imports', () async {
      // Arrange: Criar módulos
      final moduleA = ModuleA();
      final moduleB = ModuleB();

      // IMPORTANTE: ModuleA NÃO é AppModule, é um módulo comum
      // Registrar um AppModule vazio primeiro
      await InjectionManager.instance.registerAppModule(AppModuleEmpty());

      // Registrar módulo A como módulo comum
      await InjectionManager.instance.registerBindsModule(moduleA);

      // Registrar módulo B (que NÃO importa A)
      await InjectionManager.instance.registerBindsModule(moduleB);

      // Definir contexto do módulo B (simular navegação para rota de B)
      InjectionManager.instance.setModuleContext(ModuleB);

      // Assert: COMPORTAMENTO ESPERADO - B NÃO deve conseguir acessar ServiceA
      expect(
        () => Modular.get<ServiceA>(),
        throwsA(isA<Exception>()),
        reason: 'ModuleB não deveria conseguir acessar ServiceA sem importar ModuleA',
      );
      print('✅ ISOLAMENTO CORRETO: ModuleB não conseguiu acessar ServiceA sem importar ModuleA');
    });

    test('🔒 ISOLAMENTO: Após dispose de módulo, seus binds não devem estar acessíveis', () async {
      // Arrange: Criar módulos
      final appModule = AppModuleEmpty();
      final moduleA = ModuleA();

      // Act: Registrar AppModule vazio
      await InjectionManager.instance.registerAppModule(appModule);

      // Registrar módulo A
      await InjectionManager.instance.registerBindsModule(moduleA);

      // Definir contexto do módulo A
      InjectionManager.instance.setModuleContext(ModuleA);

      // Verificar que ServiceA está acessível
      final serviceA = Modular.get<ServiceA>();
      expect(serviceA, isNotNull);

      // Dispose do módulo A
      await InjectionManager.instance.unregisterModule(moduleA);

      // Assert: COMPORTAMENTO ESPERADO - ServiceA não deve estar acessível após dispose
      expect(
        () => Modular.get<ServiceA>(),
        throwsA(isA<GoRouterModularException>()),
        reason: 'ServiceA não deveria estar acessível após dispose de ModuleA',
      );

      print('✅ ISOLAMENTO CORRETO: Após dispose de ModuleA, ServiceA não está mais acessível');
    });

    test('📊 DIAGNÓSTICO: Verificar quantos binds estão disponíveis em cada contexto', () async {
      // Arrange: Criar módulos
      final moduleA = ModuleA();
      final moduleB = ModuleB();

      // Act & Assert: Verificar binds em cada etapa

      // 1. Apenas ModuleA registrado (como AppModule)
      await InjectionManager.instance.registerAppModule(moduleA);

      try {
        Modular.get<ServiceA>();
        print('✅ Após registrar ModuleA (AppModule): ServiceA está disponível');
      } catch (e) {
        print('❌ Após registrar ModuleA (AppModule): ServiceA NÃO está disponível');
      }

      try {
        Modular.get<ServiceB>();
        print('⚠️ Após registrar ModuleA (AppModule): ServiceB está disponível (INESPERADO)');
      } catch (e) {
        print('✅ Após registrar ModuleA (AppModule): ServiceB NÃO está disponível (esperado)');
      }

      // 2. ModuleA (AppModule) + ModuleB registrados
      await InjectionManager.instance.registerBindsModule(moduleB);

      // Definir contexto do módulo B
      InjectionManager.instance.setModuleContext(ModuleB);

      try {
        Modular.get<ServiceA>();
        print('✅ Após registrar ModuleB: ServiceA está disponível (do AppModule)');
      } catch (e) {
        print('❌ Após registrar ModuleB: ServiceA NÃO está disponível');
      }

      try {
        Modular.get<ServiceB>();
        print('✅ Após registrar ModuleB: ServiceB está disponível');
      } catch (e) {
        print('❌ Após registrar ModuleB: ServiceB NÃO está disponível');
      }
    });

    test('🔍 EDGE CASE: Módulo C importa B que não importa A - C não deve acessar A', () async {
      // Arrange: Criar cadeia de módulos
      final appModule = AppModuleEmpty();
      final moduleA = ModuleA();
      final moduleB = ModuleB();
      final moduleC = ModuleCImportsB();

      // Act: Registrar AppModule vazio primeiro
      await InjectionManager.instance.registerAppModule(appModule);

      // Registrar módulos em ordem (todos como módulos comuns)
      await InjectionManager.instance.registerBindsModule(moduleA);
      await InjectionManager.instance.registerBindsModule(moduleB);
      await InjectionManager.instance.registerBindsModule(moduleC);

      // Definir contexto do módulo C
      InjectionManager.instance.setModuleContext(ModuleCImportsB);

      // Assert: Verificar acessibilidade

      // ServiceC deve estar disponível
      final serviceC = Modular.get<ServiceC>();
      expect(serviceC, isNotNull);

      // ServiceB deve estar disponível (C importa B)
      final serviceB = Modular.get<ServiceB>();
      expect(serviceB, isNotNull);

      // COMPORTAMENTO ESPERADO: ServiceA NÃO deve estar disponível
      // (C importa B, mas B não importa A)
      expect(
        () => Modular.get<ServiceA>(),
        throwsA(isA<Exception>()),
        reason: 'ModuleC não deveria acessar ServiceA (C→B, mas B não importa A)',
      );
      print('✅ ISOLAMENTO EM CADEIA CORRETO: ModuleC não conseguiu acessar ServiceA');
    });
  });
}

// ============================================================================
// MÓDULOS E SERVICES DE TESTE
// ============================================================================

/// AppModule vazio para testes
class AppModuleEmpty extends Module {}

/// AppModule de teste com GlobalService
class AppModuleTest extends Module {
  @override
  void binds(Injector i) {
    i.addLazySingleton(() => GlobalService());
  }
}

/// Módulo A - Fornece ServiceA
class ModuleA extends Module {
  @override
  void binds(Injector i) {
    i.addLazySingleton(() => ServiceA());
  }
}

/// Módulo B - NÃO importa A, mas fornece ServiceB
class ModuleB extends Module {
  @override
  void binds(Injector i) {
    i.addLazySingleton(() => ServiceB(serviceA: null)); // Não depende de A
  }
}

/// Módulo B com imports - BOA PRÁTICA
class ModuleBWithImports extends Module {
  @override
  List<Module> imports() => [ModuleA()];

  @override
  void binds(Injector i) {
    i.addLazySingleton(() => ServiceB(serviceA: i.get<ServiceA>()));
  }
}

/// Módulo C - Importa B
class ModuleCImportsB extends Module {
  @override
  List<Module> imports() => [ModuleB()];

  @override
  void binds(Injector i) {
    i.addLazySingleton(() => ServiceC(serviceB: i.get<ServiceB>()));
  }
}

// ============================================================================
// SERVICES DE TESTE
// ============================================================================

class GlobalService {
  final String name = 'GlobalService';

  void dispose() {
    print('🗑️ GlobalService disposed');
  }
}

class ServiceA {
  final String name = 'ServiceA';

  void dispose() {
    print('🗑️ ServiceA disposed');
  }
}

class ServiceB {
  final ServiceA? serviceA;
  final String name = 'ServiceB';

  ServiceB({this.serviceA});

  void dispose() {
    print('🗑️ ServiceB disposed');
  }
}

class ServiceC {
  final ServiceB serviceB;
  final String name = 'ServiceC';

  ServiceC({required this.serviceB});

  void dispose() {
    print('🗑️ ServiceC disposed');
  }
}
