import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'modules/auth/auth_module.dart';
import 'modules/user/user_module.dart';
import 'modules/shared/shared_module.dart';
import 'modules/home/home_module.dart';

class AppModule extends Module {
  @override
  List<Module> get imports {
    print('📦 [APP_MODULE] Obtendo imports');
    return [SharedModule()];
  }

  @override
  List<Bind<Object>> get binds {
    print('📦 [APP_MODULE] Obtendo binds');
    return [
      Bind.singleton<AppService>((i) => AppService()),
    ];
  }

  @override
  List<ModularRoute> get routes {
    print('🛣️ [APP_MODULE] Obtendo rotas');
    return [
      ModuleRoute(
        '/auth',
        module: AuthModule(),
      ),
      ModuleRoute(
        '/user',
        module: UserModule(),
      ),
      ModuleRoute(
        '/',
        module: HomeModule(),
      ),
    ];
  }

  @override
  void initState(Injector i) {
    print('🚀 [APP_MODULE] initState chamado');
    super.initState(i);
    print('✅ [APP_MODULE] AppModule inicializado com sucesso');
  }

  @override
  void dispose() {
    print('🗑️ [APP_MODULE] dispose chamado');
    super.dispose();
    print('✅ [APP_MODULE] AppModule disposto com sucesso');
  }
}

class AppService {
  AppService() {
    print('🏠 [APP_SERVICE] AppService criado');
  }

  void dispose() {
    print('🏠 [APP_SERVICE] AppService disposto');
  }
}
