import 'package:example/src/modules/z_she/home_shell/pages/home_shell_page.dart';
import 'package:example/src/modules/z_she/shell/pages/page_one.dart';
import 'package:example/src/modules/z_she/shell/pages/page_three.dart';
import 'package:example/src/modules/z_she/shell/pages/page_two.dart';
import 'package:example/src/modules/user/aplication/teste.dart';
import 'package:example/src/modules/user/aplication/user_store.dart';
import 'package:example/src/modules/user/user_module.dart';
import 'package:go_router_modular/go_router_modular.dart';

class HomeShellModule extends Module {
  @override
  List<Bind<Object>> get binds => [
        Bind.singleton((i) => Teste()),
        Bind.singleton((i) => UserStore(i.get())),
      ];
  @override
  List<ModularRoute> get routes => [
        ShellModularRoute(builder: (context, state, child) => HomeShellPage(shellChild: child), routes: [
          ChildRoute("/", child: (context, state, i) => const PageOne()),
          ChildRoute("/two", child: (context, state, i) => const PageTwo()),
          ChildRoute("/three", child: (context, state, i) => const PageThree()),
          ModuleRoute("/user", module: UserModule()),
        ])
      ];
}
