import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import '../shared/shared_module.dart';
import 'domain/repositories/user_repository.dart';
import 'presenters/user_page.dart';
import 'presenters/user_name_page.dart';

class UserModule extends Module {
  @override
  List<Module> get imports {
    print('📦 [USER_MODULE] Obtendo imports');
    return [SharedModule()];
  }

  @override
  List<Bind<Object>> get binds {
    print('📦 [USER_MODULE] Obtendo binds');
    return [
      Bind.singleton<IUserRepository>((i) => UserRepository()),
    ];
  }

  @override
  List<ModularRoute> get routes {
    print('🛣️ [USER_MODULE] Obtendo rotas');
    return [
      ChildRoute(
        '/',
        child: (context, state) => const UserPage(),
      ),
      ChildRoute(
        '/name/:name',
        child: (context, state) {
          final name = state.pathParameters['name'] ?? 'Usuário';
          return UserNamePage(userName: name);
        },
      ),
    ];
  }

  @override
  void initState(Injector i) {
    print('🚀 [USER_MODULE] initState chamado');
    super.initState(i);
    print('✅ [USER_MODULE] UserModule inicializado com sucesso');
  }

  @override
  void dispose() {
    print('🗑️ [USER_MODULE] dispose chamado');
    super.dispose();
    print('✅ [USER_MODULE] UserModule disposto com sucesso');
  }
}

class UserService {
  UserService() {
    print('👤 UserService criado');
  }

  void dispose() {
    print('👤 UserService disposto');
  }
}
