import 'package:example/src/modules/auth/auth_store.dart';
import 'package:example/src/modules/shell/home_shell/home_shell_module.dart';
import 'package:example/src/modules/user/aplication/user_store.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class HomeShellPage extends StatefulWidget {
  final Widget shellChild; // Request a child WIDGET to be rendered in the shell
  const HomeShellPage({
    super.key,
    required this.shellChild,
  });

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  late final store = context.read<UserStore>();
  late final auth = Modular.get<AuthStore>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(children: [
        Expanded(child: widget.shellChild), // Your routes will be re-rendered here
        Row(
          children: [
            ElevatedButton(
              child: const Text('page 1'),
              onPressed: () {
                context.go("/");
              },
            ),
            ElevatedButton(
              child: const Text('page 2'),
              onPressed: () {
                context.go("/page-2");
              },
            ),
            ElevatedButton(
              child: const Text('page 3'),
              onPressed: () {
                context.go("/page-3");
                isLoggedin = true;
              },
            ),
            ElevatedButton(
              child: const Text('user'),
              onPressed: () {
                context.go("/user");
              },
            ),
          ],
        ),
      ]),
    );
  }
}
