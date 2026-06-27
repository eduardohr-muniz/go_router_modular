import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/src/di/bind.dart';
import 'package:go_router_modular/src/di/injector.dart';

// ======================== SERVIÇOS ========================

class ServiceX {
  ServiceX();
}

class ServiceY {
  static int constructorCalls = 0;
  final String origin;
  ServiceY(this.origin) {
    constructorCalls++;
  }
}

class ServiceZ {
  ServiceZ();
}

// ======================== SIMULAÇÃO DOS MÓDULOS ========================
//
// ModuleB: binds X, Y(from-B), Z
// ModuleC: binds Y(from-C)   ← mesmo tipo que B
// ModuleA: imports B + C, também declara Y(from-A)
//
// Antes do fix: _processInstance era chamado ANTES de _isSingletonAlreadyRegistered,
// então a factory de toda Y duplicada era executada, criando instâncias órfãs.
//
// Após o fix: quando bind.type != Object, a factory nunca é chamada se o tipo
// já estiver em bindsMap — zero instâncias órfãs.

List<Bind<Object>> _bindsModuleB() {
  final injector = Injector();
  injector.startRegistering();
  injector.addSingleton((i) => ServiceX());
  injector.addSingleton((i) => ServiceY('from-B'));
  injector.addSingleton((i) => ServiceZ());
  return injector.finishRegistering();
}

List<Bind<Object>> _bindsModuleC() {
  final injector = Injector();
  injector.startRegistering();
  injector.addSingleton((i) => ServiceY('from-C'));
  return injector.finishRegistering();
}

List<Bind<Object>> _bindsModuleA() {
  final injector = Injector();
  injector.startRegistering();
  injector.addSingleton((i) => ServiceY('from-A'));
  return injector.finishRegistering();
}

// ======================== TESTES ========================

void main() {
  group('Duplicate bind import', () {
    final injector = Injector();

    setUp(() {
      Bind.clearAll();
      ServiceY.constructorCalls = 0;
    });

    tearDown(() {
      Bind.clearAll();
      ServiceY.constructorCalls = 0;
    });

    test('baseline: Module B com X,Y,Z registra exatamente 1 instância de ServiceY', () {
      final allBinds = _bindsModuleB();
      Bind.registerBatch(allBinds);
      Bind.commitBatch(injector);

      expect(ServiceY.constructorCalls, 1);
      expect(Bind.get<ServiceY>().origin, 'from-B');
    });

    test(
      'Module A importa B(X,Y,Z) e C(Y) — ServiceY é instanciado apenas 1x (from-B vence)',
      () {
        // Simula _collectImportedBinds: une binds de B e C numa lista
        final allBinds = [..._bindsModuleB(), ..._bindsModuleC()];
        Bind.registerBatch(allBinds);
        Bind.commitBatch(injector);

        // Fix: a factory de Y_C nunca é chamada — bindsMap[ServiceY] já tem Y_B
        // quando Y_C chega ao fast-path.
        expect(
          ServiceY.constructorCalls,
          1,
          reason: 'Apenas a factory de Y_B deve ser invocada; Y_C é ignorado sem instanciar',
        );

        expect(Bind.get<ServiceY>().origin, 'from-B');
      },
    );

    test(
      'Module A também declara Y: apenas 1 instância criada, Y de A vence',
      () {
        // allBinds simula: módulo A no início, depois imports de B e C
        final allBinds = [
          ..._bindsModuleA(), // A's próprio Y vem antes dos imports
          ..._bindsModuleB(),
          ..._bindsModuleC(),
        ];
        Bind.registerBatch(allBinds);
        Bind.commitBatch(injector);

        // Fix: Y_B e Y_C são pulados via fast-path — apenas Y_A é instanciado.
        expect(
          ServiceY.constructorCalls,
          1,
          reason: 'Apenas Y de A deve ser instanciado; Y de B e C são ignorados sem instanciar',
        );

        expect(Bind.get<ServiceY>().origin, 'from-A');
      },
    );
  });
}
