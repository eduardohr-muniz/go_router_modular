import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Passe para proxima pagina'),
      ),
      body: Container(
        child: Center(
          child: ElevatedButton(
              onPressed: () {
                context.pushNamed("user_name");
              },
              child: const Text("Go User name")),
        ),
      ),
    );
  }
}
