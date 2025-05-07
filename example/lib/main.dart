import 'package:example/src/app_module.dart';
import 'package:example/src/app_widget.dart';
import 'package:example/src/core/routes.dart';
import 'package:flutter/material.dart';

import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router_modular/go_router_modular.dart';

void main() {
  // ignore: prefer_const_constructors
  setUrlStrategy(PathUrlStrategy());

  Modular.configure(
    appModule: AppModule(),
    initialRoute: Routes.splash,
    debugLogDiagnosticsGoRouter: true,
  );
  runApp(const AppWidget());
}
