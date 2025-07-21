import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import '../shell_module.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  ProfileService? profileService;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadService();
  }

  void _loadService() {
    try {
      profileService = Modular.get<ProfileService>();
      errorMessage = null;
    } catch (e) {
      profileService = null;
      errorMessage = 'Erro ao carregar ProfileService: $e';
      print('Erro no ProfilePage: $e');
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
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      '👤 Profile Module',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Este módulo está dentro do Shell e será disposed quando sair.',
                  style: TextStyle(color: Colors.blue.shade700),
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
                      'Status do ProfileService',
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
                ] else if (profileService != null) ...[
                  Text('Service Name: ${profileService!.name}'),
                  Text('Service Hash: ${profileService.hashCode}'),
                  const Text('✅ ProfileService carregado com sucesso!'),
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
                  '🧪 Testes de Dispose',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Para testar o sistema de dispose:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                const Text('1. Vá para Settings (módulo irmão)'),
                const Text('2. Ou saia do Shell completamente'),
                const Text('3. Verifique no console se o ProfileModule foi disposed'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.go('/shell/settings'),
                      icon: const Icon(Icons.settings),
                      label: const Text('Ir para Settings'),
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
                      onPressed: () => context.go('/auto-resolve'),
                      icon: const Icon(Icons.science),
                      label: const Text('Auto Resolve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
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
                  const Text('• Este é um módulo filho dentro de um ShellModularRoute'),
                  const Text('• O ProfileService é um singleton dentro deste módulo'),
                  const Text('• Quando você navegar para fora, o módulo deve ser disposed'),
                  const Text('• Verifique os logs no console para confirmar o dispose'),
                  const SizedBox(height: 16),
                  if (profileService != null) ...[
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
                          Text('Name: ${profileService!.name}'),
                          Text('Hash: ${profileService.hashCode}'),
                          Text('Type: ${profileService.runtimeType}'),
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
