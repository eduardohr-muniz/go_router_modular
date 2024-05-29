import 'package:example/src/modules/auth/auth_store.dart';
import 'package:example/src/modules/home/home_module.dart';
import 'package:example/src/modules/z_she/home_shell/home_shell_module.dart';
import 'package:example/src/modules/z_she/shell/pages/page_one.dart';
import 'package:example/src/modules/user/user_module.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AppModule extends Module {
  // final rHomeShellModule = HomeShellModule();
  // @override
  // List<ModularRoute> get routes => [
  //       ModuleRoute("/teste", module: rHomeShellModule),
  //       // ModuleRoute("/user/", module: UserModule()),
  //     ];
  @override
  List<ModularRoute> get routes => [
        // ChildRoute(
        //   "/auth",
        //   child: (context, state, i) => const Text("Centre"),
        // ),
        ModuleRoute("/", module: HomeModule()),
        // ModuleRoute("/user", module: UserModule()),
      ];
}
