import 'package:example/src/modules/home/pages/demo_page.dart';
import 'package:example/src/modules/shared/shared_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Go Router Modular Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Bem-vindo ao Go Router Modular!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.go('/auth');
              },
              child: const Text('Módulo Auth'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              /// behavior with
              /// local loading handling
              onPressed: () async {
                setState(() => isLoading = true);
                await context.push('/user');
                setState(() => isLoading = false);
              },
              child: isLoading ? const SizedBox(height: 15, width: 15, child: CircularProgressIndicator()) : const Text('Módulo User'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.go('/demo');
              },
              child: const Text('Demo Page'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.push('/shell/dashboard');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('🚀 Shell Router Example'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Modular.get<SharedService>().setName('teste');
              },
              child: Text('Teste Shared ${Modular.get<SharedService>().name}'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.go('/auto-resolve');
              },
              child: const Text('Teste Auto Resolve'),
            ),
            const SizedBox(height: 32),
            const Text(
              'Teste de Loader:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ModularLoader.show();
                Future.delayed(const Duration(seconds: 2), () {
                  ModularLoader.hide();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Mostrar Loader'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ModularLoader.hide();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Esconder Loader'),
            ),
            const SizedBox(height: 32),
            const Text(
              'Teste de Erros:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.go('/rota-inexistente');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Rota Inexistente'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.go('/user/name/');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Parâmetro Ausente'),
            ),
          ],
        ),
      ),
    );
  }
}
