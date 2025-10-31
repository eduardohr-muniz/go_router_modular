import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import '../imports_bug_module.dart';

/// Página que demonstra o problema de imports no AppModule
class ImportsBugPage extends StatefulWidget {
  const ImportsBugPage({super.key});

  @override
  State<ImportsBugPage> createState() => _ImportsBugPageState();
}

class _ImportsBugPageState extends State<ImportsBugPage> {
  String? _status;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _testBinds();
  }

  Future<void> _testBinds() async {
    setState(() {
      _isLoading = true;
      _status = 'Testando binds...';
    });

    try {
      // Tentar buscar IClient do AppModule
      final client = Modular.get<IClient>();
      setState(() {
        _status = '✅ IClient encontrado: ${client.baseUrl}';
      });
    } catch (e) {
      setState(() {
        _status = '❌ IClient NÃO encontrado: $e';
      });
    }

    try {
      // Tentar buscar IAuthApi do AppModule
      final api = Modular.get<IAuthApi>();
      setState(() {
        _status = '$_status\n✅ IAuthApi encontrado (${api.runtimeType})';
      });
    } catch (e) {
      setState(() {
        _status = '$_status\n❌ IAuthApi NÃO encontrado: $e';
      });
    }

    try {
      // Tentar buscar AuthPhoneService do AuthPhoneModule (import)
      final authService = Modular.get<AuthPhoneService>();
      setState(() {
        _status = '$_status\n✅ AuthPhoneService encontrado (${authService.runtimeType})';
      });
    } catch (e) {
      setState(() {
        _status = '$_status\n❌ AuthPhoneService NÃO encontrado: $e';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Imports Bug Demo'),
        backgroundColor: Colors.red.shade100,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🐛 Bug de Imports no AppModule',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Este exemplo demonstra o problema onde:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text('1. AppModule tem imports() [AuthPhoneModule]'),
                    const Text('2. AppModule registra IClient e IAuthApi em binds()'),
                    const Text('3. AuthPhoneModule precisa de IClient durante binds()'),
                    const Text('4. ❌ PROBLEMA: imports são processados ANTES de binds()'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status dos Binds:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      Text(
                        _status ?? 'Aguardando teste...',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testBinds,
              child: const Text('Testar Novamente'),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Solução Esperada:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Os binds do AppModule devem estar disponíveis para:',
                    ),
                    const Text('• Módulos importados durante seu binds()'),
                    const Text('• Módulos filhos que precisam dos binds'),
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

