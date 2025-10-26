import 'dart:developer';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

void main() {
  setUp(() async {
    await InjectionManager.instance.clearAllForTesting();
  });

  tearDown(() async {
    await InjectionManager.instance.clearAllForTesting();
  });

  test('⚠️ DOCUMENTAÇÃO: Sem tipagem explícita, i.add(MyClass.new) registra apenas a classe, NÃO a interface', () async {
    log('🔬 Emulando erro real do AuthEmailModule...', name: 'TEST');

    // AppModule vazio
    final appModule = AppModuleEmpty();
    await InjectionManager.instance.registerAppModule(appModule);

    // AuthEmailModule ERRADO (sem tipagem) - exatamente como no log real!
    final authModule = AuthEmailModuleErrado();
    await InjectionManager.instance.registerBindsModule(authModule);

    // Definir contexto
    InjectionManager.instance.setModuleContext(AuthEmailModuleErrado);

    log('❌ Este teste VAI FALHAR porque sem tipagem, IAuthApi não é registrada', name: 'TEST');

    // Isso FALHARÁ porque IAuthApi não foi registrada
    expect(
      () => Modular.get<AuthEmailCubit>(),
      throwsA(anything),
      reason: 'AuthEmailCubit precisa de IAuthApi, mas i.add(AuthApi.new) sem tipagem não registra a interface',
    );
  });
}

// ============ MÓDULOS ============

class AppModuleEmpty extends Module {
  @override
  void binds(Injector i) {
    // Vazio
  }
}

class AuthEmailModuleErrado extends Module {
  @override
  void binds(Injector i) {
    // ⚠️ ERRO: Sem tipagem, exatamente como no log real!
    // Isso registra como Object, não como IAuthApi
    i.add(AuthApi.new); // ❌ Deveria ser i.add<IAuthApi>(AuthApi.new)
    i.add(AuthEmailCubit.new);
  }
}

// ============ INTERFACES ============

abstract class IAuthApi {
  Future<void> login(String email, String password);
}

// ============ IMPLEMENTAÇÕES ============

class AuthApi implements IAuthApi {
  @override
  Future<void> login(String email, String password) async {
    log('Login: $email', name: 'AuthApi');
  }
}

class AuthEmailCubit {
  final IAuthApi authApi;

  AuthEmailCubit(this.authApi);

  Future<void> login(String email, String password) {
    return authApi.login(email, password);
  }
}
