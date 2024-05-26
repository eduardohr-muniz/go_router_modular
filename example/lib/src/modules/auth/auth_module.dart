import 'package:example/src/modules/auth/auth_store.dart';
import 'package:example/src/modules/user/aplication/teste.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AuthModule extends Module {
  @override
  List<Bind<Object>> get binds => [
        Bind.singleton((i) => Teste()),
        Bind.singleton((i) => AuthStore()),
      ];
}
