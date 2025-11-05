import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/src/core/bind/bind.dart';
import 'package:go_router_modular/src/di/injector.dart';
import 'package:go_router_modular/src/exceptions/exception.dart';

// Classes de teste
class HttpClient {
  final String name;
  HttpClient(this.name);
}

class ApiClient {
  final String name;
  ApiClient(this.name);
}

void main() {
  group('Bind Key Isolation Tests', () {
    setUp(() {
      // Limpa todo o estado antes de cada teste
      Bind.clearAll();
    });

    tearDown(() {
      // Limpa todo o estado após cada teste
      Bind.clearAll();
    });

    group('Regra: Bind com key só pode ser chamado com key', () {
      test('Deve retornar bind correto quando busca com key', () {
        final injector = Injector();
        injector.startRegistering();

        // Registra HttpClient com key
        injector.addSingleton<HttpClient>(
          (i) => HttpClient('com-key'),
          key: 'http-client-key',
        );

        // Registra HttpClient sem key
        injector.addSingleton<HttpClient>(
          (i) => HttpClient('sem-key'),
        );

        final binds = injector.finishRegistering();
        for (final bind in binds) {
          Bind.register(bind);
        }

        // Busca com key deve retornar o bind com key
        final clientWithKey = Bind.get<HttpClient>(key: 'http-client-key');
        expect(clientWithKey.name, equals('com-key'));

        // Busca sem key deve retornar o bind sem key
        final clientWithoutKey = Bind.get<HttpClient>();
        expect(clientWithoutKey.name, equals('sem-key'));
      });

      test('Não deve conseguir pegar bind com key usando get sem key', () {
        final injector = Injector();
        injector.startRegistering();

        // Registra apenas HttpClient com key
        injector.addSingleton<HttpClient>(
          (i) => HttpClient('com-key'),
          key: 'http-client-key',
        );

        final binds = injector.finishRegistering();
        for (final bind in binds) {
          Bind.register(bind);
        }

        // Busca sem key deve lançar exceção (bind não encontrado)
        expect(
          () => Bind.get<HttpClient>(),
          throwsA(isA<GoRouterModularException>()),
        );

        // Busca com key deve funcionar
        final clientWithKey = Bind.get<HttpClient>(key: 'http-client-key');
        expect(clientWithKey.name, equals('com-key'));
      });
    });

    group('Regra: Bind sem key só pode ser chamado sem key', () {
      test('Deve retornar bind correto quando busca sem key', () {
        final injector = Injector();
        injector.startRegistering();

        // Registra ApiClient sem key
        injector.addSingleton<ApiClient>(
          (i) => ApiClient('sem-key'),
        );

        final binds = injector.finishRegistering();
        for (final bind in binds) {
          Bind.register(bind);
        }

        // Busca sem key deve retornar o bind sem key
        final clientWithoutKey = Bind.get<ApiClient>();
        expect(clientWithoutKey.name, equals('sem-key'));

        // Busca com key deve lançar exceção (bind não encontrado)
        expect(
          () => Bind.get<ApiClient>(key: 'api-client-key'),
          throwsA(isA<GoRouterModularException>()),
        );
      });

      test('Não deve conseguir pegar bind sem key usando get com key', () {
        final injector = Injector();
        injector.startRegistering();

        // Registra apenas ApiClient sem key
        injector.addSingleton<ApiClient>(
          (i) => ApiClient('sem-key'),
        );

        final binds = injector.finishRegistering();
        for (final bind in binds) {
          Bind.register(bind);
        }

        // Busca com key deve lançar exceção (bind não encontrado)
        expect(
          () => Bind.get<ApiClient>(key: 'api-client-key'),
          throwsA(isA<GoRouterModularException>()),
        );

        // Busca sem key deve funcionar
        final clientWithoutKey = Bind.get<ApiClient>();
        expect(clientWithoutKey.name, equals('sem-key'));
      });
    });

    group('Cenário: Múltiplos binds do mesmo tipo com e sem key', () {
      test('Deve isolar corretamente binds com e sem key', () {
        final injector = Injector();
        injector.startRegistering();

        // Registra HttpClient com key
        injector.addSingleton<HttpClient>(
          (i) => HttpClient('com-key-1'),
          key: 'key-1',
        );

        // Registra outro HttpClient com key diferente
        injector.addSingleton<HttpClient>(
          (i) => HttpClient('com-key-2'),
          key: 'key-2',
        );

        // Registra HttpClient sem key
        injector.addSingleton<HttpClient>(
          (i) => HttpClient('sem-key'),
        );

        final binds = injector.finishRegistering();
        for (final bind in binds) {
          Bind.register(bind);
        }

        // Busca com key-1 deve retornar o bind correto
        final client1 = Bind.get<HttpClient>(key: 'key-1');
        expect(client1.name, equals('com-key-1'));

        // Busca com key-2 deve retornar o bind correto
        final client2 = Bind.get<HttpClient>(key: 'key-2');
        expect(client2.name, equals('com-key-2'));

        // Busca sem key deve retornar o bind sem key
        final clientWithoutKey = Bind.get<HttpClient>();
        expect(clientWithoutKey.name, equals('sem-key'));

        // Verifica que são instâncias diferentes
        expect(client1, isNot(same(client2)));
        expect(client1, isNot(same(clientWithoutKey)));
        expect(client2, isNot(same(clientWithoutKey)));
      });

      test('Deve manter isolamento após múltiplas buscas', () {
        final injector = Injector();
        injector.startRegistering();

        // Registra HttpClient com key
        injector.addSingleton<HttpClient>(
          (i) => HttpClient('com-key'),
          key: 'http-key',
        );

        // Registra HttpClient sem key
        injector.addSingleton<HttpClient>(
          (i) => HttpClient('sem-key'),
        );

        final binds = injector.finishRegistering();
        for (final bind in binds) {
          Bind.register(bind);
        }

        // Múltiplas buscas devem retornar sempre o mesmo resultado
        for (int i = 0; i < 5; i++) {
          final clientWithKey = Bind.get<HttpClient>(key: 'http-key');
          expect(clientWithKey.name, equals('com-key'));

          final clientWithoutKey = Bind.get<HttpClient>();
          expect(clientWithoutKey.name, equals('sem-key'));

          // Verifica que são instâncias diferentes
          expect(clientWithKey, isNot(same(clientWithoutKey)));
        }
      });
    });

    group('Cenário: Ordem de registro não deve afetar isolamento', () {
      test('Deve funcionar mesmo registrando bind sem key primeiro', () {
        final injector = Injector();
        injector.startRegistering();

        // Registra HttpClient sem key primeiro
        injector.addSingleton<HttpClient>(
          (i) => HttpClient('sem-key'),
        );

        // Depois registra HttpClient com key
        injector.addSingleton<HttpClient>(
          (i) => HttpClient('com-key'),
          key: 'http-key',
        );

        final binds = injector.finishRegistering();
        for (final bind in binds) {
          Bind.register(bind);
        }

        // Busca sem key deve retornar o bind sem key
        final clientWithoutKey = Bind.get<HttpClient>();
        expect(clientWithoutKey.name, equals('sem-key'));

        // Busca com key deve retornar o bind com key
        final clientWithKey = Bind.get<HttpClient>(key: 'http-key');
        expect(clientWithKey.name, equals('com-key'));
      });

      test('Deve funcionar mesmo registrando bind com key primeiro', () {
        final injector = Injector();
        injector.startRegistering();

        // Registra HttpClient com key primeiro
        injector.addSingleton<HttpClient>(
          (i) => HttpClient('com-key'),
          key: 'http-key',
        );

        // Depois registra HttpClient sem key
        injector.addSingleton<HttpClient>(
          (i) => HttpClient('sem-key'),
        );

        final binds = injector.finishRegistering();
        for (final bind in binds) {
          Bind.register(bind);
        }

        // Busca com key deve retornar o bind com key
        final clientWithKey = Bind.get<HttpClient>(key: 'http-key');
        expect(clientWithKey.name, equals('com-key'));

        // Busca sem key deve retornar o bind sem key
        final clientWithoutKey = Bind.get<HttpClient>();
        expect(clientWithoutKey.name, equals('sem-key'));
      });
    });
  });
}
