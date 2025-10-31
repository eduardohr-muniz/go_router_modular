import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import '../async_binds_module.dart';

class AsyncBindsPage extends StatefulWidget {
  const AsyncBindsPage({Key? key}) : super(key: key);

  @override
  State<AsyncBindsPage> createState() => _AsyncBindsPageState();
}

class _AsyncBindsPageState extends State<AsyncBindsPage> {
  IAppConfig? config;
  ICacheService? cache;
  IHttpClient? httpClient;
  IAuthService? authService;
  ISharedPreferences? sharedPrefs;
  
  String? loginResult;
  bool isLoading = false;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Buscar todas as dependências injetadas usando context
    // didChangeDependencies é chamado após o widget estar no contexto
    if (config == null) {
      config = context.read<IAppConfig>();
      cache = context.read<ICacheService>();
      httpClient = context.read<IHttpClient>();
      authService = context.read<IAuthService>();
      sharedPrefs = context.read<ISharedPreferences>();
    }
  }

  Future<void> _performLogin() async {
    setState(() {
      isLoading = true;
      loginResult = null;
    });
    
    try {
      final success = await authService!.login('demo_user', 'password123');
      setState(() {
        loginResult = success ? '✅ Login realizado com sucesso!' : '❌ Falha no login';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        loginResult = '❌ Erro: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Garantir que as dependências foram carregadas
    if (config == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Async Binds Demo'),
          backgroundColor: Colors.deepPurple,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Async Binds Demo'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.purple.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.sync, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Async Binds Example',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Demonstração de binds assíncronos com imports',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Config Info
            _buildCard(
              title: '⚙️ App Config',
              icon: Icons.settings,
              color: Colors.blue,
              children: [
                _buildInfoRow('API URL', config!.apiUrl),
                _buildInfoRow('Timeout', '${config!.timeout}s'),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // HTTP Client Info
            _buildCard(
              title: '🌐 HTTP Client',
              icon: Icons.http,
              color: Colors.green,
              children: [
                _buildInfoRow('Base URL', httpClient!.baseUrl),
                _buildInfoRow('Timeout', '${httpClient!.timeout}s'),
                _buildInfoRow('Status', '✅ Injetado do módulo pai'),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Cache Info
            _buildCard(
              title: '💾 Cache Service',
              icon: Icons.storage,
              color: Colors.orange,
              children: [
                const Text(
                  'Dados em cache (SharedPreferences):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ...cache!.getAll().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Auth Service Test
            _buildCard(
              title: '🔐 Auth Service',
              icon: Icons.security,
              color: Colors.red,
              children: [
                _buildInfoRow('Client Type', authService!.client.runtimeType.toString()),
                _buildInfoRow('Cached Token', authService!.cachedToken ?? '(nenhum)'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : _performLogin,
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.login),
                  label: Text(isLoading ? 'Autenticando...' : 'Testar Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                if (loginResult != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: loginResult!.contains('✅')
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: loginResult!.contains('✅')
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    child: Text(
                      loginResult!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: loginResult!.contains('✅')
                            ? Colors.green.shade900
                            : Colors.red.shade900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Explanation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Como funciona?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '1. AsyncBindsModule tem binds() ASSÍNCRONO que:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text('   • Aguarda SharedPreferences.getInstance()'),
                  const Text('   • Carrega config remoto'),
                  const Text('   • Registra HttpClient'),
                  const SizedBox(height: 8),
                  const Text(
                    '2. AsyncAuthModule (importado) usa i.get():',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text('   • Busca HttpClient do módulo pai'),
                  const Text('   • Funciona porque AppModule aguardou binds()'),
                  const SizedBox(height: 8),
                  const Text(
                    '3. ✅ Resultado:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const Text('   • Todos os binds disponíveis'),
                  const Text('   • Imports conseguem acessar dependências'),
                  const Text('   • Sem erro "Injector committed!"'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

