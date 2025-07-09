import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import '../shared/shared_module.dart';
import 'pages/home_page.dart';
import 'pages/demo_page.dart';

class HomeModule extends Module {
  @override
  List<Module> get imports {
    print('📦 [HOME_MODULE] Obtendo imports');
    return [SharedModule()];
  }

  @override
  List<Bind<Object>> get binds {
    print('📦 [HOME_MODULE] Obtendo binds');
    return [
      Bind.singleton<HomeService>((i) => HomeService()),
    ];
  }

  @override
  List<ModularRoute> get routes {
    print('🛣️ [HOME_MODULE] Obtendo rotas');
    return [
      ChildRoute(
        '/',
        child: (context, state) => const HomePage(),
      ),
      ChildRoute(
        '/demo',
        child: (context, state) => const DemoPage(),
      ),
    ];
  }

  @override
  void initState(Injector i) {
    print('🚀 [HOME_MODULE] initState chamado');
    super.initState(i);
    print('✅ [HOME_MODULE] HomeModule inicializado com sucesso');
  }

  @override
  void dispose() {
    print('🗑️ [HOME_MODULE] dispose chamado');
    super.dispose();
    print('✅ [HOME_MODULE] HomeModule disposto com sucesso');
  }
}

class HomeService {
  HomeService() {
    print('🏠 [HOME_SERVICE] HomeService criado');
  }

  void dispose() {
    print('🏠 [HOME_SERVICE] HomeService disposto');
  }
}
