import 'package:example/src/core/routes.dart';
import 'package:example/src/modules/shell/presenters/config_page.dart';
import 'package:example/src/modules/shell/presenters/home_page.dart';
import 'package:example/src/modules/shell/presenters/profile_page.dart';
import 'package:example/src/modules/shell/presenters/shell_page.dart';
import 'package:go_router_modular/go_router_modular.dart';

class ShellModule extends Module {
  @override
  List<ModularRoute> get routes => [
        ShellModularRoute(
          builder: (context, state, child) => ShellPage(child: child),
          routes: [
            ChildRoute(
              Routes.shellHomeRelative,
              child: (context, state) => const HomePage(),
            ),
            ChildRoute(
              Routes.shellConfigRelative,
              child: (context, state) => const ConfigPage(),
            ),
            ChildRoute(
              Routes.shellProfileRelative,
              child: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ];
}
