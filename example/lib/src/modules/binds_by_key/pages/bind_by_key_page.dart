import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import '../binds_by_key_module.dart';

class BindByKeyPage extends StatefulWidget {
  const BindByKeyPage({super.key});

  @override
  State<BindByKeyPage> createState() => _BindByKeyPageState();
}

class _BindByKeyPageState extends State<BindByKeyPage> {
  String? result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Keys - Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.key, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Sistema de Keys - Demonstração',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Esta página demonstra como usar o sistema de keys para múltiplas instâncias do mesmo tipo.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🧪 Testes do Sistema de Keys',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _testLocalDio,
                          icon: const Icon(Icons.computer),
                          label: const Text('Dio Local'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _testRemoteDio,
                          icon: const Icon(Icons.cloud),
                          label: const Text('Dio Remote'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _testBothDios,
                          icon: const Icon(Icons.compare),
                          label: const Text('Comparar Ambos'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _testInvalidKey,
                          icon: const Icon(Icons.error),
                          label: const Text('Key Inválida'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Results
            if (result != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📊 Resultado',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          result!,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Info Card
            Card(
              color: Colors.amber.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'Como Funciona',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Dio Local: Busca por key "dio_local"\n'
                      '• Dio Remote: Busca por key "dio_remote"\n'
                      '• Key Inválida: Testa exceção para key inexistente\n'
                      '• Comparar: Mostra as diferenças entre as instâncias',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _testLocalDio() {
    try {
      final injector = Injector();
      final dioLocal = injector.get<DioFake>(key: 'dio_local');

      setState(() {
        result = '''
✅ Dio Local encontrado!
Base URL: ${dioLocal.baseUrl}
Runtime Type: ${dioLocal.runtimeType}
Hash Code: ${dioLocal.hashCode}
        ''';
      });

      _showSnackBar('✅ Dio Local funcionando!', Colors.green);
    } catch (e) {
      setState(() {
        result = '❌ Erro ao buscar Dio Local: $e';
      });
      _showSnackBar('❌ Erro no Dio Local: $e', Colors.red);
    }
  }

  void _testRemoteDio() {
    try {
      final injector = Injector();
      final dioRemote = injector.get<DioFake>(key: 'dio_remote');

      setState(() {
        result = '''
✅ Dio Remote encontrado!
Base URL: ${dioRemote.baseUrl}
Runtime Type: ${dioRemote.runtimeType}
Hash Code: ${dioRemote.hashCode}
        ''';
      });

      _showSnackBar('✅ Dio Remote funcionando!', Colors.blue);
    } catch (e) {
      setState(() {
        result = '❌ Erro ao buscar Dio Remote: $e';
      });
      _showSnackBar('❌ Erro no Dio Remote: $e', Colors.red);
    }
  }

  void _testBothDios() {
    try {
      final injector = Injector();
      final dioLocal = injector.get<DioFake>(key: 'dio_local');
      final dioRemote = injector.get<DioFake>(key: 'dio_remote');

      setState(() {
        result = '''
🔍 Comparação dos DIOs:

📱 Dio Local:
  Base URL: ${dioLocal.baseUrl}
  Hash Code: ${dioLocal.hashCode}

☁️ Dio Remote:
  Base URL: ${dioRemote.baseUrl}
  Hash Code: ${dioRemote.hashCode}

${dioLocal.hashCode == dioRemote.hashCode ? '⚠️ Mesma instância!' : '✅ Instâncias diferentes!'}
        ''';
      });

      _showSnackBar('✅ Comparação realizada!', Colors.purple);
    } catch (e) {
      setState(() {
        result = '❌ Erro na comparação: $e';
      });
      _showSnackBar('❌ Erro na comparação: $e', Colors.red);
    }
  }

  void _testInvalidKey() {
    try {
      final injector = Injector();
      injector.get<DioFake>(key: 'key_inexistente');

      setState(() {
        result = '❌ Erro: Deveria ter lançado exceção!';
      });
      _showSnackBar('❌ Teste falhou - deveria ter exceção!', Colors.red);
    } catch (e) {
      setState(() {
        result = '''
✅ Exceção lançada corretamente!
Erro: $e

Isso demonstra que o sistema de keys está funcionando corretamente - quando uma key não existe, uma exceção é lançada.
        ''';
      });
      _showSnackBar('✅ Exceção lançada corretamente!', Colors.green);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
