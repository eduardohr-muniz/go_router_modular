import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import '../shared/shared_module.dart';
import 'auth_store.dart';
import 'pages/login_page.dart';
import 'pages/splash_page.dart';

class AuthModule extends Module {
  @override
  List<Module> get imports {
    print('📦 [AUTH_MODULE] Obtendo imports');
    return [SharedModule()];
  }

  @override
  List<Bind<Object>> get binds {
    print('📦 [AUTH_MODULE] Obtendo binds');
    return [Bind.singleton<AuthStore>((i) => AuthStore())];
  }

  @override
  List<ModularRoute> get routes {
    print('🛣️ [AUTH_MODULE] Obtendo rotas');
    return [
      ChildRoute(
        '/',
        child: (context, state) => const SplashPage(),
      ),
      ChildRoute(
        '/login',
        child: (context, state) => const LoginPage(),
      ),
    ];
  }

  @override
  void initState(Injector i) {
    print('🚀 [AUTH_MODULE] initState chamado');
    super.initState(i);
    print('✅ [AUTH_MODULE] AuthModule inicializado com sucesso');
  }

  @override
  void dispose() {
    print('🗑️ [AUTH_MODULE] dispose chamado');
    super.dispose();
    print('✅ [AUTH_MODULE] AuthModule disposto com sucesso');
  }
}
