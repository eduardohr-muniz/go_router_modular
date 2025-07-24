import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class ExampleEventPage extends StatelessWidget {
  const ExampleEventPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exemplo de Event Module'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Demonstração de Event Module',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Disparar evento para mostrar modal
                ModularEvent.fire(ShowModalEvent(
                  context: context,
                  title: 'Modal Exemplo',
                  message: 'Este é um modal disparado por evento!',
                ));
              },
              child: const Text('Mostrar Modal (Evento)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Disparar evento para mostrar snackbar
                ModularEvent.fire(ShowSnackBarEvent(
                  context: context,
                  message: 'SnackBar disparado por evento!',
                ));
              },
              child: const Text('Mostrar SnackBar (Evento)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Exemplo de disparar múltiplos eventos em sequência
                ModularEvent.fire(ShowSnackBarEvent(
                  context: context,
                  message: 'Primeiro evento disparado!',
                ));

                Future.delayed(const Duration(seconds: 2), () {
                  ModularEvent.fire(ShowModalEvent(
                    context: context,
                    title: 'Segundo Evento',
                    message: 'Este modal foi disparado após 2 segundos!',
                  ));
                });
              },
              child: const Text('Disparar Eventos em Sequência'),
            ),
            const SizedBox(height: 32),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Como funciona:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('• Event Module escuta eventos específicos'),
                    Text('• modularEvent.fire() dispara eventos'),
                    Text('• Eventos são processados automaticamente'),
                    Text('• Permite comunicação desacoplada entre módulos'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShowModalEvent {
  final BuildContext context;
  final String title;
  final String message;

  ShowModalEvent({required this.context, required this.title, required this.message});
}

class ShowSnackBarEvent {
  final BuildContext context;
  final String message;

  ShowSnackBarEvent({required this.context, required this.message});
}
