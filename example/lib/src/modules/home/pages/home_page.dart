// ignore_for_file: avoid_print, deprecated_member_use

import 'package:example/src/modules/shared/module_singleton.dart';
import 'package:example/src/modules/shared/shared_service.dart';
import 'package:example/src/modules/shared/test_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoading = false;
  bool _hasShownInitialMessage = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasShownInitialMessage) {
      _hasShownInitialMessage = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnackBar('🏠 Home Module carregado com sucesso!', Colors.blue);
      });
    }
  }

  @override
  void dispose() {
    print('🗑️ HomeModule dispose iniciado');
    super.dispose();
  }

  void _showSnackBar(String message, Color color) {
    try {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: color,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('SnackBar: $message');
    }
  }

  void _veryHashBindSingleton() {
    final bindSingleton = Modular.get<IBindSingleton>();
    bindSingleton.printHash();
  }

  Future<void> _navigateToAutoResolve() async {
    setState(() => isLoading = true);
    _showSnackBar('🧪 Navegando para AutoResolve...', Colors.blue);

    try {
      await context.goAsync('/auto-resolve', onComplete: () {
        print('✅ Navegação para AutoResolve completada');
      });
    } catch (e) {
      print('❌ Erro na navegação: $e');
      _showSnackBar('❌ Erro na navegação: $e', Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _navigateToBindsByKey() async {
    setState(() => isLoading = true);
    _showSnackBar('🧪 Navegando para BindsByKey...', Colors.blue);

    try {
      await context.pushAsync('/binds-by-key', onComplete: () {
        print('✅ Navegação para BindsByKey completada');
      });
    } catch (e) {
      print('❌ Erro na navegação: $e');
      _showSnackBar('❌ Erro na navegação: $e', Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _navigateToUser() async {
    setState(() => isLoading = true);
    _showSnackBar('👤 Navegando para User...', Colors.purple);

    try {
      await context.goAsync('/user', onComplete: () {
        print('✅ Navegação para User completada');
      });
    } catch (e) {
      print('❌ Erro na navegação: $e');
      _showSnackBar('❌ Erro na navegação: $e', Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _navigateToShell() async {
    setState(() => isLoading = true);
    _showSnackBar('🐚 Navegando para Shell...', Colors.green);

    try {
      // Teste de shell navigation
      final result = TestController.instance.testShellNavigation(
        '/shell',
        ['profile', 'settings'],
      );

      await context.push('/shell/profile');

      if (result.success) {
        _showSnackBar('🎉 Shell navigation testado com sucesso!', Colors.green);
      }
    } catch (e) {
      print('❌ Erro na navegação: $e');
      _showSnackBar('❌ Erro na navegação: $e', Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _navigateToEvent() async {
    setState(() => isLoading = true);
    _showSnackBar('🐚 Navegando para Event...', Colors.green);

    try {
      // Teste de shell navigation
      final result = TestController.instance.testShellNavigation(
        '/event',
        ['profile', 'settings'],
      );

      await context.push('/event');

      if (result.success) {
        _showSnackBar('🎉 Event navigation testado com sucesso!', Colors.green);
      }
    } catch (e) {
      print('❌ Erro na navegação: $e');
      _showSnackBar('❌ Erro na navegação: $e', Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _testHomeService() {
    try {
      final sharedService = Modular.get<SharedService>();
      sharedService.setName('Teste do HomeModule - ${DateTime.now().millisecondsSinceEpoch}');

      print('✅ SharedService testado: ${sharedService.name}');
      _showSnackBar('✅ SharedService funcionando!', Colors.green);
    } catch (e) {
      print('❌ Erro ao testar SharedService: $e');
      _showSnackBar('❌ Erro no SharedService: $e', Colors.red);
    }
  }

  // Teste para verificar se binds foram disposed após navegação
  void _testBindDisposal() {
    final dependencies = {
      'Z': () => Modular.get<Z>(),
      'A': () => Modular.get<A>(),
      'B': () => Modular.get<B>(),
      'C': () => Modular.get<C>(),
      'D': () => Modular.get<D>(),
    };

    final result = TestController.instance.testBindDisposal(
      'AutoResolveModule',
      dependencies,
    );

    if (result.success) {
      _showSnackBar('🎉 Binds foram corretamente disposed!', Colors.green);
    } else {
      _showSnackBar('⚠️ Alguns binds ainda existem!', Colors.orange);
    }

    setState(() {}); // Atualizar UI
  }

  @override
  Widget build(BuildContext context) {
    final controller = TestController.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Go Router Modular - Sistema de Testes'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.home, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Home Module - Centro de Controle',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Módulo atual: ${controller.currentModule ?? 'HomeModule'}'),
                    Text('Total de testes: ${controller.testCount}'),
                    if (isLoading) const LinearProgressIndicator(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Navigation Test Buttons
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: isLoading ? null : _navigateToAutoResolve,
                          icon: const Icon(Icons.science),
                          label: const Text('1. Testar Auto Resolve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _testBindDisposal,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('2. Verificar Dispose'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: isLoading ? null : _navigateToShell,
                          icon: const Icon(Icons.layers),
                          label: const Text('3. Testar Shell'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: isLoading ? null : _navigateToEvent,
                          icon: const Icon(Icons.layers),
                          label: const Text('4. Testar Event Module'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: isLoading ? null : _veryHashBindSingleton,
                          icon: const Icon(Icons.layers),
                          label: const Text('5. Testar hash singleton'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: isLoading ? null : _navigateToBindsByKey,
                          icon: const Icon(Icons.layers),
                          label: const Text('6. Testar BindsByKey'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: isLoading ? null : _navigateToUser,
                          icon: const Icon(Icons.person),
                          label: const Text('Testar User Module'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _testHomeService,
                          icon: const Icon(Icons.home_repair_service),
                          label: const Text('Testar Home Service'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/demo'),
                          icon: const Icon(Icons.play_circle),
                          label: const Text('Demo Page'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
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

            // Control Buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎛️ Controles',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            TestController.instance.clearAll();
                            setState(() {});
                            _showSnackBar('🧹 Tudo limpo!', Colors.grey);
                          },
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Limpar Tudo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            TestController.instance.clearTestResults();
                            setState(() {});
                            _showSnackBar('🧹 Resultados limpos!', Colors.grey);
                          },
                          icon: const Icon(Icons.clear),
                          label: const Text('Limpar Testes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade600,
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

            // Results Section
            Expanded(
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: '📊 Testes', icon: Icon(Icons.science)),
                        Tab(text: '🧭 Navegação', icon: Icon(Icons.navigation)),
                        Tab(text: '💉 Binds', icon: Icon(Icons.memory)),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Test Results Tab
                          _buildTestResultsTab(controller),
                          // Navigation History Tab
                          _buildNavigationHistoryTab(controller),
                          // Bind History Tab
                          _buildBindHistoryTab(controller),
                        ],
                      ),
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

  Widget _buildTestResultsTab(TestController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: controller.testResults.isEmpty
            ? const Center(
                child: Text(
                  'Nenhum teste executado ainda.\nUse os botões de navegação para testar!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            : ListView.builder(
                itemCount: controller.testResults.length,
                itemBuilder: (context, index) {
                  final result = controller.testResults[index];
                  return Card(
                    color: result.success ? Colors.green.shade50 : Colors.red.shade50,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      title: Text(
                        'Teste #${result.id} - ${result.message}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: result.success ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                      subtitle: Text(
                        '${result.timestamp} | ${result.moduleName} | ${result.success ? 'PASSOU' : 'FALHOU'}',
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: result.details.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text(
                                  '• ${entry.key}: ${entry.value}',
                                  style: const TextStyle(fontFamily: 'monospace'),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildNavigationHistoryTab(TestController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: controller.navigationHistory.isEmpty
            ? const Center(
                child: Text(
                  'Nenhum evento de navegação registrado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            : ListView.builder(
                itemCount: controller.navigationHistory.length,
                itemBuilder: (context, index) {
                  final log = controller.navigationHistory[index];
                  Color logColor = Colors.blue;

                  if (log.contains('🏠')) {
                    logColor = Colors.green;
                  } else if (log.contains('🚪')) {
                    logColor = Colors.orange;
                  } else if (log.contains('🐚')) {
                    logColor = Colors.purple;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: logColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: logColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      log,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: logColor,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildBindHistoryTab(TestController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: controller.bindHistory.isEmpty
            ? const Center(
                child: Text(
                  'Nenhum evento de bind registrado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            : ListView.builder(
                itemCount: controller.bindHistory.length,
                itemBuilder: (context, index) {
                  final log = controller.bindHistory[index];
                  Color logColor = Colors.black;

                  if (log.contains('📝')) {
                    logColor = Colors.blue;
                  } else if (log.contains('🗑️')) {
                    logColor = Colors.red;
                  } else if (log.contains('🧪')) {
                    logColor = Colors.green;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: logColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: logColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      log,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: logColor,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// Classes necessárias para os testes de disposal (devem estar no AutoResolveModule)
class Z {
  final dynamic homeService;
  Z(this.homeService);
}

class A {
  final Z z;
  A(this.z);
}

class B {
  final A a;
  B(this.a);
}

class C {
  final B b;
  C(this.b);
}

class D {
  final A a;
  D(this.a);
}
