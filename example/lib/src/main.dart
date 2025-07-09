import 'package:example/src/app_module.dart';
import 'package:example/src/app_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  Modular.configure(
    appModule: AppModule(),
    debugLogDiagnostics: true,
    debugLogDiagnosticsGoRouter: true,
    initialRoute: "/",
  );

  runApp(const AppWidget());
}
