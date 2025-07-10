import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: Modular.routerConfig,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
        },
      ),
      title: 'Modular GoRoute Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      builder: (context, child) {
        return Scaffold(
          body: child,
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: "debug_modules",
                onPressed: () {
                  // Debug do estado atual dos módulos

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Debug dos módulos executado - verifique os logs'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Icon(Icons.bug_report),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: "force_dispose",
                backgroundColor: Colors.red,
                onPressed: () {
                  // Força limpeza de todos os módulos não ativos
                  // Aqui você pode adicionar lógica para forçar dispose se necessário
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Limpeza forçada executada'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Icon(Icons.cleaning_services),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ErrorPage extends StatelessWidget {
  final Exception? error;
  const ErrorPage({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Erro de Navegação')),
      body: Center(
        child: Text(
          'Erro: ${error?.toString() ?? 'Rota não encontrada'}',
          style: const TextStyle(color: Colors.red, fontSize: 18),
        ),
      ),
    );
  }
}
