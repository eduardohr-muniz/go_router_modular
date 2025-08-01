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
    on<ShowModalEvent>((event, context) {
      if (context != null) {
        showModalBottomSheet(
            context: context,
            builder: (context) => BottomSheet(
                  onClosing: () {},
                  builder: (context) => Column(
                    children: [
                      Text(event.title),
                      Text(event.message),
                    ],
                  ),
                ));
      }
    });

    on<ShowSnackBarEvent>(
      (event, context) {
        if (context != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(event.message)));
      },
      autoDispose: false,
    );
  }
}
