import 'package:example/src/modules/auth/auth_store.dart';
import 'package:example/src/modules/user/aplication/user_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:go_router_modular/go_router_modular.dart';

class HomeShellPage extends StatefulWidget {
  final Widget shellChild;
  const HomeShellPage({
    super.key,
    required this.shellChild,
  });

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  // late final store = context.read<UserStore>();
  // late final auth = Modular.get<AuthStore>();
  late final auth = Modular.get<AuthStore>();
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
            TextFormField(
              initialValue: "store.name",
              decoration: const InputDecoration(labelText: "Name"),
              onChanged: (value) {},
            ),
            Expanded(
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      child: Column(
                        children: [
                          ElevatedButton(
                              onPressed: () {
                                context.push("/");
                              },
                              child: const Text("Pagina 1")),
                          const SizedBox(height: 20),
                          ElevatedButton(
                              onPressed: () {
                                context.push("/two");
                              },
                              child: const Text("Pagina 2")),
                          const SizedBox(height: 20),
                          ElevatedButton(
                              onPressed: () {
                                context.push("/three");
                              },
                              child: const Text("Pagina 3")),
                          const SizedBox(height: 20),
                          ElevatedButton(
                              onPressed: () {
                                context.pushNamed('user');
                              },
                              child: const Text("Go User")),
                          const SizedBox(height: 20),
                          ElevatedButton(
                              onPressed: () {
                                print(auth.verify);
                              },
                              child: const Text("get bind NotFound"))
                        ],
                      ),
                    ),
                  ),
                  Expanded(child: widget.shellChild)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
