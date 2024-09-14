import 'package:example/src/core/routes.dart';
import 'package:example/src/modules/auth/auth_store.dart';
import 'package:example/src/modules/auth/pages/login_page.dart';
import 'package:example/src/modules/auth/pages/splash_page.dart';

import 'package:go_router_modular/go_router_modular.dart';

class AuthModule extends Module {
  @override
  List<Bind<Object>> get binds => [
        Bind.singleton((i) => AuthStore()),
      ];
  @override
  List<ModularRoute> get routes => [
        ChildRoute(Routes.slpash.childR, name: 'auth', child: (context, state) => const SplashPage()),
        ChildRoute(Routes.login.childR, name: Routes.login.name, child: (context, state) => const LoginPage()),
      ];
}
