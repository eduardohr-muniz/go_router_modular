import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/src/bind.dart';

// Classes de teste para diferentes cenários de cleanup
class TestDisposableService {
  bool disposed = false;
  static int instanceCount = 0;

  TestDisposableService() {
    instanceCount++;
  }

  void dispose() {
    disposed = true;
    instanceCount--;
  }
}

class TestCloseService {
  bool closed = false;
  static int instanceCount = 0;

  TestCloseService() {
    instanceCount++;
  }

  void close() {
    closed = true;
    instanceCount--;
  }
}

class TestNormalService {
  static int instanceCount = 0;

  TestNormalService() {
    instanceCount++;
  }
}

class TestServiceWithKey {
  bool disposed = false;
  final String id;
  static int instanceCount = 0;

  TestServiceWithKey(this.id) {
    instanceCount++;
  }

  void dispose() {
    disposed = true;
    instanceCount--;
  }
}

class TestCubitService {
  bool closed = false;
  static int instanceCount = 0;

  TestCubitService() {
    instanceCount++;
  }

  void close() {
    closed = true;
    instanceCount--;
  }
}

void main() {
  group('Bind Memory Management Tests', () {
    setUp(() {
      // Limpa todos os binds antes de cada teste
      Bind.clearAll();
      // Reset dos contadores de instância
      TestDisposableService.instanceCount = 0;
      TestCloseService.instanceCount = 0;
      TestNormalService.instanceCount = 0;
      TestServiceWithKey.instanceCount = 0;
      TestCubitService.instanceCount = 0;
    });

    tearDown(() {
      // Limpa todos os binds após cada teste
      Bind.clearAll();
    });

    group('dispose<T>() method', () {
      test('should call CleanBind.fromInstance when disposing singleton', () {
        // Arrange
        final bind = Bind.singleton<TestDisposableService>((i) => TestDisposableService());
        Bind.register(bind);

        // Act
        Bind.dispose<TestDisposableService>();

        // Assert
        expect(TestDisposableService.instanceCount, 0);
      });

      test('should call CleanBind.fromInstance when disposing factory', () {
        // Arrange
        final bind = Bind.factory<TestCloseService>((i) => TestCloseService());
        Bind.register(bind);

        // Act
        Bind.dispose<TestCloseService>();

        // Assert
        expect(TestCloseService.instanceCount, 0);
      });

      test('should remove bind from _bindsMap when disposing', () {
        // Arrange
        final bind = Bind.singleton<TestDisposableService>((i) => TestDisposableService());
        Bind.register(bind);

        // Act
        Bind.dispose<TestDisposableService>();

        // Assert - Verifica se o bind foi removido tentando buscar novamente
        expect(() => Bind.get<TestDisposableService>(), throwsA(isA<Exception>()));
      });

      test('should remove bind from _bindsMapByKey when disposing singleton with key', () {
        // Arrange
        final bind = Bind.singleton<TestServiceWithKey>((i) => TestServiceWithKey('test'), key: 'test-key');
        Bind.register(bind);

        // Act
        Bind.dispose<TestServiceWithKey>();

        // Assert - Verifica se o bind foi removido de ambos os maps
        expect(() => Bind.get<TestServiceWithKey>(), throwsA(isA<Exception>()));
        expect(() => Bind.get<TestServiceWithKey>(key: 'test-key'), throwsA(isA<Exception>()));
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

        // Act
        Bind.disposeByKey('test-key');

        // Assert
        expect(TestDisposableService.instanceCount, 0);
      });

      test('should remove bind from both maps when disposing by key', () {
        // Arrange
        final bind = Bind.singleton<TestServiceWithKey>((i) => TestServiceWithKey('test'), key: 'test-key');
        Bind.register(bind);

        // Act
        Bind.disposeByKey('test-key');

        // Assert - Verifica se o bind foi removido de ambos os maps
        expect(() => Bind.get<TestServiceWithKey>(), throwsA(isA<Exception>()));
        expect(() => Bind.get<TestServiceWithKey>(key: 'test-key'), throwsA(isA<Exception>()));
      });

      test('should handle dispose of non-existent key gracefully', () {
        // Act & Assert - Não deve lançar exceção
        expect(() => Bind.disposeByKey('non-existent-key'), returnsNormally);
      });

      test('should handle dispose by key for factory bind', () {
        // Arrange
        final bind = Bind.factory<TestCloseService>((i) => TestCloseService(), key: 'factory-key');
        Bind.register(bind);

        // Act
        Bind.disposeByKey('factory-key');

        // Assert
        expect(() => Bind.get<TestCloseService>(key: 'factory-key'), throwsA(isA<Exception>()));
      });
    });

    group('disposeByType(Type type) method', () {
      test('should call CleanBind.fromInstance when disposing by type', () {
        // Arrange
        final bind = Bind.singleton<TestCubitService>((i) => TestCubitService());
        Bind.register(bind);

        // Act
        Bind.disposeByType(TestCubitService);

        // Assert
        expect(TestCubitService.instanceCount, 0);
      });

      test('should remove bind from _bindsMap when disposing by type', () {
        // Arrange
        final bind = Bind.singleton<TestDisposableService>((i) => TestDisposableService());
        Bind.register(bind);

        // Act
        Bind.disposeByType(TestDisposableService);

        // Assert
        expect(() => Bind.get<TestDisposableService>(), throwsA(isA<Exception>()));
      });

      test('should remove all compatible keys when disposing by type', () {
        // Arrange
        final bind1 = Bind.singleton<TestServiceWithKey>((i) => TestServiceWithKey('test1'), key: 'key1');
        final bind2 = Bind.singleton<TestServiceWithKey>((i) => TestServiceWithKey('test2'), key: 'key2');
        Bind.register(bind1);
        Bind.register(bind2);

        // Act
        Bind.disposeByType(TestServiceWithKey);

        // Assert - Todas as keys devem ser removidas
        expect(() => Bind.get<TestServiceWithKey>(key: 'key1'), throwsA(isA<Exception>()));
        expect(() => Bind.get<TestServiceWithKey>(key: 'key2'), throwsA(isA<Exception>()));
      });

      test('should handle dispose of non-existent type gracefully', () {
        // Act & Assert - Não deve lançar exceção
        expect(() => Bind.disposeByType(TestDisposableService), returnsNormally);
      });
    });

    group('clearAll() method', () {
      test('should clear all binds and call cleanup', () {
        // Arrange
        final bind1 = Bind.singleton<TestDisposableService>((i) => TestDisposableService());
        final bind2 = Bind.singleton<TestCloseService>((i) => TestCloseService(), key: 'test-key');
        final bind3 = Bind.factory<TestNormalService>((i) => TestNormalService());

        Bind.register(bind1);
        Bind.register(bind2);
        Bind.register(bind3);

        // Act
        Bind.clearAll();

        // Assert - Todos os binds devem ser removidos
        expect(() => Bind.get<TestDisposableService>(), throwsA(isA<Exception>()));
        expect(() => Bind.get<TestCloseService>(), throwsA(isA<Exception>()));
        expect(() => Bind.get<TestCloseService>(key: 'test-key'), throwsA(isA<Exception>()));
        expect(() => Bind.get<TestNormalService>(), throwsA(isA<Exception>()));
      });

      test('should clear internal tracking maps', () {
        // Arrange
        final bind = Bind.singleton<TestDisposableService>((i) => TestDisposableService());
        Bind.register(bind);

        // Act
        Bind.clearAll();

        // Assert - Maps internos devem estar vazios
        expect(Bind.getAllKeys(), isEmpty);
      });

      test('should handle clearAll when no binds exist', () {
        // Act & Assert - Não deve lançar exceção
        expect(() => Bind.clearAll(), returnsNormally);
      });
    });

    group('Memory leak prevention', () {
      test('should properly cleanup multiple instances of same type', () {
        // Arrange
        final bind1 = Bind.singleton<TestDisposableService>((i) => TestDisposableService());
        final bind2 = Bind.singleton<TestDisposableService>((i) => TestDisposableService(), key: 'key1');
        final bind3 = Bind.singleton<TestDisposableService>((i) => TestDisposableService(), key: 'key2');

        Bind.register(bind1);
        Bind.register(bind2);
        Bind.register(bind3);

        // Act
        Bind.disposeByType(TestDisposableService);

        // Assert
        expect(TestDisposableService.instanceCount, 0);
        expect(() => Bind.get<TestDisposableService>(), throwsA(isA<Exception>()));
        expect(() => Bind.get<TestDisposableService>(key: 'key1'), throwsA(isA<Exception>()));
        expect(() => Bind.get<TestDisposableService>(key: 'key2'), throwsA(isA<Exception>()));
      });

      test('should not leave orphaned references after dispose', () {
        // Arrange
        final service = TestServiceWithKey('test');
        final bind = Bind.singleton<TestServiceWithKey>((i) => service, key: 'test-key');
        Bind.register(bind);

        // Act
        Bind.dispose<TestServiceWithKey>();

        // Assert - Verifica se não há referências órfãs
        expect(Bind.getAllKeys(), isEmpty);
        expect(service.disposed, true);
      });

      test('should handle mixed singleton and factory cleanup', () {
        // Arrange
        final singletonBind = Bind.singleton<TestDisposableService>((i) => TestDisposableService());
        final factoryBind = Bind.factory<TestCloseService>((i) => TestCloseService(), key: 'factory');

        Bind.register(singletonBind);
        Bind.register(factoryBind);

        // Act
        Bind.dispose<TestDisposableService>();
        Bind.disposeByKey('factory');

        // Assert
        expect(() => Bind.get<TestDisposableService>(), throwsA(isA<Exception>()));
        expect(() => Bind.get<TestCloseService>(key: 'factory'), throwsA(isA<Exception>()));
      });
    });

    group('CleanBind integration', () {
      test('should call CleanBind.fromInstance for disposable objects', () {
        // Arrange
        final service = TestDisposableService();
        final bind = Bind.singleton<TestDisposableService>((i) => service);
        Bind.register(bind);

        // Act
        Bind.dispose<TestDisposableService>();

        // Assert
        expect(service.disposed, true);
      });

      test('should call CleanBind.fromInstance for closeable objects', () {
        // Arrange
        final service = TestCloseService();
        final bind = Bind.singleton<TestCloseService>((i) => service);
        Bind.register(bind);

        // Act
        Bind.dispose<TestCloseService>();

        // Assert
        expect(service.closed, true);
      });

      test('should handle CleanBind gracefully for objects without cleanup methods', () {
        // Arrange
        final service = TestNormalService();
        final bind = Bind.singleton<TestNormalService>((i) => service);
        Bind.register(bind);

        // Act & Assert - Não deve lançar exceção
        expect(() => Bind.dispose<TestNormalService>(), returnsNormally);
      });
    });
  });
}
