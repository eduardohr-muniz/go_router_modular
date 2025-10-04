import 'dart:async';

import 'package:go_router_modular/go_router_modular.dart';
import 'shared_service.dart';
import 'module_singleton.dart';

class SharedModule extends Module {
  @override
  FutureOr<List<Module>> imports() {
    return [ModuleSingleton()];
  }

  @override
  FutureOr<List<Bind<Object>>> binds() {
    return [
      Bind.factory((i) => SharedService()),
    ];
  }
}
