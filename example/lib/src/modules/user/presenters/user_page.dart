import 'package:example/src/modules/shared/shared_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/diagnostics.dart';
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
  }

  // @override
  // void reassemble() {
  //   print('UserPage reassemble');
  //   super.reassemble();
  // }

  @override
  Widget build(BuildContext context) {
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
                context.go('/');
              },
              child: const Text('Ir para Home'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.go('/auth');
              },
              child: const Text('Ir para Auth'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.go('/user/user_name/teste');
              },
              child: const Text('Ir para User Name Page'),
            ),
            ElevatedButton(
              onPressed: () {
                Modular.get<SharedService>().setName('teste');
              },
              child: Text('Teste Shared ${Modular.get<SharedService>().name}'),
            ),
          ],
        ),
      ),
    );
  }
}
