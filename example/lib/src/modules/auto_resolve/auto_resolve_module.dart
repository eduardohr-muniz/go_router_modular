import 'dart:async';

import 'package:example/src/modules/home/home_module.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AutoResolveModule extends Module {
  @override
  FutureOr<List<Bind<Object>>> binds() {
    return [
      Bind.singleton((i) => HomeService()),
      Bind.factory<Z>((i) => Z(i.get<HomeService>())),
      Bind.factory<A>((i) => A(i.get<Z>())),
      Bind.factory<B>((i) => B(i.get<A>())),
      Bind.factory<C>((i) => C(i.get<B>())),
      Bind.factory<D>((i) => D(i.get<A>())),
    ];
  }

  @override
  List<ModularRoute> get routes => [
        ChildRoute('/', child: (context, args) => const AutoResolveModuleWidget()),
      ];
}

class AutoResolveModuleWidget extends StatelessWidget {
  const AutoResolveModuleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Resolve'),
      ),
      body: Placeholder(
        child: Column(
          children: [
            Text('Auto Resolve: ${Modular.get<Z>().homeService.name}'),
            ElevatedButton(
                onPressed: () {
                  print(Modular.get<Z>().homeService.name);
                },
                child: const Text('Olá'))
            // Text('Auto Resolve: ${Modular.get<HomeService>().name}'),
          ],
        ),
      ),
    );
  }
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
