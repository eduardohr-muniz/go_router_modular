import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Page')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            context.go('/config');
          },
          child: const Text('Go to Config'),
        ),
      ),
    );
  }
}
