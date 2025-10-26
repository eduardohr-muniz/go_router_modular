import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

// Mocks
abstract class IClient {}

class Client implements IClient {}

abstract class IAuthApi {}

class AuthApi implements IAuthApi {
  final IClient client;
  AuthApi({required this.client});
}

class AuthEmailCubit {
  final IAuthApi authApi;
  AuthEmailCubit({required this.authApi});
}

class AppModule extends EventModule {
  @override
  FutureBinds binds(Injector i) {
    i.addLazySingleton<IClient>(Client.new);
  }

  @override
  List<ModularRoute> get routes => [];

  @override
  void listen() {}
}

class AuthEmailModule extends EventModule {
  @override
  FutureBinds binds(Injector i) {
    // Usar lambda para passar dependências manualmente
    i.add<IAuthApi>(() => AuthApi(client: i.get<IClient>()));
    i.addLazySingleton<AuthEmailCubit>(() => AuthEmailCubit(authApi: i.get<IAuthApi>()));
  }

  @override
  List<ModularRoute> get routes => [];

  @override
  void listen() {}
}

void main() {
  group('AuthEmailCubit Test', () {
    tearDown(() {
      InjectionManager.instance.clearAllForTesting();
    });

    test('Deve resolver AuthEmailCubit após registrar AppModule e AuthEmailModule usando .new', () async {
      // 1. Registrar AppModule
      final appModule = AppModule();
      await InjectionManager.instance.registerAppModule(appModule);
      await InjectionManager.instance.registerBindsModule(appModule);

      // 2. Registrar AuthEmailModule
      final authModule = AuthEmailModule();
      await InjectionManager.instance.registerBindsModule(authModule);

      // 3. Definir contexto para AuthEmailModule
      InjectionManager.instance.setModuleContext(AuthEmailModule);

      // 4. Tentar obter AuthEmailCubit
      final cubit = Modular.get<AuthEmailCubit>();

      expect(cubit, isNotNull);
      expect(cubit.authApi, isNotNull);
    });

    test('Deve funcionar com i.addLazySingleton(MyClass.new) - sem dependências', () async {
      final appModule = AppModule();
      await InjectionManager.instance.registerAppModule(appModule);
      await InjectionManager.instance.registerBindsModule(appModule);

      final client = Modular.get<IClient>();
      expect(client, isNotNull);
      expect(client, isA<Client>());
    });
  });
}
