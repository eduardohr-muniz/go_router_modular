import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // Use `copyWith` para sobrescrever opções do router (ex.: observers)
      // reaproveitando tudo que foi passado em `Modular.configure(...)`.
      routerConfig: Modular.routerConfig.copyWith(
        observers: [],
      ),
      builder: (context, child) => ModularLoader.builder(context, child),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
        },
      ),
      title: 'Modular GoRoute Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}
