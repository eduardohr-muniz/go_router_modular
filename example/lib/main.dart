import 'package:example/src/app_module.dart';
import 'package:example/src/app_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

final injector = Injector();

final router = GoRouter(
  initialLocation: '/',
  routes: AppModule().configureRoutes(injector),
);

void main() {
  // WidgetsFlutterBinding.ensureInitialized();
  // setUrlStrategy(const PathUrlStrategy());

  runApp(AppWidget(router: router));
}
