import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/go_router_modular.dart';

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  @override
  void initState() {
    super.initState();
    print('🎯 [DEMO_PAGE] DemoPage inicializada');
  }

  @override
  void dispose() {
    print('🗑️ [DEMO_PAGE] DemoPage disposta');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ [DEMO_PAGE] Construindo DemoPage');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Page'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Página de Demo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const Text(
              'Esta página está fora dos módulos principais.\n'
              'Navegar para cá vai disparar o dispose dos módulos ativos.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                print('🏠 [DEMO_PAGE] Voltando para Home');
                context.go('/');
              },
              child: const Text('Voltar para Home'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                print('🔐 [DEMO_PAGE] Navegando para AuthModule');
                context.go('/auth');
              },
              child: const Text('Ir para AuthModule'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                print('👤 [DEMO_PAGE] Navegando para UserModule');
                context.go('/user');
              },
              child: const Text('Ir para UserModule'),
            ),
            const SizedBox(height: 32),
            const Text(
              'Teste de Injeção:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                print('🔍 [DEMO_PAGE] Testando injeção de SharedService');
                try {
                  final sharedService = GoRouterModular.get<SharedService>();
                  print('✅ [DEMO_PAGE] SharedService injetado: ${sharedService.runtimeType}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ SharedService injetado com sucesso!')),
                  );
                } catch (e) {
                  print('❌ [DEMO_PAGE] Erro ao injetar SharedService: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ Erro: $e')),
                  );
                }
              },
              child: const Text('Testar Injeção'),
            ),
          ],
        ),
      ),
    );
  }
}

class SharedService {
  SharedService() {
    print('🔗 [SHARED_SERVICE] SharedService criado via DemoPage');
  }
}
