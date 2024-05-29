import 'package:example/src/modules/user/aplication/teste.dart';
import 'package:example/src/modules/user/aplication/user_store.dart';
import 'package:example/src/modules/user/presenters/user_name_page.dart';
import 'package:example/src/modules/user/presenters/user_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class UserModule extends Module {
  @override
  List<Module> get imports => [];
  @override
  List<Bind<Object>> get binds => [Bind.singleton((i) => Teste()), Bind.singleton((i) => UserStore(i.get()))];
  @override
  List<ModularRoute> get routes => [
        ChildRoute('/', child: (context, state, i) => const UserPage()),
        ChildRoute('/user_name/:name',
            child: (context, state, i) => UserNamePage(name: state.pathParameters['name'] ?? "teste"), pageTransition: PageTransition.rotation),
        // ModuleRoute("/teste", module: TesteModule()),
      ];
  // @override
  // List<ModuleRoute> get routes => [
  //
  //     ];
}

class TesteModule extends Module {
  @override
  List<ModularRoute> get routes => [
        ChildRoute(
          "/",
          child: (context, state, i) => Scaffold(
              appBar: AppBar(
                leading: const BackButton(),
              ),
              body: Column(
                children: [
                  const Text("Centre"),
                  ElevatedButton(
                      onPressed: () {
                        context.push('/user/teste/p');
                      },
                      child: const Text("Go User")),
                ],
              )),
        ),
        ChildRoute(
          '/p',
          name: "teste",
          child: (context, state, i) => Scaffold(
              appBar: AppBar(
                leading: const BackButton(),
              ),
              body: const Text("Centre")),
        ),
      ];
}
