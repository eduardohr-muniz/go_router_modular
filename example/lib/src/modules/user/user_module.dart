import 'dart:async';

import 'package:go_router_modular/go_router_modular.dart';
import '../shared/shared_module.dart';
import 'domain/repositories/user_repository.dart';
import 'presenters/user_page.dart';
import 'presenters/user_name_page.dart';

class UserModule extends Module {
  // Controle de estado do módulo

  @override
  FutureOr<List<Module>> imports() {
    return [SharedModule()];
  }

  @override
  Future<List<Bind<Object>>> binds() async {
    return [
      Bind.singleton<IUserRepository>((i) => UserRepository()),
    ];
  }

  @override
  List<ModularRoute> get routes {
    return [
      ChildRoute(
        '/',
        child: (context, state) => const UserPage(),
      ),
      ChildRoute(
        '/user_name/:name',
        child: (context, state) {
          final name = state.pathParameters['name'] ?? 'Usuário';
          return UserNamePage(userName: name);
        },
      ),
    ];
  }

  @override
  void initState(Injector i) {}

  @override
  void dispose() {}
}

class UserService {
  UserService();

  void dispose() {}
}
