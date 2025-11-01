import 'dart:async';

import 'package:go_router_modular/go_router_modular.dart';

class ModuleSingleton extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<BindSingleton>((i) => BindSingleton());
  }
}

abstract interface class IBindSingleton {
  void printHash();
}

class BindSingleton implements IBindSingleton {
  @override
  void printHash() {
    print('BindSingleton hashcode: ${this.hashCode}');
  }
}
