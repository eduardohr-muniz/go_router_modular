import 'package:example/src/modules/user/presenters/user_name_page.dart';
import 'package:example/src/modules/user/presenters/user_page.dart';
import 'package:go_router_modular/go_router_modular.dart';

class UserModule extends Module {
  @override
  List<ChildRoute> get routes => [
        ChildRoute('/', name: "user", builder: (context, state, i) => const UserPage()),
        ChildRoute('/user_name/', name: "user_name", builder: (context, state, i) => const UserNamePage()),
      ];
}
