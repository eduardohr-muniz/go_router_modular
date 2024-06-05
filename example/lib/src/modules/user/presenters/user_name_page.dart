import 'package:example/src/modules/user/aplication/user_store.dart';
import 'package:flutter/material.dart';

import 'package:go_router_modular/go_router_modular.dart';

class UserNamePage extends StatefulWidget {
  final String name;
  const UserNamePage({
    super.key,
    this.name = 'não veio',
  });

  @override
  State<UserNamePage> createState() => _UserNamePageState();
}

class _UserNamePageState extends State<UserNamePage> {
  late final store = Bind.get<UserStore>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Olá 👋, ${store.name} ${widget.name} ${store.name} ${store.teste.getName()}'),
      ),
      body: Container(),
    );
  }
}
