import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class PageTwo extends StatelessWidget {
  const PageTwo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow,
      appBar: AppBar(
        title: Text('Pagina 2,  path = ${Modular.stateOf(context).path}'),
      ),
      body: Container(),
    );
  }
}
