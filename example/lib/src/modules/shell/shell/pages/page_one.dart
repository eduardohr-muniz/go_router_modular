import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class PageOne extends StatelessWidget {
  const PageOne({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      appBar: AppBar(
        title: Text('Page-1, path = ${Modular.stateOf(context).path}'),
      ),
      body: Container(),
    );
  }
}
