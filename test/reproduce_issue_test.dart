import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'dart:async';

/// Issue: qualquer código adicionado na criação de uma classe registrada como
/// bind é executado várias vezes, mesmo sem usar import.
///
/// Exemplo reportado:
/// ```dart
/// AuthBloc(this.client) {
///   print('Teste');
/// }
///
/// class AppModule extends Module {
///   @override
///   FutureOr<void> binds(Injector i) {
///     i.addLazySingleton((i) => AuthBloc(i.get()));
///   }
/// ```
/// O "Teste" era impresso 4 vezes no console.
///
/// Causa raiz: vários métodos internos (como _mapBindsToIdentifiers,
/// _logRegisteredBinds, _validateModuleBinds) chamavam bind.factoryFunction()
/// ao invés de reusar a instância já cacheada (bind.cachedInstance).
///
/// Fix: usar bind.cachedInstance ?? bind.factoryFunction() em todos esses métodos.

class HttpClient {
  static int constructorCalls = 0;
  HttpClient() {
    constructorCalls++;
  }
}

class AuthBloc {
  static int constructorCalls = 0;
  final HttpClient client;

  AuthBloc(this.client) {
    constructorCalls++;
  }
}

// ======================== MÓDULO DE TESTE ========================

class AppModuleIssue extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addLazySingleton((i) => HttpClient());
    i.addLazySingleton((i) => AuthBloc(i.get()));
  }

  @override
  List<ModularRoute> get routes => [
        ChildRoute('/', child: (context, state) => const SizedBox()),
      ];
}

void main() {
  group('Issue: bind constructor chamado múltiplas vezes', () {
    test(
      'addLazySingleton: construtor deve ser chamado apenas 1 vez durante registro',
      () async {
        AuthBloc.constructorCalls = 0;
        HttpClient.constructorCalls = 0;

        final module = AppModuleIssue();
        await InjectionManager.instance.registerAppModule(module);

        // Antes do fix: AuthBloc.constructorCalls era 2 (sem debugLog) ou 4 (com debugLog)
        expect(AuthBloc.constructorCalls, 1, reason: 'addLazySingleton não deve chamar o construtor múltiplas vezes');
        expect(HttpClient.constructorCalls, 1, reason: 'Dependência HttpClient também não deve ser criada múltiplas vezes');

        // Deve retornar a mesma instância (singleton)
        final instance1 = Injector().get<AuthBloc>();
        final instance2 = Injector().get<AuthBloc>();
        expect(identical(instance1, instance2), isTrue, reason: 'lazySingleton deve retornar a mesma instância');
        expect(AuthBloc.constructorCalls, 1, reason: 'get() não deve criar nova instância para singleton já cacheado');
      },
    );

    test(
      'Instanciação isolada via registerBatch + commitBatch: construtor chamado 1 vez',
      () async {
        AuthBloc.constructorCalls = 0;
        HttpClient.constructorCalls = 0;
        Bind.clearAll();

        final injector = Injector();
        injector.startRegistering();
        injector.addLazySingleton((i) => HttpClient());
        injector.addLazySingleton((i) => AuthBloc(i.get()));
        final moduleBinds = injector.finishRegistering();

        expect(AuthBloc.constructorCalls, 0);
        expect(HttpClient.constructorCalls, 0);

        Bind.registerBatch(moduleBinds);
        Bind.commitBatch(injector);

        // commitBatch materializes singletons (eager and lazy) so the
        // discovered runtimeType is registered in `bindsMap`, keeping
        // `Injector.get<Interface>()` resolution intact.
        expect(AuthBloc.constructorCalls, 1);
        expect(HttpClient.constructorCalls, 1);

        for (final bind in moduleBinds) {
          expect(bind.cachedInstance, isNotNull, reason: 'cachedInstance deve ser setada após commitBatch para singleton');
        }

        for (final bind in moduleBinds) {
          final instance = bind.cachedInstance ?? bind.factoryFunction(injector);
          expect(instance, isNotNull);
        }

        expect(AuthBloc.constructorCalls, 1, reason: 'cachedInstance deve evitar chamadas extras à factory');
        expect(HttpClient.constructorCalls, 1, reason: 'cachedInstance deve evitar chamadas extras à factory');
      },
    );
  });
}
