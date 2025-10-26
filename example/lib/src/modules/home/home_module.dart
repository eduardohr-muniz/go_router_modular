import 'dart:async';

import 'package:example/src/modules/binds_by_key/binds_by_key_module.dart';
import 'package:example/src/modules/shared/test_controller.dart';
import 'package:example/src/modules/shared/shared_module.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'pages/home_page.dart';
import 'pages/demo_page.dart';

class HomeModule extends Module {
  @override
  FutureOr<List<Module>> imports() {
    return [SharedModule(), BindsByKeyModule()];
  }

  @override
  void binds(Injector i) {
    i.addLazySingleton(() => HomeService());
  }

  @override
  List<ModularRoute> get routes {
    return [
      // 🏠 Home Page - Herda fadeUpwards do AppModule
      ChildRoute(
        '/',
        child: (context, state) => const HomePage(),
      ),

      // 🎨 Demo Page - Transição específica slide da esquerda com rotação
      ChildRoute(
        '/demo',
        child: (context, state) => const DemoPage(),
        transition: GoTransitions.slide.toLeft.withRotation,
        duration: Duration(milliseconds: 600),
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
