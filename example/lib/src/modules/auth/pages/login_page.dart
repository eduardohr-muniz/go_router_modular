import 'package:example/src/core/routes.dart';
import 'package:example/src/modules/auth/auth_store.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final store = context.read<AuthStore>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login page - store: ${store.hello}'),
      ),
      body: Center(
        child: ElevatedButton(
            onPressed: () {
              context.goNamed(Routes.user.name);
            },
            child: const Text('Go user module')),
      ),
    );
  }
}
