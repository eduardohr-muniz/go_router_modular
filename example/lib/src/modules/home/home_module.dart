import 'package:example/src/modules/auth/auth_module.dart';
import 'package:example/src/modules/home/pages/home_page.dart';
import 'package:example/src/modules/user/aplication/teste.dart';
import 'package:example/src/modules/user/aplication/user_store.dart';
import 'package:example/src/modules/user/user_module.dart';
import 'package:go_router_modular/go_router_modular.dart';

class HomeModule extends Module {
  @override
  List<Bind<Object>> get binds => [
        Bind.singleton((i) => Teste()),
        Bind.singleton((i) => UserStore(i.get())),
      ];

  @override
  List<ModularRoute> get routes => [
        ChildRoute('/', name: "home", child: (context, state, i) => const HomePage()),
        ModuleRoute("/user", module: UserModule()),
      ];
}
