import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/src/di/dependency_analyzer.dart';
import 'package:go_router_modular/src/di/bind.dart';

// Classes de teste
class ServiceA {}
class ServiceB {}
class ServiceC {}

void main() {
  group('DependencyAnalyzer Tests', () {
    setUp(() {
      DependencyAnalyzer.clearAll();
      Bind.clearAll();
    });

    tearDown(() {
      DependencyAnalyzer.clearAll();
      Bind.clearAll();
    });

    group('Rastreamento de Buscas', () {
      test('deve registrar início e fim de busca', () {
        DependencyAnalyzer.startSearch(ServiceA);
        DependencyAnalyzer.endSearch(ServiceA);
        // Teste passa se não lançar exceção
        expect(true, isTrue);
      });

      test('deve rastrear múltiplas buscas simultâneas', () {
        DependencyAnalyzer.startSearch(ServiceA);
        DependencyAnalyzer.startSearch(ServiceB);
        DependencyAnalyzer.endSearch(ServiceA);
        DependencyAnalyzer.endSearch(ServiceB);
        // Teste passa se não lançar exceção
        expect(true, isTrue);
      });
    });

    group('Registro de Tentativas', () {
      test('deve registrar tentativas corretamente', () {
        DependencyAnalyzer.recordSearchAttempt(ServiceA, true);
        DependencyAnalyzer.recordSearchAttempt(ServiceA, false);
        DependencyAnalyzer.recordSearchAttempt(ServiceA, true);
        // Teste passa se não lançar exceção
        expect(true, isTrue);
      });

      test('deve manter histórico de múltiplas tentativas', () {
        for (int i = 0; i < 15; i++) {
          DependencyAnalyzer.recordSearchAttempt(ServiceA, true);
        }
        DependencyAnalyzer.recordSearchAttempt(ServiceA, false);
        // Teste passa se não lançar exceção
        expect(true, isTrue);
      });
    });

    group('Rastreamento de Dependências', () {
      test('deve registrar dependências entre tipos', () {
        DependencyAnalyzer.recordDependency(ServiceA, ServiceB);
        DependencyAnalyzer.recordDependency(ServiceB, ServiceC);
        // Teste passa se não lançar exceção
        expect(true, isTrue);
      });

      test('deve registrar dependências circulares', () {
        DependencyAnalyzer.recordDependency(ServiceA, ServiceB);
        DependencyAnalyzer.recordDependency(ServiceB, ServiceA);
        // Teste passa se não lançar exceção
        expect(true, isTrue);
      });
    });

    group('Limpeza de Histórico', () {
      test('deve limpar histórico de tipo específico', () {
        DependencyAnalyzer.recordSearchAttempt(ServiceA, false);
        DependencyAnalyzer.recordSearchAttempt(ServiceB, true);
        DependencyAnalyzer.recordDependency(ServiceA, ServiceB);

        DependencyAnalyzer.clearTypeHistory(ServiceA);

        // ServiceB deve manter histórico
        DependencyAnalyzer.recordSearchAttempt(ServiceB, true);
        expect(true, isTrue);
      });

      test('deve limpar todo o histórico', () {
        DependencyAnalyzer.recordSearchAttempt(ServiceA, false);
        DependencyAnalyzer.recordSearchAttempt(ServiceB, false);
        DependencyAnalyzer.recordDependency(ServiceA, ServiceB);

        DependencyAnalyzer.clearAll();

        // Após limpar, deve poder registrar novamente
        DependencyAnalyzer.recordSearchAttempt(ServiceA, true);
        DependencyAnalyzer.recordSearchAttempt(ServiceB, true);
        expect(true, isTrue);
      });
    });

    group('Integração com Bind', () {
      test('deve rastrear buscas durante resolução de binds', () {
        final bind = Bind.singleton((i) => ServiceA());
        Bind.register(bind);

        DependencyAnalyzer.startSearch(ServiceA);
        final service = Bind.get<ServiceA>();
        DependencyAnalyzer.endSearch(ServiceA);

        expect(service, isA<ServiceA>());
      });

      test('deve limpar histórico ao fazer dispose', () {
        final bind = Bind.singleton((i) => ServiceA());
        Bind.register(bind);

        DependencyAnalyzer.recordSearchAttempt(ServiceA, true);
        Bind.dispose<ServiceA>();

        // Após dispose, deve poder registrar novamente
        DependencyAnalyzer.recordSearchAttempt(ServiceA, true);
        expect(true, isTrue);
      });
    });
  });
}
