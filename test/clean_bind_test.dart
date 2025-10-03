import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/src/utils/clean_bind.dart';

// Classes de teste para diferentes cenários
class TestDisposable {
  bool disposed = false;
  void dispose() {
    disposed = true;
  }
}

class TestDisposableInterface implements Disposable {
  bool disposed = false;
  @override
  void dispose() {
    disposed = true;
  }
}

// Interface para testar
abstract class Disposable {
  void dispose();
}

class TestCubit {
  bool closed = false;
  void close() {
    closed = true;
  }
}

class TestBloc {
  bool closed = false;
  void close() {
    closed = true;
  }
}

class TestStreamController {
  bool closed = false;
  void close() {
    closed = true;
  }
}

class TestTimer {
  bool cancelled = false;
  void cancel() {
    cancelled = true;
  }
}

class TestNormalClass {
  // Sem métodos de cleanup
}

class TestCloseMethod {
  bool closed = false;
  void close() {
    closed = true;
  }
}

class TestDisposeMethod {
  bool disposed = false;
  void dispose() {
    disposed = true;
  }
}

class TestBothMethods {
  bool disposed = false;
  bool closed = false;

  void dispose() {
    disposed = true;
  }

  void close() {
    closed = true;
  }
}

void main() {
  group('CleanBind Tests', () {
    test('should detect and call dispose() method', () {
      final instance = TestDisposeMethod();
      final result = CleanBind.fromInstance(instance);

      expect(result, true);
      expect(instance.disposed, true);
    });

    test('should detect and call close() method', () {
      final instance = TestCloseMethod();
      final result = CleanBind.fromInstance(instance);

      expect(result, true);
      expect(instance.closed, true);
    });

    test('should detect Disposable interface and call dispose()', () {
      final instance = TestDisposableInterface();
      final result = CleanBind.fromInstance(instance);

      expect(result, true);
      expect(instance.disposed, true);
    });

    test('should detect Cubit and call close()', () {
      final instance = TestCubit();
      final result = CleanBind.fromInstance(instance);

      expect(result, true);
      expect(instance.closed, true);
    });

    test('should detect Bloc and call close()', () {
      final instance = TestBloc();
      final result = CleanBind.fromInstance(instance);

      expect(result, true);
      expect(instance.closed, true);
    });

    test('should detect StreamController and call close()', () {
      final instance = TestStreamController();
      final result = CleanBind.fromInstance(instance);

      expect(result, true);
      expect(instance.closed, true);
    });

    test('should detect Timer and call cancel()', () {
      final instance = TestTimer();
      final result = CleanBind.fromInstance(instance);

      expect(result, true);
      expect(instance.cancelled, true);
    });

    test('should return false for class without cleanup methods', () {
      final instance = TestNormalClass();
      final result = CleanBind.fromInstance(instance);

      expect(result, false);
    });

    test('should handle class with both dispose() and close() methods', () {
      final instance = TestBothMethods();
      final result = CleanBind.fromInstance(instance);

      expect(result, true);
      // Deve chamar dispose() primeiro (prioridade mais alta)
      expect(instance.disposed, true);
      expect(instance.closed, false);
    });

    test('should handle exceptions gracefully', () {
      // Teste com instância que pode causar exceção
      final result = CleanBind.fromInstance(null);
      expect(result, false);
    });

    test('should handle class that throws exception in dispose', () {
      final instance = _ExceptionDisposeClass();
      final result = CleanBind.fromInstance(instance);

      // Deve retornar false se dispose() lança exceção
      expect(result, false);
    });

    test('should handle class that throws exception in close', () {
      final instance = _ExceptionCloseClass();
      final result = CleanBind.fromInstance(instance);

      // Deve retornar false se close() lança exceção
      expect(result, false);
    });

    test('should test method detection through behavior', () {
      // Teste indireto do método hasMethod através do comportamento
      final disposeInstance = TestDisposeMethod();
      final closeInstance = TestCloseMethod();
      final normalInstance = TestNormalClass();

      // Testa se consegue detectar métodos através do comportamento
      expect(CleanBind.fromInstance(disposeInstance), true);
      expect(CleanBind.fromInstance(closeInstance), true);
      expect(CleanBind.fromInstance(normalInstance), false);
    });

    test('should test hasMethod directly', () {
      // Teste direto do método hasMethod
      final disposeInstance = TestDisposeMethod();
      final closeInstance = TestCloseMethod();
      final normalInstance = TestNormalClass();

      expect(CleanBind.hasMethod(disposeInstance, 'dispose'), true);
      expect(CleanBind.hasMethod(closeInstance, 'close'), true);
      expect(CleanBind.hasMethod(normalInstance, 'dispose'), false);
      expect(CleanBind.hasMethod(normalInstance, 'close'), false);
    });
  });
}

class _ExceptionDisposeClass {
  void dispose() {
    throw Exception('Dispose failed');
  }
}

class _ExceptionCloseClass {
  void close() {
    throw Exception('Close failed');
  }
}
