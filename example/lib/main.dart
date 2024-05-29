import 'package:example/src/app_module.dart';
import 'package:example/src/app_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

// final injector = Injector();

// final router = GoRouter(
//   initialLocation: '/',
//   routes: AppModule().configureRoutes(injector),
// );

void main() {
  // WidgetsFlutterBinding.ensureInitialized();
  // ignore: prefer_const_constructors
  setUrlStrategy(PathUrlStrategy());

  Modular.configure(
    appModule: AppModule(),
    initialRoute: "/",
  );
  runApp(const AppWidget());
}
