import 'package:example/src/app_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router_modular/go_router_modular.dart';

import 'src/app_module.dart';

Future<void> main() async {
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  await Modular.configure(
    appModule: AppModule(),
    initialRoute: '/',
    debugLogDiagnostics: true,
    debugLogDiagnosticsGoRouter: true,
  );

  runApp(const AppWidget());
}
