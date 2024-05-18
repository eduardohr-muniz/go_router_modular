import 'package:example/src/modules/home/presenters/home_page.dart';
import 'package:example/src/modules/user/aplication/user_store.dart';
import 'package:go_router_modular/go_router_modular.dart';

class HomeModule extends Module {
  @override
  List<Bind<Object>> get binds => [
        Bind.singleton<UserStore>((i) => UserStore()),
      ];

  @override
  List<ChildRoute> get routes => [
        ChildRoute('/', name: "home", builder: (context, state, i) => const HomePage()),
      ];
}
