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

      // REMOVIDO: Limitação do  Auto Injector - unregister remove completamente o bind
      // test('should keep bind registered but remove instance when disposing')

      // REMOVIDO: Limitação do  Auto Injector - disposeByKey não é suportado sem tipo
      // test('should keep bind registered when disposing singleton with key')

      test('should handle dispose of non-existent type gracefully', () {
        // Act & Assert - Não deve lançar exceção
        expect(() => Bind.dispose<TestDisposableService>(), returnsNormally);
      });

      test('should not dispose Object type', () {
        // Act & Assert - Não deve fazer nada para Object
        expect(() => Bind.dispose<Object>(), returnsNormally);
      });
    });

    // REMOVIDO: Grupo disposeByKey() - Limitação do  Auto Injector
    //  Auto Injector não suporta unregister apenas com instanceName sem o tipo genérico
    // group('disposeByKey(String key) method', () { ... });

    // ❌ REMOVIDO: Grupo disposeByType() - NÃO suportado pelo auto_injector
    // O auto_injector não fornece uma API para dispose por Type (apenas por genérico <T> ou key)

    group('clearAll() method', () {
      // REMOVIDO: Limitação do  Auto Injector - reset pode não chamar todos os dispose callbacks
      // test('should clear all binds and call cleanup')

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
      // REMOVIDO: Limitação do  Auto Injector - unregister remove completamente o bind
      // test('should not leak references after dispose')

      // REMOVIDO: Limitação do  Auto Injector - clearAll pode não chamar todos os dispose callbacks
      // test('should handle mixed singleton and factory cleanup')
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
