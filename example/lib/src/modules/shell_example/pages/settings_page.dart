import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import '../shell_module.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  SettingsService? settingsService;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadService();
  }

  void _loadService() {
    try {
      settingsService = Modular.get<SettingsService>();
      errorMessage = null;
    } catch (e) {
      settingsService = null;
      errorMessage = 'Erro ao carregar SettingsService: $e';
      print('Erro no SettingsPage: $e');
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Card(
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.settings, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      '⚙️ Settings Module',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Módulo irmão do Profile - teste a navegação entre eles.',
                  style: TextStyle(color: Colors.green.shade700),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Status do Service
        Card(
          color: errorMessage != null ? Colors.red.shade50 : Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      errorMessage != null ? Icons.error : Icons.check_circle,
                      color: errorMessage != null ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Status do SettingsService',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: errorMessage != null ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (errorMessage != null) ...[
                  Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadService,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar Novamente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ] else if (settingsService != null) ...[
                  Text('Service Name: ${settingsService!.name}'),
                  Text('Service Hash: ${settingsService.hashCode}'),
                  const Text('✅ SettingsService carregado com sucesso!'),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Botões de teste
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🧪 Testes de Navegação',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Teste a navegação entre módulos irmãos:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                const Text('1. Vá para Profile e veja se SettingsModule é disposed'),
                const Text('2. Volte para Settings e veja se ProfileModule é disposed'),
                const Text('3. Saia do Shell e veja se ambos são disposed'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.go('/shell/profile'),
                      icon: const Icon(Icons.person),
                      label: const Text('Ir para Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text('Sair do Shell'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/demo'),
                      icon: const Icon(Icons.home),
                      label: const Text('Demo Page'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
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

        // Informações do módulo
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ℹ️ Informações do Módulo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('• Este é outro módulo filho dentro do ShellModularRoute'),
                  const Text('• O SettingsService é um singleton dentro deste módulo'),
                  const Text('• Módulos irmãos devem ser disposed quando você navega entre eles'),
                  const Text('• O ShellModule (pai) permanece ativo até sair do shell'),
                  const SizedBox(height: 16),
                  if (settingsService != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Service Instance:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Name: ${settingsService!.name}'),
                          Text('Hash: ${settingsService.hashCode}'),
                          Text('Type: ${settingsService.runtimeType}'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
