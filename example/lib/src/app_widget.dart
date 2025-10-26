import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Configurar transições padrão globais
    GoTransition.defaultCurve = Curves.easeInOut;
    GoTransition.defaultDuration = const Duration(milliseconds: 400);

    return MaterialApp.router(
      routerConfig: Modular.routerConfig,
      builder: (context, child) => ModularLoader.builder(context, child),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
        },
      ),
      title: 'Modular GoRoute Example - Transitions Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Configuração global de transições para fallback
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: GoTransitions.fadeUpwards,
            TargetPlatform.iOS: GoTransitions.cupertino,
            TargetPlatform.macOS: GoTransitions.cupertino,
            TargetPlatform.linux: GoTransitions.fade,
            TargetPlatform.windows: GoTransitions.fade,
            TargetPlatform.fuchsia: GoTransitions.fade,
          },
        ),
      ),
    );
  }
}
