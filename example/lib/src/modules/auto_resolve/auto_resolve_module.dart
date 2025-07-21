import 'dart:async';

import 'package:example/src/modules/home/home_module.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AutoResolveModule extends Module {
  @override
  FutureOr<List<Bind<Object>>> binds() {
    return [
      Bind.singleton((i) => Z(i.get())),
      Bind.singleton((i) => A(i.get())),
      Bind.singleton((i) => B(i.get())),
      Bind.singleton((i) => C(i.get())),
      Bind.singleton((i) => D(i.get())),
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
