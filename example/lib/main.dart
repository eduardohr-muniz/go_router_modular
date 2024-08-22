import 'package:example/src/app_module.dart';
import 'package:example/src/app_widget.dart';
import 'package:flutter/material.dart';

import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router_modular/go_router_modular.dart';

// final injector = Injector();

// final router = GoRouter(
//   initialLocation: '/',
//   routes: AppModule().configureRoutes(injector),
// );
final navigatorKey = GlobalKey<NavigatorState>();
void main() {
  // WidgetsFlutterBinding.ensureInitialized();
  // ignore: prefer_const_constructors
  setUrlStrategy(PathUrlStrategy());

  Modular.configure(
    navigatorKey: navigatorKey,
    appModule: AppModule(),
    initialRoute: "/",
    debugLogDiagnosticsGoRouter: true,
  );
  runApp(const AppWidget());
}
