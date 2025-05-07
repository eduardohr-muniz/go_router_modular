import 'package:example/src/core/routes.dart';
import 'package:example/src/modules/user/domain/repositories/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class UserPage extends StatefulWidget {
  final UserRepository userRepository;
  const UserPage({super.key, required this.userRepository});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  // late final auth = context.read<AuthStore>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Passe para proxima pagina ${widget.userRepository.getSurname()}'),
      ),
      body: SizedBox(
        child: Center(
          child: ElevatedButton(
              onPressed: () {
                context.go(Routes.userName('Edu'));
              },
              child: const Text("Go User name")),
        ),
      ),
    );
  }
}
