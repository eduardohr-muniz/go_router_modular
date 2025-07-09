import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/go_router_modular.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    print('🏠 [HOME_PAGE] HomePage inicializada');
  }

  @override
  void dispose() {
    print('🗑️ [HOME_PAGE] HomePage disposta');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ [HOME_PAGE] Construindo HomePage');

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
                print('🔐 [HOME_PAGE] Navegando para AuthModule');
                context.go('/auth');
              },
              child: const Text('Módulo Auth'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                print('👤 [HOME_PAGE] Navegando para UserModule');
                context.go('/user');
              },
              child: const Text('Módulo User'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                print('🎯 [HOME_PAGE] Navegando para Demo');
                context.go('/demo');
              },
              child: const Text('Demo Page'),
            ),
            const SizedBox(height: 32),
            const Text(
              'Teste de Erros:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                print('❌ [HOME_PAGE] Testando rota inexistente');
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
                print('👤 [HOME_PAGE] Testando parâmetro ausente');
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
