import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/di/clean_bind.dart';

// Test classes
class TestDisposableService implements Disposable {
  static int instanceCount = 0;

  TestDisposableService() {
    instanceCount++;
  }

  @override
  void dispose() {
    instanceCount--;
  }
}

class TestCloseService {
  static int instanceCount = 0;

  TestCloseService() {
    instanceCount++;
  }

  void close() {
    instanceCount--;
  }
}

class TestServiceWithKey {
  final String value;
  TestServiceWithKey(this.value);
}

class TestServiceWithoutCleanup {
  final String data = 'test';
}

void main() {
  setUp(() {
    // Limpar estado entre testes
    Bind.clearAll();
    TestDisposableService.instanceCount = 0;
    TestCloseService.instanceCount = 0;
  });

  group('Bind Memory Management Tests', () {
    group('dispose<T>() method - Seguindo padrão auto_injector', () {
      test('should call CleanBind.fromInstance when disposing singleton', () {
        // Arrange
        final bind = Bind.singleton<TestDisposableService>((i) => TestDisposableService());
        Bind.register(bind);

        // Criar instância
        final instance = Bind.get<TestDisposableService>();
        expect(TestDisposableService.instanceCount, 1);
        expect(instance, isA<TestDisposableService>());

        // Act - Dispose da instância
        Bind.dispose<TestDisposableService>();

        // Assert - O dispose() deve ter sido chamado
        expect(TestDisposableService.instanceCount, 0);
      });

      test('should call CleanBind.fromInstance when disposing factory', () {
        // Arrange
        final bind = Bind.factory<TestCloseService>((i) => TestCloseService());
        Bind.register(bind);

        // Criar instância
        Bind.get<TestCloseService>();
        expect(TestCloseService.instanceCount, 1);

        // Act - Factory não mantém instância, então dispose não faz nada
        Bind.dispose<TestCloseService>();

        // Assert - Factory não é singleton, então instanceCount permanece
        expect(TestCloseService.instanceCount, 1);
      });

      test('should keep bind registered but remove instance when disposing', () {
        // Arrange - Seguindo o teste do auto_injector (linha 85-99)
        final bind = Bind.singleton<TestDisposableService>((i) => TestDisposableService());
        Bind.register(bind);

        // Criar primeira instância
        final firstInstance = Bind.get<TestDisposableService>();
        expect(TestDisposableService.instanceCount, 1);

        // Act - Dispose da instância
        Bind.dispose<TestDisposableService>();

        // Assert - Instância foi disposed
        expect(TestDisposableService.instanceCount, 0);

        // Assert - Bind continua registrado, pode criar nova instância
        final secondInstance = Bind.get<TestDisposableService>();
        expect(secondInstance, isNot(same(firstInstance)));
        expect(TestDisposableService.instanceCount, 1); // Nova instância criada
      });

      test('should keep bind registered when disposing singleton with key', () {
        // Arrange
        final bind = Bind.singleton<TestServiceWithKey>((i) => TestServiceWithKey('test'), key: 'test-key');
        Bind.register(bind);

        final firstInstance = Bind.get<TestServiceWithKey>(key: 'test-key');
        expect(firstInstance.value, 'test');

        // Act - Usar disposeByKey para binds com key
        Bind.disposeByKey('test-key');

        // Assert - Bind continua registrado, pode criar nova instância
        final secondInstance = Bind.get<TestServiceWithKey>(key: 'test-key');
        expect(secondInstance, isNot(same(firstInstance)));
        expect(secondInstance.value, 'test');
      });

      test('should handle dispose of non-existent type gracefully', () {
        // Act & Assert - Não deve lançar exceção
        expect(() => Bind.dispose<TestDisposableService>(), returnsNormally);
      });

      test('should not dispose Object type', () {
        // Act & Assert - Não deve fazer nada para Object
        expect(() => Bind.dispose<Object>(), returnsNormally);
      });
    });

    group('disposeByKey(String key) method', () {
      test('should call CleanBind.fromInstance when disposing by key', () {
        // Arrange
        final bind = Bind.singleton<TestDisposableService>((i) => TestDisposableService(), key: 'test-key');
        Bind.register(bind);

        // Criar instância
        Bind.get<TestDisposableService>(key: 'test-key');
        expect(TestDisposableService.instanceCount, 1);

        // Act
        Bind.disposeByKey('test-key');

        // Assert
        expect(TestDisposableService.instanceCount, 0);
      });

      test('should keep bind registered when disposing by key', () {
        // Arrange
        final bind = Bind.singleton<TestServiceWithKey>((i) => TestServiceWithKey('test'), key: 'test-key');
        Bind.register(bind);

        final firstInstance = Bind.get<TestServiceWithKey>(key: 'test-key');

        // Act
        Bind.disposeByKey('test-key');

        // Assert - Bind continua registrado
        final secondInstance = Bind.get<TestServiceWithKey>(key: 'test-key');
        expect(secondInstance, isNot(same(firstInstance)));
      });

      test('should handle dispose of non-existent key gracefully', () {
        // Act & Assert - Não deve lançar exceção
        expect(() => Bind.disposeByKey('non-existent-key'), returnsNormally);
      });

      test('should handle dispose by key for factory bind', () {
        // Arrange
        final bind = Bind.factory<TestCloseService>((i) => TestCloseService(), key: 'factory-key');
        Bind.register(bind);

        // Act - Factory não mantém instância
        Bind.disposeByKey('factory-key');

        // Assert - Deve funcionar normalmente (não faz nada para factory)
        expect(() => Bind.get<TestCloseService>(key: 'factory-key'), returnsNormally);
      });
    });

    // ❌ REMOVIDO: Grupo disposeByType() - NÃO suportado pelo auto_injector
    // O auto_injector não fornece uma API para dispose por Type (apenas por genérico <T> ou key)

    group('clearAll() method', () {
      test('should clear all binds and call cleanup', () {
        // Arrange
        final bind1 = Bind.singleton<TestDisposableService>((i) => TestDisposableService());
        final bind2 = Bind.singleton<TestCloseService>((i) => TestCloseService());
        Bind.register(bind1);
        Bind.register(bind2);

        Bind.get<TestDisposableService>();
        Bind.get<TestCloseService>();

        expect(TestDisposableService.instanceCount, 1);
        expect(TestCloseService.instanceCount, 1);

        // Act
        Bind.clearAll();

        // Assert - Tudo foi limpo
        expect(TestDisposableService.instanceCount, 0);
        expect(TestCloseService.instanceCount, 0);

        // Assert - Binds foram removidos
        expect(() => Bind.get<TestDisposableService>(), throwsA(isA<GoRouterModularException>()));
        expect(() => Bind.get<TestCloseService>(), throwsA(isA<GoRouterModularException>()));
      });

      test('should clear internal tracking maps', () {
        // Arrange
        final bind = Bind.singleton<TestDisposableService>((i) => TestDisposableService());
        Bind.register(bind);
        Bind.get<TestDisposableService>();

        // Act
        Bind.clearAll();

        // Assert - Deve poder registrar novamente após clearAll
        final newBind = Bind.singleton<TestDisposableService>((i) => TestDisposableService());
        expect(() => Bind.register(newBind), returnsNormally);
      });

      test('should handle clearAll when no binds exist', () {
        // Act & Assert
        expect(() => Bind.clearAll(), returnsNormally);
      });
    });

    group('Memory leak prevention', () {
      test('should not leak references after dispose', () {
        // Arrange
        final bind = Bind.singleton<TestDisposableService>((i) => TestDisposableService());
        Bind.register(bind);

        final instance = Bind.get<TestDisposableService>();
        expect(TestDisposableService.instanceCount, 1);

        // Act
        Bind.dispose<TestDisposableService>();

        // Assert - Instância foi disposed
        expect(TestDisposableService.instanceCount, 0);

        // Nova instância é diferente
        final newInstance = Bind.get<TestDisposableService>();
        expect(newInstance, isNot(same(instance)));
      });

      test('should handle mixed singleton and factory cleanup', () {
        // Arrange
        final singletonBind = Bind.singleton<TestDisposableService>((i) => TestDisposableService());
        final factoryBind = Bind.factory<TestCloseService>((i) => TestCloseService());

        Bind.register(singletonBind);
        Bind.register(factoryBind);

        Bind.get<TestDisposableService>();
        Bind.get<TestCloseService>();

        expect(TestDisposableService.instanceCount, 1);
        expect(TestCloseService.instanceCount, 1);

        // Act
        Bind.clearAll();

        // Assert
        expect(TestDisposableService.instanceCount, 0);
        // Factory instances não são gerenciadas pelo injector
        expect(TestCloseService.instanceCount, 1);
      });
    });

    group('CleanBind integration', () {
      test('should call CleanBind.fromInstance for disposable objects', () {
        // Arrange
        final bind = Bind.singleton<TestDisposableService>((i) => TestDisposableService());
        Bind.register(bind);

        Bind.get<TestDisposableService>();
        expect(TestDisposableService.instanceCount, 1);

        // Act
        Bind.dispose<TestDisposableService>();

        // Assert - CleanBind deve ter chamado dispose()
        expect(TestDisposableService.instanceCount, 0);
      });

      test('should call CleanBind.fromInstance for closeable objects', () {
        // Arrange
        final bind = Bind.singleton<TestCloseService>((i) => TestCloseService());
        Bind.register(bind);

        Bind.get<TestCloseService>();
        expect(TestCloseService.instanceCount, 1);

        // Act
        Bind.dispose<TestCloseService>();

        // Assert - CleanBind deve ter chamado close()
        expect(TestCloseService.instanceCount, 0);
      });

      test('should handle CleanBind gracefully for objects without cleanup methods', () {
        // Arrange
        final bind = Bind.singleton<TestServiceWithoutCleanup>((i) => TestServiceWithoutCleanup());
        Bind.register(bind);

        Bind.get<TestServiceWithoutCleanup>();

        // Act & Assert - Não deve lançar exceção
        expect(() => Bind.dispose<TestServiceWithoutCleanup>(), returnsNormally);
      });
    });

    group('CleanBind Tests', () {
      test('should return true for class with dispose method', () {
        final service = TestDisposableService();
        final result = CleanBind.fromInstance(service);
        expect(result, true);
      });

      test('should return true for class with close method', () {
        final service = TestCloseService();
        final result = CleanBind.fromInstance(service);
        expect(result, true);
      });

      test('should return false for class without cleanup methods', () {
        final service = TestServiceWithoutCleanup();
        final result = CleanBind.fromInstance(service);
        expect(result, false);
      });
    });
  });
}
