import 'dart:async';

import 'package:go_router_modular/go_router_modular.dart';

import 'shared_service.dart';

class SharedModule extends Module {
  // Controle de estado do módulo

  @override
  FutureOr<List<Bind<Object>>> binds() {
    return [
      Bind.singleton<SharedService>((i) => SharedService()),
    ];
  }

  @override
  void initState(Injector i) {}

  @override
  void dispose() {}
}
