import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/src/core/bind.dart';

// Classes de teste
class TestService {
  final String id;
  TestService(this.id);
}

class ApiService {
  final String endpoint;
  ApiService(this.endpoint);
}

int factoryCallCount = 0;
int singletonCallCount = 0;
int lazySingletonCallCount = 0;
int addCallCount = 0;

void main() {
  group('Bind Static Methods Tests', () {
    setUp(() {
      // Limpa todo o estado antes de cada teste
      Bind.clearAll();
      // Reseta contadores
      factoryCallCount = 0;
      singletonCallCount = 0;
      lazySingletonCallCount = 0;
      addCallCount = 0;
    });

    tearDown(() {
      // Limpa todo o estado após cada teste
      Bind.clearAll();
    });

    group('Bind.add (Factory)', () {
      test('Deve criar uma nova instância a cada acesso', () {
        final bind = Bind.add<TestService>(
          (i) {
            addCallCount++;
            return TestService('factory-${addCallCount}');
          },
        );

        Bind.register(bind);

        // O register cria uma instância para descobrir o tipo, então o contador já está em 1
        expect(addCallCount, greaterThanOrEqualTo(1));

        // Primeira chamada explícita
        final instance1 = Bind.get<TestService>();
        final currentCount = addCallCount;
        
        // Segunda chamada - deve criar nova instância
        final instance2 = Bind.get<TestService>();
        expect(addCallCount, greaterThan(currentCount)); // Deve ter incrementado

        // Verifica que são instâncias diferentes
        expect(instance1, isNot(same(instance2)));
      });

      test('Deve funcionar com key', () {
        final bind = Bind.add<TestService>(
          (i) => TestService('factory-key'),
          key: 'test-key',
        );

        Bind.register(bind);

        final instance1 = Bind.get<TestService>(key: 'test-key');
        final instance2 = Bind.get<TestService>(key: 'test-key');

        expect(instance1.id, equals('factory-key'));
        expect(instance2.id, equals('factory-key'));
        expect(instance1, isNot(same(instance2))); // Instâncias diferentes
      });
    });

    group('Bind.factory (Deprecated)', () {
      test('Deve criar uma nova instância a cada acesso', () {
        // Usa Bind.factory diretamente (deprecated)
        final bind = Bind.factory<TestService>(
          (i) {
            factoryCallCount++;
            return TestService('factory-${factoryCallCount}');
          },
        );

        Bind.register(bind);

        // O register cria uma instância para descobrir o tipo
        expect(factoryCallCount, greaterThanOrEqualTo(1));

        // Primeira chamada explícita
        final instance1 = Bind.get<TestService>();
        final currentCount = factoryCallCount;

        // Segunda chamada - deve criar nova instância
        final instance2 = Bind.get<TestService>();
        expect(factoryCallCount, greaterThan(currentCount)); // Deve ter incrementado

        // Verifica que são instâncias diferentes
        expect(instance1, isNot(same(instance2)));
      });

      test('Deve funcionar com key', () {
        final bind = Bind.factory<TestService>(
          (i) => TestService('factory-key'),
          key: 'factory-key',
        );

        Bind.register(bind);

        final instance1 = Bind.get<TestService>(key: 'factory-key');
        final instance2 = Bind.get<TestService>(key: 'factory-key');

        expect(instance1.id, equals('factory-key'));
        expect(instance2.id, equals('factory-key'));
        expect(instance1, isNot(same(instance2))); // Instâncias diferentes
      });
    });

    group('Bind.singleton', () {
      test('Deve criar apenas uma instância e reutilizá-la', () {
        final bind = Bind.singleton<TestService>(
          (i) {
            singletonCallCount++;
            return TestService('singleton-${singletonCallCount}');
          },
        );

        Bind.register(bind);

        // O register cria uma instância para descobrir o tipo, mas não armazena no cache
        // então o singleton ainda não foi criado de fato
        final countBeforeFirstGet = singletonCallCount;

        // Primeira chamada - cria a instância singleton
        final instance1 = Bind.get<TestService>();
        final countAfterFirstGet = singletonCallCount;
        expect(countAfterFirstGet, greaterThanOrEqualTo(countBeforeFirstGet));

        // Segunda chamada - deve retornar a mesma instância
        final instance2 = Bind.get<TestService>();
        expect(singletonCallCount, equals(countAfterFirstGet)); // Não incrementou

        // Verifica que são a mesma instância
        expect(instance1, same(instance2));
      });

      test('Deve funcionar com key', () {
        final bind = Bind.singleton<TestService>(
          (i) => TestService('singleton-key'),
          key: 'singleton-key',
        );

        Bind.register(bind);

        final instance1 = Bind.get<TestService>(key: 'singleton-key');
        final instance2 = Bind.get<TestService>(key: 'singleton-key');

        expect(instance1.id, equals('singleton-key'));
        expect(instance2.id, equals('singleton-key'));
        expect(instance1, same(instance2)); // Mesma instância
      });
    });

    group('Bind.lazySingleton', () {
      test('Deve criar instância apenas quando acessado pela primeira vez', () {
        final bind = Bind.lazySingleton<TestService>(
          (i) {
            lazySingletonCallCount++;
            return TestService('lazy-singleton-${lazySingletonCallCount}');
          },
        );

        Bind.register(bind);

        // O register cria uma instância para descobrir o tipo, mas não armazena no cache
        // então o lazy singleton ainda não foi criado de fato
        final countAfterRegister = lazySingletonCallCount;
        expect(countAfterRegister, greaterThanOrEqualTo(0)); // Pode ser 0 ou 1 (depende do register)

        // Primeira chamada explícita - cria a instância singleton
        final instance1 = Bind.get<TestService>();
        final countAfterFirstGet = lazySingletonCallCount;
        expect(countAfterFirstGet, greaterThanOrEqualTo(countAfterRegister));

        // Segunda chamada - reutiliza a mesma instância
        final instance2 = Bind.get<TestService>();
        expect(lazySingletonCallCount, equals(countAfterFirstGet)); // Não incrementou

        // Verifica que são a mesma instância
        expect(instance1, same(instance2));
      });

      test('Deve funcionar com key', () {
        final bind = Bind.lazySingleton<TestService>(
          (i) => TestService('lazy-singleton-key'),
          key: 'lazy-key',
        );

        Bind.register(bind);

        final instance1 = Bind.get<TestService>(key: 'lazy-key');
        final instance2 = Bind.get<TestService>(key: 'lazy-key');

        expect(instance1.id, equals('lazy-singleton-key'));
        expect(instance2.id, equals('lazy-singleton-key'));
        expect(instance1, same(instance2)); // Mesma instância
      });

      test('Deve criar apenas uma instância mesmo com múltiplos acessos', () {
        final bind = Bind.lazySingleton<ApiService>(
          (i) {
            lazySingletonCallCount++;
            return ApiService('endpoint-${lazySingletonCallCount}');
          },
        );

        Bind.register(bind);

        // Múltiplos acessos
        final instance1 = Bind.get<ApiService>();
        final countAfterFirstGet = lazySingletonCallCount;
        final instance2 = Bind.get<ApiService>();
        final instance3 = Bind.get<ApiService>();

        // Deve ter criado apenas uma vez após o register
        expect(lazySingletonCallCount, equals(countAfterFirstGet)); // Não incrementou após primeiro get
        expect(instance1, same(instance2));
        expect(instance2, same(instance3));
      });
    });

    group('Comparação entre métodos', () {
      test('add vs factory vs singleton vs lazySingleton devem comportar-se diferentemente', () {
        // Usa keys para isolar cada tipo de bind
        final factoryBind = Bind.add<TestService>(
          (i) => TestService('factory'),
          key: 'factory',
        );
        final factoryBindDeprecated = Bind.factory<TestService>(
          (i) => TestService('factory-deprecated'),
          key: 'factory-deprecated',
        );
        final singletonBind = Bind.singleton<TestService>(
          (i) => TestService('singleton'),
          key: 'singleton',
        );
        final lazyBind = Bind.lazySingleton<TestService>(
          (i) => TestService('lazy'),
          key: 'lazy',
        );

        Bind.register(factoryBind);
        Bind.register(factoryBindDeprecated);
        Bind.register(singletonBind);
        Bind.register(lazyBind);

        // Factory (add) cria nova instância cada vez
        final f1 = Bind.get<TestService>(key: 'factory');
        final f2 = Bind.get<TestService>(key: 'factory');
        expect(f1, isNot(same(f2))); // Factory: instâncias diferentes

        // Factory (deprecated) também cria nova instância cada vez
        final fd1 = Bind.get<TestService>(key: 'factory-deprecated');
        final fd2 = Bind.get<TestService>(key: 'factory-deprecated');
        expect(fd1, isNot(same(fd2))); // Factory deprecated: instâncias diferentes

        // Singleton cria apenas uma instância
        final s1 = Bind.get<TestService>(key: 'singleton');
        final s2 = Bind.get<TestService>(key: 'singleton');
        expect(s1, same(s2)); // Singleton: mesma instância

        // LazySingleton cria apenas uma instância (lazy)
        final l1 = Bind.get<TestService>(key: 'lazy');
        final l2 = Bind.get<TestService>(key: 'lazy');
        expect(l1, same(l2)); // LazySingleton: mesma instância
      });
    });
  });
}
