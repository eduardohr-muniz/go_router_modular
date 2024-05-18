import 'package:example/src/modules/home/home_module.dart';
import 'package:example/src/modules/user/user_module.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AppModule extends Module {
  @override
  List<ModuleRoute> get moduleRoutes => [
        ModuleRoute("/", module: HomeModule()),
        ModuleRoute("/user/", module: UserModule()),
      ];
}
