import 'package:example/src/app_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'src/app_module.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Modular.configure(
    appModule: AppModule(),
    initialRoute: '/',
    debugLogDiagnostics: true,
    debugLogDiagnosticsGoRouter: true,
    debugLogEventBus: kDebugMode,
    defaultTransition: GoTransitions.fadeUpwards, // Transição padrão
    defaultTransitionDuration: Duration(milliseconds: 600),
    defaultTransitionCurve: Curves.easeInOutCubic,
  );

  runApp(const AppWidget());
}
