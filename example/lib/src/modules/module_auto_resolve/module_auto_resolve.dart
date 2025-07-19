import 'dart:async';

import 'package:example/src/modules/home/home_module.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

import '../shared/shared_module.dart';

class AutoResolveModule extends Module {
  @override
  FutureOr<List<Module>> imports() {
    return [SharedModule()];
  }

  @override
  Future<List<Bind<Object>>> binds() async {
    await Future.delayed(const Duration(seconds: 2));
    return [
      Bind.singleton<C>((i) => C(i.get(), i.get())),
      Bind.singleton<B>((i) => B(i.get())),
      Bind.singleton<A>((i) => A(i.get())),
      Bind.singleton<D>((i) => D(i.get())),
    ];
  }

  @override
  List<ModularRoute> get routes {
    return [
      ChildRoute(
        '/',
        child: (context, state) => const Scaffold(
          body: Center(
            child: Text('Auto Resolve'),
          ),
        ),
      ),
    ];
  }
}

class A {
  final HomeService sharedService;
  A(this.sharedService);
}

class B {
  final A a;
  B(this.a);
}

class C {
  final B b;
  final A a;
  C(this.b, this.a);
}

class D {
  final C c;
  D(this.c);
}
