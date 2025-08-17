import 'dart:async';

import 'package:example/src/modules/shared/module_singleton.dart';
import 'package:example/src/modules/shared/test_controller.dart';
import 'package:example/src/modules/shared/shared_module.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'pages/home_page.dart';
import 'pages/demo_page.dart';

class HomeModule extends Module {
  @override
  FutureOr<List<Module>> imports() {
    return [SharedModule(), ModuleSingleton()];
  }

  @override
  FutureOr<List<Bind<Object>>> binds() {
    return [
      Bind.singleton((i) => HomeService()),
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
  void initState(Injector i) {
    TestController.instance.enterModule('HomeModule');
  }

  @override
  void dispose() {
    TestController.instance.exitModule('HomeModule');
  }
}

class HomeService {
  HomeService();

  get name => 'olá';

  void dispose() {}
}
