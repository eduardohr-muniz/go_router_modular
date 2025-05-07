import 'package:example/src/core/routes.dart';
import 'package:example/src/modules/user/domain/repositories/user_repository.dart';
import 'package:example/src/modules/user/pages/user_name_page.dart';
import 'package:example/src/modules/user/pages/user_page.dart';
import 'package:go_router_modular/go_router_modular.dart';

class UserModule extends Module {
  @override
  List<Bind<Object>> get binds => [
        Bind.lazySingleton((i) => UserRepository()),
      ];
  @override
  List<ModularRoute> get routes => [
        ChildRoute(Routes.userRelative,
            child: (context, state) => UserPage(
                  userRepository: Modular.get(),
                )),
        ChildRoute(
          Routes.userNameRelative,
          child: (context, state) =>
              UserNamePage(name: state.pathParameters[Routes.userNameParam]!),
        )
      ];
}
