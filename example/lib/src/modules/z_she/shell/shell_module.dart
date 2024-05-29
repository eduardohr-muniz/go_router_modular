import 'package:example/src/modules/z_she/shell/pages/page_one.dart';
import 'package:example/src/modules/z_she/shell/pages/page_two.dart';
import 'package:go_router_modular/go_router_modular.dart';

class ShellModule extends Module {
  @override
  // TODO: implement routes
  List<ModularRoute> get routes => [
        ChildRoute(
          "/",
          child: (context, state, i) => const PageOne(),
        ),
        ChildRoute(
          "/two",
          child: (context, state, i) => const PageTwo(),
        )
      ];
}
