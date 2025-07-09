import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'src/app_module.dart';

void main() {
  print('🚀 [MAIN] Iniciando aplicação');
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
      routerConfig: GoRouterModularConfigure.configure(
        module: AppModule(),
        initialRoute: '/',
        debugLogDiagnostics: true,
      ),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}
