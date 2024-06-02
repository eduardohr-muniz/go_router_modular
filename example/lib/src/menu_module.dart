import 'package:example/src/core/routes.dart';
import 'package:example/src/modules/auth/auth_module.dart';
import 'package:flutter/material.dart';

import 'package:go_router_modular/go_router_modular.dart';

class MenuModule extends Module {
  @override
  List<ModularRoute> get routes => [
        ChildRoute(Routes.menu.childR,
            child: (context, state, i) => PageMenu(
                  param: state.pathParameters['establishment_id']!,
                )),
        // ChildRoute(Routes.cartProduct.childR,
        //     child: (context, state, i) =>
        //         PageTeste(state.pathParameters[Routes.cartProduct.params![0]]!, productId: state.pathParameters[Routes.cartProduct.params![1]])),
        // ChildRoute(Routes.cart.childR, child: (context, state, i) => const PageTeste("cart")),
        ChildRoute(Routes.paymentQrcode.childR, child: (context, state, i) => PageTeste(state.pathParameters['teste']!)),
      ];
}

class PageMenu extends StatelessWidget {
  final String param;
  const PageMenu({
    super.key,
    this.param = '',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(param),
      ),
      body: Container(
        child: ElevatedButton(
            onPressed: () {
              context.push(Routes.paymentQrcode.route);
            },
            child: const Text("Page Menu")),
      ),
    );
  }
}
