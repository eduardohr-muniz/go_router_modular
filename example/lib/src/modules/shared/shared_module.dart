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
  void binds(Injector i) {
    i.add(() => SharedService());
  }
}
