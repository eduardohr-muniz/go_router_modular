// import 'package:example/src/modules/home/pages/home_page.dart';
// import 'package:example/src/modules/user/aplication/teste.dart';
// import 'package:example/src/modules/user/aplication/user_store.dart';
// import 'package:example/src/modules/user/user_module.dart';
// import 'package:example/src/routes.dart';
// import 'package:go_router_modular/go_router_modular.dart';

// class HomeModule extends Module {
//   @override
//   List<Bind<Object>> get binds => [
//         Bind.singleton((i) => UserStore(i.get())),
//         Bind.factory((i) => Teste()),
//       ];

//   @override
//   List<ModularRoute> get routes => [
//         ChildRoute(Routes.home.childR, name: "home", child: (context, state, i) => const HomePage(), pageTransition: PageTransition.slideRight),
//         ModuleRoute(Routes.user.moduleR, module: UserModule()),
//       ];
// }
