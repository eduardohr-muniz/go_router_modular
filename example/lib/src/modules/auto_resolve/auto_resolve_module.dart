import 'dart:async';

import 'package:example/src/modules/home/home_module.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AutoResolveModule extends Module {
  @override
  FutureOr<List<Bind<Object>>> binds() {
    return [
      Bind.factory<Z>((i) => Z(i.get<HomeService>())),
      Bind.factory<A>((i) => A(i.get<Z>())),
      Bind.factory<B>((i) => B(i.get<A>())),
      Bind.factory<C>((i) => C(i.get<B>())),
      Bind.factory<D>((i) => D(i.get<A>())),
    ];
  }

  @override
  List<ModularRoute> get routes => [
        ChildRoute('/',
            child: (context, args) => Material(
                  child: Placeholder(
                    child: Column(
                      children: [
                        Text('Auto Resolve: ${Modular.get<Z>().homeService.name}'),
                        Text('Auto Resolve: ${Modular.get<HomeService>().name}'),
                      ],
                    ),
                  ),
                )),
      ];
}

class A {
  final Z z;

  A(this.z);
}

class B {
  final A a;

  B(this.a);
}

class C {
  final B b;

  C(this.b);
}

class D {
  final A a;

  D(this.a);
}

class Z {
  final HomeService homeService;

  Z(this.homeService);
}
