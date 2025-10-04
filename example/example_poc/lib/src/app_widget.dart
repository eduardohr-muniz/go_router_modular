import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ModularApp.router(
      title: 'GoRouter Modular Demo',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
    );
  }
}
