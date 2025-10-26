import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

// Simulating the user's code structure
abstract class IClient {
  void makeRequest();
}

class ClientDio implements IClient {
  final String baseUrl;
  ClientDio({required this.baseUrl});

  @override
  void makeRequest() {}
}

abstract class IAuthApi {
  void login();
}

class AuthApi implements IAuthApi {
  final IClient client;
  AuthApi({required this.client});

  @override
  void login() {}
}

class AuthEmailCubit {
  final IAuthApi authApi;
  AuthEmailCubit({required this.authApi});
}

class PaipBindKey {
  static const String paipApi = 'paip-api';
}

void main() {
  setUp(() {
    Bind.clearAll();
  });

  test('SHOULD FAIL: Reproduce the exact error from the logs', () {
    // This replicates the user's AppModule.binds:
    // i.addLazySingleton(() => ClientDio(baseOptions: PaipBaseOptions.paipApi), key: PaipBindKey.paipApi);
    // i.addLazySingleton(() => ClientDio(baseOptions: PaipBaseOptions.supabase));

    final clientDio1 = Bind.singleton<ClientDio>(
      (i) => ClientDio(baseUrl: 'paip-api'),
      key: PaipBindKey.paipApi,
    );

    final clientDio2 = Bind.singleton<ClientDio>(
      (i) => ClientDio(baseUrl: 'supabase'),
    );

    Bind.register(clientDio1);
    Bind.register(clientDio2);

    // This is what AuthEmailModule tries to do:
    // i.add<IAuthApi>(() => AuthApi(client: i.get<IClient>()));

    final authApiBind = Bind.singleton<IAuthApi>(
      (i) => AuthApi(client: i.get<IClient>()),
    );

    Bind.register(authApiBind);

    // This should FAIL with "Bind not found for type: IClient"
    // ⚠️ THIS TEST DOCUMENTS THE ERROR - IT SHOULD FAIL
    // This will throw because IClient is not registered
    expect(
      () => Bind.get<IAuthApi>(),
      throwsA(isA<GoRouterModularException>()),
      reason: 'Should throw error because IClient is not registered',
    );
  });

  test('SHOULD FAIL: Two ClientDio implementations but no IClient interface registered', () {
    // This is the EXACT scenario from the user's code:
    // AppModule has TWO implementations of ClientDio:
    //   1. One with key 'paip-api'
    //   2. One without key (default)
    // But NO IClient interface is registered
    // When AuthApi tries to get IClient, it will FAIL

    // Register first ClientDio with key
    final clientDio1 = Bind.singleton<ClientDio>(
      (i) => ClientDio(baseUrl: 'paip-api'),
      key: PaipBindKey.paipApi,
    );
    Bind.register(clientDio1);

    // Register second ClientDio without key
    final clientDio2 = Bind.singleton<ClientDio>(
      (i) => ClientDio(baseUrl: 'supabase'),
    );
    Bind.register(clientDio2);

    // Now try to register AuthApi that needs IClient
    final authApiBind = Bind.singleton<IAuthApi>(
      (i) => AuthApi(client: i.get<IClient>()), // This will FAIL because IClient is not registered
    );
    Bind.register(authApiBind);

    // This should FAIL because IClient is not registered
    // Even though we have two ClientDio implementations

    // This will throw because IClient is not registered
    expect(
      () => Bind.get<IAuthApi>(),
      throwsA(isA<GoRouterModularException>()),
      reason: 'Should throw error because IClient is not registered',
    );
  });
}
