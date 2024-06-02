import 'package:example/src/core/routes.dart';
import 'package:example/src/modules/auth/auth_store.dart';
import 'package:example/src/modules/user/aplication/teste.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AuthModule extends Module {
  @override
  List<ModularRoute> get routes => [
        ChildRoute(Routes.slpash.childR, child: (context, state, i) => const PageTeste("Splash")),
        ChildRoute(Routes.login.childR, child: (context, state, i) => const PageTeste("Login")),
      ];
}

class PageTeste extends StatelessWidget {
  final String label;
  final String? productId;

  const PageTeste(this.label, {this.productId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(label + (productId ?? "")),
      ),
      body: Container(
        child: const Text("Olá"),
      ),
    );
  }
}
