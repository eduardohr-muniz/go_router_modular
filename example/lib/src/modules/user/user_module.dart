import 'package:example/src/core/routes.dart';
import 'package:example/src/modules/user/domain/repositories/user_repository.dart';
import 'package:example/src/modules/user/presenters/user_name_page.dart';
import 'package:example/src/modules/user/presenters/user_page.dart';
import 'package:go_router_modular/go_router_modular.dart';

class UserModule extends Module {
  @override
  List<Bind<Object>> get binds => [
        Bind.singleton((i) => UserRepository()),
      ];
  @override
  List<ModularRoute> get routes => [
        ChildRoute(Routes.user.childR, name: Routes.user.name, child: (context, state) => const UserPage()),
        ChildRoute(
          Routes.userName.childR,
          name: Routes.userName.name,
          child: (context, state) => UserNamePage(name: state.pathParameters['name']!),
        )
      ];
}
