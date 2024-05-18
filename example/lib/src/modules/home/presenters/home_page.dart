import 'package:example/src/modules/user/aplication/user_store.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final store = context.read<UserStore>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Olá 👋'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextFormField(
              initialValue: store.name,
              decoration: const InputDecoration(labelText: "Name"),
              onChanged: (value) => store.name = value,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () {
                  context.pushNamed('user');
                },
                child: const Text("Go User"))
          ],
        ),
      ),
    );
  }
}
