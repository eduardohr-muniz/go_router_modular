import 'package:example/src/core/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  // late final auth = context.read<AuthStore>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Passe para proxima pagina '),
      ),
      body: SizedBox(
        child: Center(
          child: ElevatedButton(
              onPressed: () {
                context.push(Routes.userName.buildPath(params: ["Dudu"]));
              },
              child: const Text("Go User name")),
        ),
      ),
    );
  }
}
