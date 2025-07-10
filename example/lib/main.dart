import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'src/app_module.dart';

void main() {
  Modular.configure(
    appModule: AppModule(),
    initialRoute: '/',
    debugLogDiagnostics: true,
    debugLogDiagnosticsGoRouter: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Go Router Modular Demo',
      debugShowCheckedModeBanner: false,
      routerConfig: Modular.routerConfig,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}
