import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'pages/example_event_page.dart';

class ExampleEventModule extends EventModule {
  @override
  List<ModularRoute> get routes => [
        ChildRoute('/', child: (context, state) => const ExampleEventPage()),
      ];
  @override
  void listen() {
    on<ShowModalEvent>((event) {
      showModalBottomSheet(context: event.context, builder: (context) => Text(event.title));
    });

    on<ShowSnackBarEvent>((event) {
      ScaffoldMessenger.of(event.context).showSnackBar(SnackBar(content: Text(event.message)));
    });
  }
}
