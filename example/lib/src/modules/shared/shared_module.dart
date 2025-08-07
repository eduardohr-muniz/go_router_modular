import 'dart:async';

import 'package:go_router_modular/go_router_modular.dart';
import 'shared_service.dart';

class SharedModule extends Module {
  @override
  FutureOr<List<Bind<Object>>> binds() {
    return [
      Bind.factory((i) => SharedService()),
    ];
  }
}
