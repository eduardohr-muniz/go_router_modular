import 'dart:async';

import 'package:example_poc/src/modules/home/home_controller.dart';
import 'package:example_poc/src/modules/home/home_page.dart';
import 'package:go_router_modular/go_router_modular.dart';

class HomeModule extends Module {
  @override
  FutureOr<List<Bind<Object>>> binds() {
    return [Bind.singleton((i) => HomeController())];
  }

  @override
  List<ModularRoute> get routes => [ChildRoute('/', child: (context, state) => HomePage())];
}
