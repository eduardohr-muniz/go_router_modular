import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

void main() {
  group('BindContextExtension Tests', () {
    setUp(() {
      Bind.clearAll();
    });

    tearDown(() {
      Bind.clearAll();
    });

    testWidgets('should read dependency without key', (WidgetTester tester) async {
      // Arrange
      Bind.register(Bind.singleton<TestService>((i) => TestService('default')));

      // Act & Assert
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final service = context.read<TestService>();
              expect(service.value, equals('default'));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('should read dependency with key', (WidgetTester tester) async {
      // Arrange
      Bind.register(Bind.singleton<TestServiceWithKey>((i) => TestServiceWithKey('with-key'), key: 'test-key'));

      // Act & Assert
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // Note: context.read() doesn't support keys, so we test Bind.get() directly
              expect(Bind.get<TestServiceWithKey>(key: 'test-key').value, equals('with-key'));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('should throw exception when dependency not found', (WidgetTester tester) async {
      // Act & Assert
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(
                () => context.read<TestService>(),
                throwsA(isA<GoRouterModularException>()),
              );
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('should work with different types', (WidgetTester tester) async {
      // Arrange
      Bind.register(Bind.singleton<StringService>((i) => StringService('Hello World')));
      Bind.register(Bind.singleton<IntService>((i) => IntService(42)));
      Bind.register(Bind.singleton<BoolService>((i) => BoolService(true)));

      // Act & Assert
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(context.read<StringService>().value, equals('Hello World'));
              expect(context.read<IntService>().value, equals(42));
              expect(context.read<BoolService>().value, equals(true));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('should work with factory dependencies', (WidgetTester tester) async {
      // Arrange
      var counter = 0;
      Bind.register(Bind.factory<TestService>((i) => TestService('factory-${++counter}')));

      // Act & Assert
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final service1 = context.read<TestService>();
              final service2 = context.read<TestService>();

              // Factory should create new instances each time
              expect(service1, isNot(equals(service2)));
              expect(service1.value, isNot(equals(service2.value)));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('should work with lazy singleton dependencies', (WidgetTester tester) async {
      // Arrange
      var creationCount = 0;
      Bind.register(Bind.lazy<TestService>((i) {
        creationCount++;
        return TestService('lazy-$creationCount');
      }));

      // Act & Assert
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final service1 = context.read<TestService>();
              final service2 = context.read<TestService>();

              // Lazy singleton should create only one instance
              expect(service1, equals(service2));
              expect(creationCount, equals(1));
              expect(service1.value, equals('lazy-1'));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('should work with multiple keys for same type', (WidgetTester tester) async {
      // Arrange
      Bind.register(Bind.singleton<TestService>((i) => TestService('service-1'), key: 'key1'));
      Bind.register(Bind.singleton<TestService>((i) => TestService('service-2'), key: 'key2'));

      // Act & Assert
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // Note: context.read() doesn't support keys, so we test Bind.get() directly
              expect(Bind.get<TestService>(key: 'key1').value, equals('service-1'));
              expect(Bind.get<TestService>(key: 'key2').value, equals('service-2'));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('should work in different widget contexts', (WidgetTester tester) async {
      // Arrange
      Bind.register(Bind.singleton<TestService>((i) => TestService('shared')));

      // Act & Assert
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final service1 = context.read<TestService>();
              final service2 = context.read<TestService>();

              expect(service1.value, equals('shared'));
              expect(service2.value, equals('shared'));
              expect(service1, equals(service2));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('should handle Bind.get() directly', (WidgetTester tester) async {
      // Arrange
      Bind.register(Bind.singleton<TestService>((i) => TestService('direct')));

      // Act & Assert
      expect(() => Bind.get<TestService>(), returnsNormally);
      final service = Bind.get<TestService>();
      expect(service.value, equals('direct'));
    });
  });
}

// Test classes
class TestService {
  final String value;
  TestService(this.value);
}

class TestServiceWithKey {
  final String value;
  TestServiceWithKey(this.value);
}

class StringService {
  final String value;
  StringService(this.value);
}

class IntService {
  final int value;
  IntService(this.value);
}

class BoolService {
  final bool value;
  BoolService(this.value);
}
