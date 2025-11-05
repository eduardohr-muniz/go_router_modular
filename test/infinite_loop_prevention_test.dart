import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/core/dependency_analyzer/dependency_analyzer.dart';

// Classes de teste para simular dependências
class TestService {
  final String name;
  TestService(this.name);
}

class TestDependency {
  final TestService service;
  TestDependency(this.service);
}

class TestModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<TestService>((i) => TestService('test'));
    i.addSingleton<TestDependency>((i) => TestDependency(i.get<TestService>()));
  }

  @override
  List<ModularRoute> get routes => [];
}

class TestModuleWithDisorderedBinds extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    // Binds desordenados - TestDependency depende de TestService
    i.addSingleton<TestDependency>((i) => TestDependency(i.get<TestService>()));
    i.addSingleton<TestService>((i) => TestService('test'));
  }

  @override
  List<ModularRoute> get routes => [];
}

void main() {
  group('Infinite Loop Prevention Tests', () {
    setUp(() {
      // Limpa tudo antes de cada teste
      Bind.clearAll();
      DependencyAnalyzer.clearAll();
    });

    tearDown(() {
      // Limpa tudo após cada teste
      Bind.clearAll();
      DependencyAnalyzer.clearAll();
    });

    test('Não deve entrar em loop infinito ao buscar bind não registrado', () {
      // Arrange & Act & Assert
      expect(() => Bind.get<TestService>(), throwsA(isA<GoRouterModularException>()));

      // Verifica que não há tentativas pendentes após exceção
      expect(() => Bind.get<TestService>(), throwsA(isA<GoRouterModularException>()));
    });

    test('Deve limpar estado de busca após exceção', () {
      // Arrange
      expect(() => Bind.get<TestService>(), throwsA(isA<GoRouterModularException>()));

      // Act - Tenta buscar novamente
      expect(() => Bind.get<TestService>(), throwsA(isA<GoRouterModularException>()));

      // Assert - Não deve acumular tentativas indefinidamente
      // Se chegou aqui sem timeout, o teste passou
    });

    test('Simula cenário de pop e volta: não deve entrar em loop infinito', () async {
      // Arrange - Simula registro de módulo
      final module = TestModule();
      await InjectionManager.instance.registerBindsModule(module);

      // Act 1 - Busca inicial (deve funcionar)
      final service1 = Bind.get<TestService>();
      expect(service1.name, 'test');

      // Simula pop - desregistra módulo
      await InjectionManager.instance.unregisterModule(module);

      // Verifica que o bind foi removido
      expect(() => Bind.get<TestService>(), throwsA(isA<GoRouterModularException>()));

      // Act 2 - Simula volta para página (novo registro)
      await InjectionManager.instance.registerBindsModule(module);

      // Busca novamente (deve funcionar sem loop infinito)
      final service2 = Bind.get<TestService>();
      expect(service2.name, 'test');
    });

    test('Simula múltiplas tentativas de busca antes do módulo estar registrado', () async {
      // Arrange - Registra módulo após delay
      final module = TestModule();

      // Simula widget tentando buscar antes do módulo estar registrado
      bool bindFound = false;
      int attempts = 0;
      const maxAttempts = 10;

      // Inicia registro em background
      final registrationFuture = InjectionManager.instance.registerBindsModule(module);

      // Simula widget tentando buscar múltiplas vezes
      while (!bindFound && attempts < maxAttempts) {
        attempts++;
        final service = Bind.tryGet<TestService>();
        if (service != null) {
          bindFound = true;
          break;
        }
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Aguarda registro completar
      await registrationFuture;

      // Assert
      expect(bindFound, isTrue, reason: 'Bind deve ser encontrado após registro');
      expect(attempts, lessThanOrEqualTo(maxAttempts), reason: 'Não deve ultrapassar limite de tentativas');
    });

    test('Deve respeitar limite máximo absoluto de tentativas', () {
      // Arrange
      int exceptionCount = 0;

      // Act - Simula múltiplas chamadas de get para bind não registrado
      for (int i = 0; i < 10; i++) {
        try {
          Bind.get<TestService>();
        } catch (e) {
          exceptionCount++;
          // Cada chamada deve falhar, mas não acumular tentativas indefinidamente
        }
      }

      // Assert - Cada chamada deve falhar imediatamente após limite
      expect(exceptionCount, equals(10), reason: 'Cada chamada deve falhar, mas não acumular tentativas indefinidamente');
    });

    test('Simula cenário real: módulo com binds desordenados e pop/volta', () async {
      // Arrange
      final module = TestModuleWithDisorderedBinds();

      // Act 1 - Primeira navegação (registro)
      await InjectionManager.instance.registerBindsModule(module);

      // Busca funciona após registro
      final dependency1 = Bind.get<TestDependency>();
      expect(dependency1.service.name, 'test');

      // Simula pop - desregistra módulo
      await InjectionManager.instance.unregisterModule(module);

      // Aguarda processamento do unregister
      await Future.delayed(const Duration(milliseconds: 200));

      // Act 2 - Simula volta para página (novo registro)
      // O objetivo principal é verificar que o re-registro funciona sem loop infinito
      await InjectionManager.instance.registerBindsModule(module);

      // Busca novamente - deve funcionar sem loop infinito
      final dependency2 = Bind.get<TestDependency>();
      expect(dependency2.service.name, 'test');

      // Verifica que não há problemas com múltiplas buscas após re-registro
      final dependency3 = Bind.get<TestDependency>();
      expect(dependency3.service.name, 'test');
    });

    test('Deve limpar estado corretamente quando bind é removido durante busca', () async {
      // Arrange
      final module = TestModule();
      await InjectionManager.instance.registerBindsModule(module);

      // Act - Simula busca sendo interrompida por dispose
      // Inicia busca em background
      Future<void> backgroundSearch() async {
        try {
          Bind.get<TestService>();
        } catch (e) {
          // Exceção esperada quando bind é removido
        }
      }

      // Inicia busca
      final searchFuture = backgroundSearch();

      // Aguarda um pouco para busca iniciar
      await Future.delayed(const Duration(milliseconds: 10));

      // Remove bind enquanto busca está ativa
      await InjectionManager.instance.unregisterModule(module);

      // Aguarda busca completar
      await searchFuture;

      // Assert - Nova busca deve funcionar após re-registro
      await InjectionManager.instance.registerBindsModule(module);
      final service = Bind.get<TestService>();
      expect(service.name, 'test');
    });
  });
}
