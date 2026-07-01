import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/src/di/bind.dart';
import 'package:go_router_modular/src/di/injector.dart';

/// Regression: a module registers a keyed singleton **and** an unkeyed
/// singleton for the same interface (e.g. two HTTP clients sharing
/// `IClient` with different base URLs). `Injector.get<IClient>()` (no key)
/// must resolve the unkeyed bind, while `Injector.get<IClient>(key: 'x')`
/// resolves the keyed one.
///
/// The previous refactor stored the **first** registered bind under
/// `bindsMap[type]` regardless of its key, so when the keyed bind was
/// declared first the unkeyed slot stayed pointing at it and unkeyed
/// lookups failed (`BindLocator._searchByType` skips keyed slots).
abstract interface class IClient {
  String get baseUrl;
}

class ClientDio implements IClient {
  @override
  final String baseUrl;
  ClientDio(this.baseUrl);
}

void main() {
  final injector = Injector();

  setUp(Bind.clearAll);
  tearDown(Bind.clearAll);

  test('keyed declared first: unkeyed bind still resolves via Injector.get<IClient>()', () {
    injector.startRegistering();
    injector.addSingleton<IClient>((i) => ClientDio('https://paip-api.example'), key: 'paip-api');
    injector.addSingleton<IClient>((i) => ClientDio('https://default.example'));
    final binds = injector.finishRegistering();

    Bind.registerBatch(binds);
    Bind.commitBatch(injector);

    final unkeyed = Bind.get<IClient>();
    expect(unkeyed.baseUrl, 'https://default.example');

    final keyed = Bind.get<IClient>(key: 'paip-api');
    expect(keyed.baseUrl, 'https://paip-api.example');
  });

  test('unkeyed declared first: same expectation holds', () {
    injector.startRegistering();
    injector.addSingleton<IClient>((i) => ClientDio('https://default.example'));
    injector.addSingleton<IClient>((i) => ClientDio('https://paip-api.example'), key: 'paip-api');
    final binds = injector.finishRegistering();

    Bind.registerBatch(binds);
    Bind.commitBatch(injector);

    expect(Bind.get<IClient>().baseUrl, 'https://default.example');
    expect(Bind.get<IClient>(key: 'paip-api').baseUrl, 'https://paip-api.example');
  });

  test('downstream factory consuming a keyed dependency works after commit', () {
    injector.startRegistering();
    injector.addSingleton<IClient>((i) => ClientDio('https://paip-api.example'), key: 'paip-api');
    injector.addSingleton<IClient>((i) => ClientDio('https://default.example'));
    final upstream = injector.finishRegistering();
    Bind.registerBatch(upstream);
    Bind.commitBatch(injector);

    injector.startRegistering();
    injector.addSingleton((i) => _AuthApi(i.get<IClient>(key: 'paip-api')));
    final downstream = injector.finishRegistering();
    Bind.registerBatch(downstream);
    Bind.commitBatch(injector);

    final api = Bind.get<_AuthApi>();
    expect(api.client.baseUrl, 'https://paip-api.example');
  });
}

class _AuthApi {
  final IClient client;
  _AuthApi(this.client);
}
