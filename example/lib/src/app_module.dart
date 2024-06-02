import 'package:example/src/core/routes.dart';
import 'package:example/src/menu_module.dart';
import 'package:example/src/modules/auth/auth_module.dart';
import 'package:example/src/modules/user/user_module.dart';
import 'package:example/src/modules/z_she/home_shell/home_shell_module.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AppModule extends Module {
  // final rHomeShellModule = HomeShellModule();
  // @override
  // List<ModularRoute> get routes => [
  //       ModuleRoute("/teste", module: rHomeShellModule),
  //       // ModuleRoute("/user/", module: UserModule()),
  //     ];
  // @override
  // List<ModularRoute> get routes => [
  //       // ChildRoute(
  //       //   "/auth",
  //       //   child: (context, state, i) => const Text("Centre"),
  //       // ),
  //       ModuleRoute(Routes.home.moduleR, module: HomeModule()),
  //       // ModuleRoute("/user", module: UserModule()),
  //     ];

  @override
  List<ModularRoute> get routes => [
        // ModuleRoute(Routes.slpash.moduleR, module: AuthModule()),
        ModuleRoute(Routes.menu.moduleR, module: MenuModule()),
        ModuleRoute("/", module: HomeShellModule()),
        // ModuleRoute(Routes.order.moduleR, module: OrderModule()),
        // ModuleRoute(Routes.name.moduleR, module: UserModule()),
      ];
}
