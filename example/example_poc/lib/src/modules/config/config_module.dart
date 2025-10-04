import 'dart:async';

import 'package:example_poc/src/modules/config/config_controller.dart';
import 'package:example_poc/src/modules/config/config_page.dart';
import 'package:go_router_modular/go_router_modular.dart';

class ConfigModule extends Module {
  @override
  FutureOr<List<Bind<Object>>> binds() {
    return [Bind.singleton((i) => ConfigController())];
  }

  @override
  List<ModularRoute> get routes => [ChildRoute('/', child: (context, state) => ConfigPage())];
}
