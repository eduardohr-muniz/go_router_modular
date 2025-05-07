import 'package:example/src/core/routes.dart';
import 'package:example/src/modules/auth/auth_module.dart';
import 'package:example/src/modules/user/user_module.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AppModule extends Module {
  @override
  List<ModularRoute> get routes => [
        ModuleRoute(Routes.authModule, module: AuthModule()),
        ModuleRoute(Routes.userModule, module: UserModule()),
      ];
}
