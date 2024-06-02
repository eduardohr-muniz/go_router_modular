import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: Modular.routerConfig,
      title: 'Modular GoRoute Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}
