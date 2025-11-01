import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/core/dependency_analyzer.dart';

class TestService {
  final String name;
  TestService(this.name);
}

void main() {
  group('Loop Infinito - Teste Simples', () {
    setUp(() {
      Bind.clearAll();
      DependencyAnalyzer.clearAll();
    });

    tearDown(() {
      Bind.clearAll();
      DependencyAnalyzer.clearAll();
    });

    test('Não deve entrar em loop infinito ao buscar bind não registrado', () {
      // Deve lançar exceção rapidamente, não entrar em loop
      expect(() => Bind.get<TestService>(), throwsA(isA<GoRouterModularException>()));

      // Verifica que não há tentativas pendentes após exceção
      expect(() => Bind.get<TestService>(), throwsA(isA<GoRouterModularException>()));

      // Se chegou aqui, não entrou em loop infinito
    });
  });
}
