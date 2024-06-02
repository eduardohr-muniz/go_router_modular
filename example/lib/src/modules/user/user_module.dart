// import 'package:example/src/modules/user/aplication/teste.dart';
// import 'package:example/src/modules/user/aplication/user_store.dart';
// import 'package:example/src/modules/user/presenters/user_name_page.dart';
// import 'package:example/src/modules/user/presenters/user_page.dart';
// import 'package:example/src/routes.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router_modular/go_router_modular.dart';

// class UserModule extends Module {
//   @override
//   List<Module> get imports => [];
//   @override
//   List<Bind<Object>> get binds => [
//         Bind.singleton((i) => UserStore(i.get())),
//         Bind.factory((i) => Teste()),
//       ];
//   @override
//   List<ModularRoute> get routes => [
//         ChildRoute(Routes.user.childR, child: (context, state, i) => const UserPage(), pageTransition: PageTransition.slideRight),
//         ChildRoute(Routes.userName.childR,
//             child: (context, state, i) => UserNamePage(name: state.pathParameters['name']!), pageTransition: PageTransition.slideRight),
//         // ModuleRoute("/teste", module: TesteModule()),
//       ];
// }

// class TesteModule extends Module {
//   @override
//   List<ModularRoute> get routes => [
//         ChildRoute("/",
//             child: (context, state, i) => Scaffold(
//                 appBar: AppBar(
//                   leading: const BackButton(),
//                 ),
//                 body: Column(
//                   children: [
//                     const Text("Centre"),
//                     ElevatedButton(
//                         onPressed: () {
//                           context.push('/user/teste/p');
//                         },
//                         child: const Text("Go User")),
//                   ],
//                 )),
//             pageTransition: PageTransition.slideRight),
//         ChildRoute(
//           '/p',
//           name: "teste",
//           child: (context, state, i) => Scaffold(
//               appBar: AppBar(
//                 leading: const BackButton(),
//               ),
//               body: const Text("Centre")),
//         ),
//       ];
// }
import 'package:example/src/core/routes.dart';
import 'package:example/src/modules/auth/auth_module.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class UserModule extends Module {
  @override
  List<ModularRoute> get routes => [
        ChildRoute("/", child: (context, state, i) => const PageTeste("/user")),
        ChildRoute(Routes.name.childR, child: (context, state, i) => const PageTeste("name")),
        ChildRoute(Routes.phone.childR, child: (context, state, i) => const PageTeste("phone")),
        ChildRoute(Routes.phoneConfirm.childR, child: (context, state, i) => const PageTeste("phone")),
        ChildRoute(Routes.searchAddress.childR, child: (context, state, i) => const PageTeste("Search address")),
        ChildRoute(Routes.addressNickname.childR, child: (context, state, i) => const PageTeste("address nickname")),
      ];
}
