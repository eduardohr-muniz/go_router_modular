import 'package:example_poc/src/modules/config/config_module.dart';
import 'package:example_poc/src/modules/home/home_module.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AppModule extends EventModule {
  @override
  List<ModularRoute> get routes => [
    ModuleRoute('/home', module: HomeModule()), // 👈 HomeModule
    ModuleRoute('/config', module: ConfigModule()), // 👈 ConfigModule
  ];

  @override
  void listen() {}
}
