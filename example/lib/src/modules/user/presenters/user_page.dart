import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  @override
  void initState() {
    super.initState();
    print('👤 [USER_PAGE] UserPage inicializada');
  }

  @override
  void dispose() {
    print('🗑️ [USER_PAGE] UserPage disposta');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ [USER_PAGE] Construindo UserPage');

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Module'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'User Module',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text('Este é o módulo de usuário'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print('👤 [USER_PAGE] Navegando para HomeModule');
                context.go('/');
              },
              child: const Text('Ir para Home'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print('👤 [USER_PAGE] Navegando para AuthModule');
                context.go('/auth');
              },
              child: const Text('Ir para Auth'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print('👤 [USER_PAGE] Navegando para UserNamePage');
                context.go('/user/user_name/teste');
              },
              child: const Text('Ir para User Name Page'),
            ),
          ],
        ),
      ),
    );
  }
}
