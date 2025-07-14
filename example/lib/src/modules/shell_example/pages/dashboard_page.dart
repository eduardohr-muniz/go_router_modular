import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 Dashboard',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bem-vindo ao dashboard do Shell Router!',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rota atual: ${context.getPath}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Funcionalidades do Shell Router:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Text('✅ Navegação persistente com BottomNavigationBar'),
                  Text('✅ Estado mantido entre as tabs'),
                  Text('✅ AppBar compartilhada'),
                  Text('✅ Injeção de dependência funcional'),
                  Text('✅ Navegação por context.go()'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Shell Service está funcionando!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.check_circle),
            label: const Text('Testar Shell Service'),
          ),
        ],
      ),
    );
  }
}
