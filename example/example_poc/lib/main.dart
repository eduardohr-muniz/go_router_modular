import 'package:example_poc/src/app_module.dart';
import 'package:example_poc/src/app_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GoRouterModular.configure(appModule: AppModule(), initialRoute: '/home');

  runApp(const AppWidget());
}
