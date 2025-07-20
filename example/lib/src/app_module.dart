import 'dart:async';

import 'package:example/src/modules/injector_error/injector_error.dart';
import 'package:example/src/modules/module_auto_resolve/module_auto_resolve.dart';
import 'package:go_router_modular/go_router_modular.dart';

import 'modules/auth/auth_module.dart';
import 'modules/home/home_module.dart';
import 'modules/shared/shared_module.dart';
import 'modules/shell_example/shell_module.dart';
import 'modules/user/user_module.dart';

class AppModule extends Module {
  List<Module> get _staticImports => [SharedModule()];
  List<Bind<Object>> get _staticBinds => [
        Bind.factory<AppService>((i) => AppService()),
      ];
  List<ModularRoute> get _staticRoutes => [
        ModuleRoute('/', module: HomeModule()),
        ModuleRoute('/auth', module: AuthModule()),
        ModuleRoute('/user', module: UserModule()),
        ModuleRoute('/shell', module: ShellExampleModule()),
        ModuleRoute('/injector-error', module: InjectorErrorModule()),
        ModuleRoute('/auto-resolve', module: AutoResolveModule()),
      ];

  @override
  FutureOr<List<Module>> imports() {
    return _staticImports;
  }

  @override
  List<Bind<Object>> binds() {
    return _staticBinds;
  }

  @override
  List<ModularRoute> get routes {
    return _staticRoutes;
  }
}

class AppService {
  void dispose() {}
}
