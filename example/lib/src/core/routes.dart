import 'package:go_router_modular/go_router_modular.dart';

class Routes {
  static const Duration d = Duration(milliseconds: 700);

  //Auth
  static final RouteModel slpash = RouteModel.build(module: "/", routeName: '/');
  static final RouteModel login = RouteModel.build(module: "/", routeName: '/login');
  //User
  static final RouteModel name = RouteModel.build(module: "/user", routeName: '/');
  static final RouteModel phone = RouteModel.build(module: "/user", routeName: '/phone');
  static final RouteModel phoneConfirm = RouteModel.build(module: "/user", routeName: '/phone_confirm');
  static final RouteModel searchAddress = RouteModel.build(module: "/user", routeName: '/search_address');
  static final RouteModel addressNickname = RouteModel.build(module: "/user", routeName: '/address_nickname');
  //menu
  static final RouteModel menu = RouteModel.build(module: "/menu", routeName: '/', params: ["establishment_id"]);
  static final RouteModel cartProduct = RouteModel.build(module: "/menu", routeName: '/cart_product', params: ["establishment_id", "porduc_id"]);
  static final RouteModel cart = RouteModel.build(module: "/menu", routeName: '/cart');
  static final RouteModel paymentQrcode = RouteModel.build(module: '/menu', routeName: '/payment_qrcode');
  //order
  static final RouteModel order = RouteModel.build(module: '/order', routeName: '/order');
}
