import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'src/app_module.dart';

void main() {
  print('🚀 [MAIN] Iniciando aplicação');

  Modular.configure(
    appModule: AppModule(),
    initialRoute: '/',
    debugLogDiagnostics: true,
    debugLogDiagnosticsGoRouter: true,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key}) {
    print('🏠 [MYAPP] MyApp criado');
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ [MYAPP] Construindo widget');

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
