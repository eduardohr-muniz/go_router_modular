import 'dart:developer';

import 'package:example/src/core/routes.dart';
import 'package:example/src/modules/user/aplication/user_store.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // late final store = context.read<UserStore>();
  late final auth = Modular.get<UserStore>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Olá 👋 ${Modular.stateOf(context).path}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // TextFormField(
            //   initialValue: store.name,
            //   decoration: const InputDecoration(labelText: "Name"),
            //   onChanged: (value) => store.name = value,
            // ),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () {
                  context.push(Routes.user.route);
                },
                child: const Text("Go User")),
            ElevatedButton(
                onPressed: () {
                  log(auth.teste.getName());
                },
                child: const Text("get auth bind"))
          ],
        ),
      ),
    );
  }
}
