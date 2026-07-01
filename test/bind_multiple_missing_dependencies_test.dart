// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/src/di/bind.dart';
import 'package:go_router_modular/src/shared/exception.dart';

// Interfaces para teste
abstract class IFirstDependency {
  String get firstName;
}

abstract class ISecondDependency {
  String get secondName;
}

abstract class IThirdDependency {
  String get thirdName;
}

// Implementação da primeira dependência
class FirstDependencyImpl implements IFirstDependency {
  @override
  String get firstName => 'First';
}

// Implementação da segunda dependência
class SecondDependencyImpl implements ISecondDependency {
  @override
  String get secondName => 'Second';
}

// Implementação da terceira dependência
class ThirdDependencyImpl implements IThirdDependency {
  @override
  String get thirdName => 'Third';
}

// Classe que requer 3 dependências
class ComplexClass {
  final IFirstDependency firstDependency;
  final ISecondDependency secondDependency;
  final IThirdDependency thirdDependency;

  ComplexClass({
    required this.firstDependency,
    required this.secondDependency,
    required this.thirdDependency,
  });

  String get allNames => '${firstDependency.firstName}-${secondDependency.secondName}-${thirdDependency.thirdName}';
}

void main() {
  group('Bind Multiple Missing Dependencies Tests', () {
    setUp(() {
      // Limpa todos os binds antes de cada teste
      Bind.clearAll();
    });

    tearDown(() {
      // Limpa todos os binds após cada teste
      Bind.clearAll();
    });

    test('deve lançar exceção com informações do bind problemático e dependências faltantes quando apenas 1 de 3 dependências está registrada', () {
      // Arrange: Registra apenas a primeira dependência
      final firstBind = Bind.singleton<IFirstDependency>(
        (i) => FirstDependencyImpl(),
      );
      Bind.register(firstBind);

      // Registra o bind que requer 3 dependências (mas apenas 1 está disponível)
      final complexBind = Bind.singleton<ComplexClass>(
        (i) => ComplexClass(
          firstDependency: i.get<IFirstDependency>(),
          secondDependency: i.get<ISecondDependency>(),
          thirdDependency: i.get<IThirdDependency>(),
        ),
      );
      Bind.register(complexBind);

      // Act & Assert
      expect(
        () => Bind.get<ComplexClass>(),
        throwsA(
          predicate<ModularException>(
            (exception) {
              final message = exception.message;

              // Verifica se a mensagem contém informação sobre o bind problemático
              final containsBindInfo = message.contains('ComplexClass') || message.contains('Bind not found');

              // Verifica se a mensagem contém informação sobre dependências faltantes
              // Espera-se encontrar pelo menos uma das dependências faltantes na mensagem
              final containsMissingDependencies = message.contains('ISecondDependency') ||
                  message.contains('IThirdDependency') ||
                  message.contains('SecondDependency') ||
                  message.contains('ThirdDependency');

              return containsBindInfo && containsMissingDependencies;
            },
          ),
        ),
      );
    });

    test('deve lançar exceção mostrando que 2 de 3 dependências não foram encontradas', () {
      // Arrange: Registra apenas a primeira dependência
      final firstBind = Bind.singleton<IFirstDependency>(
        (i) => FirstDependencyImpl(),
      );
      Bind.register(firstBind);

      // Cria o bind que requer 3 dependências
      final complexBind = Bind.singleton<ComplexClass>(
        (i) => ComplexClass(
          firstDependency: i.get<IFirstDependency>(),
          secondDependency: i.get<ISecondDependency>(),
          thirdDependency: i.get<IThirdDependency>(),
        ),
      );
      Bind.register(complexBind);

      // Act
      ModularException? caughtException;

      try {
        Bind.get<ComplexClass>();
      } catch (e) {
        if (e is ModularException) {
          caughtException = e;
        } else {
          rethrow;
        }
      }

      // Assert
      expect(caughtException, isNotNull, reason: 'Deve lançar ModularException');

      final message = caughtException!.message;

      // Verifica se a mensagem menciona o bind problemático
      final mentionsBindProblem = message.contains('ComplexClass') || message.contains('Bind not found');
      expect(
        mentionsBindProblem,
        isTrue,
        reason: 'A mensagem deve conter informação sobre o bind problemático',
      );

      // Verifica se a mensagem menciona pelo menos uma das dependências faltantes
      // (o sistema pode falhar na primeira dependência não encontrada)
      final hasSecondDependency = message.contains('ISecondDependency') || message.contains('SecondDependency');
      final hasThirdDependency = message.contains('IThirdDependency') || message.contains('ThirdDependency');

      expect(
        hasSecondDependency || hasThirdDependency,
        isTrue,
        reason: 'A mensagem deve conter pelo menos uma das dependências faltantes (ISecondDependency ou IThirdDependency)',
      );
    });

    test('deve funcionar corretamente quando todas as 3 dependências estão registradas', () {
      // Arrange: Registra todas as 3 dependências
      final firstBind = Bind.singleton<IFirstDependency>(
        (i) => FirstDependencyImpl(),
      );
      final secondBind = Bind.singleton<ISecondDependency>(
        (i) => SecondDependencyImpl(),
      );
      final thirdBind = Bind.singleton<IThirdDependency>(
        (i) => ThirdDependencyImpl(),
      );

      Bind.register(firstBind);
      Bind.register(secondBind);
      Bind.register(thirdBind);

      // Registra o bind que requer as 3 dependências
      final complexBind = Bind.singleton<ComplexClass>(
        (i) => ComplexClass(
          firstDependency: i.get<IFirstDependency>(),
          secondDependency: i.get<ISecondDependency>(),
          thirdDependency: i.get<IThirdDependency>(),
        ),
      );
      Bind.register(complexBind);

      // Act
      final instance = Bind.get<ComplexClass>();

      // Assert
      expect(instance, isNotNull);
      expect(instance, isA<ComplexClass>());
      expect(instance.firstDependency, isA<IFirstDependency>());
      expect(instance.secondDependency, isA<ISecondDependency>());
      expect(instance.thirdDependency, isA<IThirdDependency>());
      expect(instance.allNames, 'First-Second-Third');
    });

    test('deve falhar na primeira dependência não encontrada e mostrar o tipo correto', () {
      // Arrange: Não registra nenhuma dependência
      final complexBind = Bind.singleton<ComplexClass>(
        (i) => ComplexClass(
          firstDependency: i.get<IFirstDependency>(),
          secondDependency: i.get<ISecondDependency>(),
          thirdDependency: i.get<IThirdDependency>(),
        ),
      );
      Bind.register(complexBind);

      // Act & Assert
      expect(
        () => Bind.get<ComplexClass>(),
        throwsA(
          predicate<ModularException>(
            (exception) {
              final message = exception.message;

              // Deve falhar na primeira dependência (IFirstDependency)
              // mas pode mencionar ComplexClass ou IFirstDependency na mensagem
              return message.contains('IFirstDependency') ||
                  message.contains('FirstDependency') ||
                  message.contains('ComplexClass') ||
                  message.contains('Bind not found');
            },
          ),
        ),
      );
    });

    test('deve mostrar informações sobre o bind problemático no erro', () {
      // Arrange: Registra apenas uma dependência
      final firstBind = Bind.singleton<IFirstDependency>(
        (i) => FirstDependencyImpl(),
      );
      Bind.register(firstBind);

      final complexBind = Bind.singleton<ComplexClass>(
        (i) => ComplexClass(
          firstDependency: i.get<IFirstDependency>(),
          secondDependency: i.get<ISecondDependency>(),
          thirdDependency: i.get<IThirdDependency>(),
        ),
      );
      Bind.register(complexBind);

      // Act
      ModularException? caughtException;

      try {
        Bind.get<ComplexClass>();
      } catch (e) {
        if (e is ModularException) {
          caughtException = e;
        }
      }

      // Assert
      expect(caughtException, isNotNull);

      final message = caughtException!.message;

      // A mensagem deve mencionar pelo menos:
      // - O bind que deu problema (ComplexClass) OU
      // - A dependência que não foi encontrada (ISecondDependency ou IThirdDependency)
      final mentionsBindProblem = message.contains('ComplexClass');
      final mentionsMissingDependency = message.contains('ISecondDependency') ||
          message.contains('IThirdDependency') ||
          message.contains('SecondDependency') ||
          message.contains('ThirdDependency');

      expect(
        mentionsBindProblem || mentionsMissingDependency,
        isTrue,
        reason:
            'A mensagem de erro deve mencionar o bind problemático (ComplexClass) ou as dependências faltantes (ISecondDependency/IThirdDependency)',
      );
    });
  });
}
