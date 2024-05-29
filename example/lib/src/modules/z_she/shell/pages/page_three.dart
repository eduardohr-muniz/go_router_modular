import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class PageThree extends StatelessWidget {
  const PageThree({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: Text('Pagina 3,  path = ${Modular.stateOf(context).path}'),
      ),
      body: Container(),
    );
  }
}
