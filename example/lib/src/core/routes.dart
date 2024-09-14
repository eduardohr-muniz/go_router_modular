import 'package:go_router_modular/go_router_modular.dart';

class Routes {
  static const Duration d = Duration(milliseconds: 700);

  //Auth
  static final RouteModularModel slpash = RouteModularModel.build(module: "/", routeName: '/');
  static final RouteModularModel login = RouteModularModel.build(module: "/", routeName: 'login');

  static final RouteModularModel user = RouteModularModel.build(module: 'user', routeName: 'user');
  static final RouteModularModel userName = RouteModularModel.build(module: 'user', routeName: 'user_name', params: ['name']);
}
