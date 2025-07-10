import 'dart:async';

import 'package:go_router_modular/go_router_modular.dart';
import '../shared/shared_module.dart';
import 'pages/home_page.dart';
import 'pages/demo_page.dart';

class HomeModule extends Module {
  // Controle de estado do módulo

  @override
  FutureOr<List<Module>> imports() {
    return [SharedModule()];
  }

  @override
  FutureOr<List<Bind<Object>>> binds() {
    return [
      Bind.singleton<HomeService>((i) => HomeService()),
    ];
  }

  @override
  List<ModularRoute> get routes {
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
  void initState(Injector i) {}

  @override
  void dispose() {}
}

class HomeService {
  HomeService();

  void dispose() {}
}
