import 'package:example/src/modules/user/domain/repositories/i_user_repository.dart';
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
  late final store = Bind.get<IUserRepository>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Olá 👋, ${widget.name} ${store.getSurname()}'),
      ),
      body: Container(),
    );
  }
}
