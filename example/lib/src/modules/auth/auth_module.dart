import 'package:example/src/core/routes.dart';
import 'package:example/src/modules/auth/viewmodels/auth_viewmodel.dart';
import 'package:example/src/modules/auth/pages/login_page.dart';
import 'package:example/src/modules/auth/pages/splash_page.dart';

import 'package:go_router_modular/go_router_modular.dart';

class AuthModule extends Module {
  @override
  List<Bind<Object>> get binds => [
        Bind.singleton((i) => AuthViewmodel()),
      ];
  @override
  List<ModularRoute> get routes => [
        ChildRoute(Routes.splashRelative,
            child: (context, state) => const SplashPage()),
        ChildRoute(Routes.loginRelative,
            child: (context, state) => const LoginPage()),
      ];
}
