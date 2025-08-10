// ignore_for_file: avoid_print

import 'dart:async';

import 'package:example/src/modules/home/home_module.dart';
import 'package:example/src/modules/shared/test_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AutoResolveModule extends Module {
  @override
  FutureOr<List<Bind<Object>>> binds() {
    return [
      Bind.singleton((i) => HomeService()),
      Bind.singleton((i) => A(i.get())),
      Bind.factory((i) => B(i.get())),
      Bind.factory((i) => Z(i.get())),
      Bind.singleton((i) => C(i.get())),
      Bind.singleton((i) => D(i.get())),
    ];
  }

  @override
  List<ModularRoute> get routes => [
        ChildRoute('/', child: (context, args) => const AutoResolveModuleWidget()),
      ];

  @override
  void initState(Injector i) {
    TestController.instance.enterModule('AutoResolveModule');
  }

  @override
  void dispose() {
    TestController.instance.exitModule('AutoResolveModule');
  }
}

class AutoResolveModuleWidget extends StatefulWidget {
  const AutoResolveModuleWidget({super.key});

  @override
  State<AutoResolveModuleWidget> createState() => _AutoResolveModuleWidgetState();
}

class _AutoResolveModuleWidgetState extends State<AutoResolveModuleWidget> {
  late Z? z;
  String? errorMessage;
  bool _hasShownInitialMessage = false;

  @override
  void initState() {
    super.initState();
    _loadDependencies();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasShownInitialMessage) {
      _hasShownInitialMessage = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (errorMessage == null && z != null) {
          _showSnackBar('🧪 AutoResolve Module carregado - Pronto para testes!', Colors.green);
        }
      });
    }
  }

  void _loadDependencies() {
    try {
      z = Modular.get<Z>();
      errorMessage = null;
    } catch (e) {
      z = null;
      errorMessage = 'Erro ao carregar dependências: $e';
    }
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

  // Teste básico de dependências
  void _testBasicDependencies() {
    final dependencies = {
      'Z': () => Modular.get<Z>(),
      'A': () => Modular.get<A>(),
      'B': () => Modular.get<B>(),
      'HomeService': () => Modular.get<HomeService>(),
    };

    final result = TestController.instance.testDependencyResolution(
      'AutoResolveModule',
      dependencies,
    );

    if (result.success) {
      _showSnackBar('🎉 Teste básico passou!', Colors.green);
    } else {
      _showSnackBar('💥 Teste básico falhou!', Colors.red);
    }

    setState(() {}); // Atualizar UI
  }

  // Teste avançado de dependências
  void _testAdvancedDependencies() {
    final dependencies = {
      'C': () => Modular.get<C>(),
      'D': () => Modular.get<D>(),
      'Z (via C)': () => Modular.get<C>().b.a.z,
      'HomeService (via D)': () => Modular.get<D>().a.z.homeService,
    };

    final result = TestController.instance.testDependencyResolution(
      'AutoResolveModule',
      dependencies,
    );

    if (result.success) {
      _showSnackBar('🎉 Teste avançado passou!', Colors.green);
    } else {
      _showSnackBar('💥 Teste avançado falhou!', Colors.red);
    }

    setState(() {}); // Atualizar UI
  }

  // Teste de singleton
  void _testSingleton() {
    try {
      final z1 = Modular.get<Z>();
      final z2 = Modular.get<Z>();
      final homeService1 = z1.homeService;
      final homeService2 = z2.homeService;

      final sameHomeService = identical(homeService1, homeService2);
      final differentZ = !identical(z1, z2);

      final dependencies = {
        'HomeService singleton': () => sameHomeService ? 'OK' : throw Exception('HomeService não é singleton'),
        'Z factory': () => differentZ ? 'OK' : throw Exception('Z não é factory'),
      };

      final result = TestController.instance.testDependencyResolution(
        'AutoResolveModule',
        dependencies,
      );

      if (result.success) {
        _showSnackBar('🎉 Teste singleton passou!', Colors.green);
      } else {
        _showSnackBar('💥 Teste singleton falhou!', Colors.red);
      }
    } catch (e) {
      _showSnackBar('💥 Erro no teste singleton: $e', Colors.red);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = TestController.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Resolve - Sistema de Testes'),
        backgroundColor: Colors.blue.shade100,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/'),
            tooltip: 'Voltar para Home',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
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
                          errorMessage != null ? 'Status: Erro' : 'Status: OK',
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
                        onPressed: () {
                          setState(() {
                            _loadDependencies();
                            if (errorMessage == null && z != null) {
                              _showSnackBar('✅ Dependências recarregadas com sucesso!', Colors.green);
                            } else {
                              _showSnackBar('❌ Erro ao recarregar dependências', Colors.red);
                            }
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar Novamente'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ] else if (z != null) ...[
                      Text('HomeService: ${z!.homeService.name}'),
                      Text('Módulo atual: ${controller.currentModule ?? 'Nenhum'}'),
                      Text('Total de testes: ${controller.testCount}'),
                    ],
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
                      '🧪 Testes de Dependências',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _testBasicDependencies,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Teste Básico (Z,A,B)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _testAdvancedDependencies,
                          icon: const Icon(Icons.engineering),
                          label: const Text('Teste Avançado (C,D)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _testSingleton,
                          icon: const Icon(Icons.share),
                          label: const Text('Teste Singleton'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
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
                          label: const Text('Limpar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
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
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📊 Resultados dos Testes',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: controller.testResults.isEmpty
                            ? const Center(
                                child: Text(
                                  'Nenhum teste executado ainda.\nClique nos botões acima para testar!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
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
                                        style: TextStyle(
                                          color: result.success ? Colors.green.shade600 : Colors.red.shade600,
                                        ),
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
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Classes de dependência para teste
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

class Z {
  final HomeService homeService;
  Z(this.homeService);
}
