import 'package:example/src/core/routes.dart';
import 'package:example/src/modules/home/pages/home_page.dart';
import 'package:go_router_modular/go_router_modular.dart';

class HomeModule extends Module {
  @override
  List<ModularRoute> get routes => [
        ChildRoute(Routes.home.childR, child: (context, state, i) => const HomePage(), pageTransition: PageTransition.slideRight),
        // ModuleRoute(Routes.user.moduleR, module: UserModule()),
      ];
}
