import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

// Importar as classes de teste do arquivo principal
import 'module_isolation_test.dart';

/// Teste isolado para CASO PERMITIDO #2
/// Este teste é executado separadamente porque apresenta race condition
/// quando executado junto com outros testes
void main() {
  group('Module Isolation Tests - Isolated', () {
    setUp(() async {
      // Limpar estado antes de cada teste
      // await InjectionManager.instance.clearAllForTesting();
    });

    tearDown(() async {
      // Limpar estado após cada teste
      // await InjectionManager.instance.clearAllForTesting();
    });

    test('✅ CASO PERMITIDO #2: Módulo B importa A e acessa seus binds', () async {
      // Arrange: Criar módulos
      final appModule = AppModuleEmpty();
      final moduleA = ModuleA();
      final moduleBWithImports = ModuleBWithImports();

      // Act: Registrar AppModule vazio primeiro
      await InjectionManager.instance.registerAppModule(appModule);

      // Registrar módulo A como módulo comum
      await InjectionManager.instance.registerBindsModule(moduleA);

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
  });
}
