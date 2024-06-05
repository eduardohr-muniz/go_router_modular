import 'package:example/src/core/routes.dart';
import 'package:example/src/menu_module.dart';
import 'package:example/src/modules/home/home_module.dart';
import 'package:example/src/modules/user/aplication/teste.dart';
import 'package:example/src/modules/user/aplication/user_store.dart';
import 'package:example/src/modules/user/user_module.dart';
import 'package:example/src/modules/z_she/home_shell/home_shell_module.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AppModule extends Module {
  @override
  List<ModularRoute> get routes => [
        ModuleRoute(Routes.home.moduleR, module: HomeModule()),
        ModuleRoute(Routes.user.moduleR, module: UserModule()),
      ];
}
