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

    test('❌ CASO PROIBIDO: Módulo B acessa binds de A sem declarar imports', () async {
      // NOTE: Com o padrão auto_injector (addInjector), todos os módulos têm acesso a todos os binds.
      // Este teste foi ajustado para refletir o comportamento real.

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

      // Assert: COMPORTAMENTO ESPERADO - B NÃO consegue acessar ServiceA (isolamento funcionando)
      expect(
        () => Modular.get<ServiceA>(),
        throwsA(isA<GoRouterModularException>()),
        reason: 'ModuleB NÃO pode acessar ServiceA - isolamento funcionando corretamente',
      );
      print('✅ ISOLAMENTO CORRETO: ModuleB não consegue acessar ServiceA sem importar ModuleA');
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
      // NOTE: Com o padrão auto_injector (addInjector), todos os módulos têm acesso a todos os binds.
      // Este teste foi ajustado para refletir o comportamento real.

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

      // COMPORTAMENTO ESPERADO: ServiceA NÃO está disponível (isolamento funcionando)
      expect(
        () => Modular.get<ServiceA>(),
        throwsA(isA<GoRouterModularException>()),
        reason: 'ModuleC NÃO pode acessar ServiceA - isolamento em cadeia funcionando',
      );
      print('✅ ISOLAMENTO EM CADEIA CORRETO: ModuleC não consegue acessar ServiceA');
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
  FutureBinds binds(Injector i) {
    i.addLazySingleton(() => GlobalService());
  }
}

/// Módulo A - Fornece ServiceA
class ModuleA extends Module {
  @override
  FutureBinds binds(Injector i) {
    i.addLazySingleton(() => ServiceA());
  }
}

/// Módulo B - NÃO importa A, mas fornece ServiceB
class ModuleB extends Module {
  @override
  FutureBinds binds(Injector i) {
    i.addLazySingleton(() => ServiceB(serviceA: null)); // Não depende de A
  }
}

/// Módulo B com imports - BOA PRÁTICA
class ModuleBWithImports extends Module {
  @override
  FutureModules imports() => [ModuleA()];

  @override
  FutureBinds binds(Injector i) {
    // Usar o Injector passado como parâmetro para buscar ServiceA
    // Isso funciona porque o injector do ModuleB tem acesso ao injector do ModuleA
    i.addLazySingleton<ServiceB>(() {
      // Buscar ServiceA através do Injector correto
      // Como ModuleB importa ModuleA, o injector de ModuleB tem acesso ao injector de ModuleA
      final serviceA = i.get<ServiceA>();
      return ServiceB(serviceA: serviceA);
    });
  }
}

/// Módulo C - Importa B
class ModuleCImportsB extends Module {
  @override
  FutureModules imports() => [ModuleB()];

  @override
  FutureBinds binds(Injector i) {
    // IMPORTANTE: Não podemos usar i.get() para buscar em imports durante binds()
    // porque o injector ainda não está commitado.
    // Solução: Deixar o auto_injector resolver automaticamente via construtor
    i.addLazySingleton<ServiceC>(ServiceC.new);
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
