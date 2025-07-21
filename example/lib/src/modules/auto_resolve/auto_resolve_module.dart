import 'dart:async';

import 'package:example/src/modules/home/home_module.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AutoResolveModule extends Module {
  @override
  FutureOr<List<Bind<Object>>> binds() {
    return [
      Bind.singleton((i) => HomeService()),
      Bind.factory((i) => Z(i.get())),
      Bind.factory((i) => A(i.get())),
      Bind.factory((i) => B(i.get())),
      Bind.factory((i) => C(i.get())),
      Bind.factory((i) => D(i.get())),
    ];
  }

  @override
  List<ModularRoute> get routes => [
        ChildRoute('/', child: (context, args) => const AutoResolveModuleWidget()),
      ];
}

class AutoResolveModuleWidget extends StatefulWidget {
  const AutoResolveModuleWidget({super.key});

  @override
  State<AutoResolveModuleWidget> createState() => _AutoResolveModuleWidgetState();
}

class _AutoResolveModuleWidgetState extends State<AutoResolveModuleWidget> {
  late Z? z;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDependencies();
  }

  void _loadDependencies() {
    try {
      z = Modular.get<Z>();
      errorMessage = null;
    } catch (e) {
      z = null;
      errorMessage = 'Erro ao carregar dependências: $e';
      print('Erro no AutoResolveModuleWidget: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Resolve'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  border: Border.all(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Erro:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    Text(errorMessage!),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loadDependencies();
                  });
                },
                child: const Text('Tentar Novamente'),
              ),
            ] else if (z != null) ...[
              Text(
                'Auto Resolve: ${z!.homeService.name}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  try {
                    print('Testing new container system:');
                    print('Z: ${Modular.get<Z>().homeService.name}');
                    print('A: ${Modular.get<A>()}');
                    print('B: ${Modular.get<B>()}');
                  } catch (e) {
                    print('Erro ao testar: $e');
                  }
                },
                child: const Text('Testar Dependências'),
              ),
            ] else ...[
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
          ],
        ),
      ),
    );
  }
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

class Z {
  final HomeService homeService;

  Z(this.homeService);
}
