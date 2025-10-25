import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

// Test interfaces
abstract class IService {
  String get name;
  void doSomething();
}

abstract class IRepository {
  String get data;
  void save(String value);
}

abstract class IController {
  void handleRequest();
}

// Test implementations
class ServiceImpl implements IService {
  @override
  String get name => 'ServiceImplementation';

  @override
  void doSomething() {
    print('Service doing something...');
  }
}

class RepositoryImpl implements IRepository {
  @override
  String get data => 'Repository data';

  @override
  void save(String value) {
    print('Saving: $value');
  }
}

class ControllerImpl implements IController {
  final IService service;

  ControllerImpl(this.service);

  @override
  void handleRequest() {
    service.doSomething();
  }
}

void main() {
  setUp(() {
    Bind.clearAll();
  });

  group('Bind Interface Resolution Tests - Seguindo padrão auto_injector', () {
    group('Explicit Interface Registration', () {
      test('should resolve when interface is explicitly registered', () {
        // Arrange - No auto_injector, você registra explicitamente a interface
        final bind = Bind.singleton<IService>((i) => ServiceImpl());
        Bind.register(bind);

        // Act
        final service = Bind.get<IService>();

        // Assert
        expect(service, isA<IService>());
        expect(service, isA<ServiceImpl>());
        expect(service.name, 'ServiceImplementation');
      });

      test('should resolve concrete implementation when registered', () {
        // Arrange - Registrar o tipo concreto
        final bind = Bind.singleton<ServiceImpl>((i) => ServiceImpl());
        Bind.register(bind);

        // Act
        final service = Bind.get<ServiceImpl>();

        // Assert
        expect(service, isA<ServiceImpl>());
        expect(service.name, 'ServiceImplementation');
      });

      test('should allow both interface and concrete registration', () {
        // Arrange - Registrar ambos explicitamente
        final implementation = ServiceImpl();

        final concreteBind = Bind.singleton<ServiceImpl>((i) => implementation);
        final interfaceBind = Bind.singleton<IService>((i) => implementation);

        Bind.register(concreteBind);
        Bind.register(interfaceBind);

        // Act
        final serviceViaInterface = Bind.get<IService>();
        final serviceViaConcrete = Bind.get<ServiceImpl>();

        // Assert - Ambos retornam a mesma instância
        expect(serviceViaInterface, same(serviceViaConcrete));
        expect(serviceViaInterface.name, 'ServiceImplementation');
      });
    });

    group('Factory vs Singleton with Interfaces', () {
      test('should resolve factory bind through interface', () {
        // Arrange
        final bind = Bind.factory<IService>((i) => ServiceImpl());
        Bind.register(bind);

        // Act
        final service1 = Bind.get<IService>();
        final service2 = Bind.get<IService>();

        // Assert - Factory cria novas instâncias
        expect(service1, isNot(same(service2)));
        expect(service1, isA<IService>());
        expect(service2, isA<IService>());
      });

      test('should resolve singleton bind through interface', () {
        // Arrange
        final bind = Bind.singleton<IService>((i) => ServiceImpl());
        Bind.register(bind);

        // Act
        final service1 = Bind.get<IService>();
        final service2 = Bind.get<IService>();

        // Assert - Singleton retorna a mesma instância
        expect(service1, same(service2));
        expect(service1, isA<IService>());
      });
    });

    group('Complex Dependencies with Interfaces', () {
      test('should resolve controller with service dependency through interface', () {
        // Arrange - Registrar dependências
        final serviceBind = Bind.singleton<IService>((i) => ServiceImpl());
        final controllerBind = Bind.singleton<IController>((i) => ControllerImpl(i.get<IService>()));

        Bind.register(serviceBind);
        Bind.register(controllerBind);

        // Act
        final controller = Bind.get<IController>();

        // Assert
        expect(controller, isA<IController>());
        expect(controller, isA<ControllerImpl>());
        expect(() => controller.handleRequest(), returnsNormally);
      });

      test('should resolve multiple implementations with different keys', () {
        // Arrange - Múltiplas implementações com keys diferentes
        final bind1 = Bind.singleton<IService>((i) => ServiceImpl(), key: 'service1');
        final bind2 = Bind.singleton<IService>((i) => ServiceImpl(), key: 'service2');

        Bind.register(bind1);
        Bind.register(bind2);

        // Act
        final service1 = Bind.get<IService>(key: 'service1');
        final service2 = Bind.get<IService>(key: 'service2');

        // Assert - Instâncias diferentes
        expect(service1, isNot(same(service2)));
        expect(service1, isA<IService>());
        expect(service2, isA<IService>());
      });

      test('should resolve interface with repository dependency', () {
        // Arrange
        final repoBind = Bind.singleton<IRepository>((i) => RepositoryImpl());
        Bind.register(repoBind);

        // Act
        final repo = Bind.get<IRepository>();

        // Assert
        expect(repo, isA<IRepository>());
        expect(repo.data, 'Repository data');
      });
    });

    group('Error Handling', () {
      test('should throw exception when interface is not registered', () {
        // Act & Assert - Interface não registrada
        expect(
          () => Bind.get<IService>(),
          throwsA(isA<GoRouterModularException>()),
        );
      });

      test('should throw exception when concrete class is not registered', () {
        // Arrange - Registrar apenas a interface
        final bind = Bind.singleton<IService>((i) => ServiceImpl());
        Bind.register(bind);

        // Act & Assert - Tipo concreto não foi registrado
        expect(
          () => Bind.get<ServiceImpl>(),
          throwsA(isA<GoRouterModularException>()),
        );
      });

      test('should handle dispose of interface bind correctly', () {
        // Arrange
        final bind = Bind.singleton<IService>((i) => ServiceImpl());
        Bind.register(bind);

        final service = Bind.get<IService>();
        expect(service, isA<IService>());

        // Act
        Bind.dispose<IService>();

        // Assert - Seguindo padrão auto_injector: bind continua registrado
        final newService = Bind.get<IService>();
        expect(newService, isNot(same(service)));
      });
    });

    group('Typed Injection Tests - Padrão auto_injector', () {
      test('should resolve with typed singleton registration', () {
        // Arrange - Registro tipado explícito
        final bind = Bind.singleton<IService>((i) => ServiceImpl());
        Bind.register(bind);

        // Act
        final service = Bind.get<IService>();

        // Assert
        expect(service, isA<IService>());
        expect(service.name, 'ServiceImplementation');
      });

      test('should resolve with typed factory registration', () {
        // Arrange
        final bind = Bind.factory<IService>((i) => ServiceImpl());
        Bind.register(bind);

        // Act
        final service1 = Bind.get<IService>();
        final service2 = Bind.get<IService>();

        // Assert - Factory cria novas instâncias
        expect(service1, isNot(same(service2)));
      });

      test('should resolve multiple typed registrations', () {
        // Arrange
        final serviceBind = Bind.singleton<IService>((i) => ServiceImpl());
        final repoBind = Bind.singleton<IRepository>((i) => RepositoryImpl());

        Bind.register(serviceBind);
        Bind.register(repoBind);

        // Act
        final service = Bind.get<IService>();
        final repo = Bind.get<IRepository>();

        // Assert
        expect(service, isA<IService>());
        expect(repo, isA<IRepository>());
      });

      test('should resolve complex dependencies with typed registrations', () {
        // Arrange
        final serviceBind = Bind.singleton<IService>((i) => ServiceImpl());
        final repoBind = Bind.singleton<IRepository>((i) => RepositoryImpl());
        final controllerBind = Bind.singleton<IController>((i) => ControllerImpl(i.get<IService>()));

        Bind.register(serviceBind);
        Bind.register(repoBind);
        Bind.register(controllerBind);

        // Act
        final controller = Bind.get<IController>();

        // Assert
        expect(controller, isA<IController>());
      });

      test('should handle mixed typed registrations', () {
        // Arrange - Mix de interfaces e implementações
        final serviceBind = Bind.singleton<IService>((i) => ServiceImpl());
        final concreteRepoBind = Bind.singleton<RepositoryImpl>((i) => RepositoryImpl());

        Bind.register(serviceBind);
        Bind.register(concreteRepoBind);

        // Act
        final service = Bind.get<IService>();
        final repo = Bind.get<RepositoryImpl>();

        // Assert
        expect(service, isA<IService>());
        expect(repo, isA<RepositoryImpl>());
      });
    });

    group('Real World Scenario - Padrão auto_injector', () {
      test('should simulate real application with explicit interface registration', () {
        // Arrange - Simular aplicação real com registro explícito
        final repoBind = Bind.singleton<IRepository>((i) => RepositoryImpl());
        final serviceBind = Bind.singleton<IService>((i) => ServiceImpl());
        final controllerBind = Bind.singleton<IController>((i) => ControllerImpl(i.get<IService>()));

        Bind.register(repoBind);
        Bind.register(serviceBind);
        Bind.register(controllerBind);

        // Act
        final controller = Bind.get<IController>();
        final service = Bind.get<IService>();
        final repo = Bind.get<IRepository>();

        // Assert
        expect(controller, isA<IController>());
        expect(service, isA<IService>());
        expect(repo, isA<IRepository>());
        expect(() => controller.handleRequest(), returnsNormally);
      });

      test('should handle multiple modules with same interface using keys', () {
        // Arrange - Múltiplos módulos com mesma interface
        final module1Service = Bind.singleton<IService>((i) => ServiceImpl(), key: 'module1');
        final module2Service = Bind.singleton<IService>((i) => ServiceImpl(), key: 'module2');

        Bind.register(module1Service);
        Bind.register(module2Service);

        // Act
        final service1 = Bind.get<IService>(key: 'module1');
        final service2 = Bind.get<IService>(key: 'module2');

        // Assert
        expect(service1, isNot(same(service2)));
        expect(service1, isA<IService>());
        expect(service2, isA<IService>());
      });
    });

    group('Key-based Registration', () {
      test('should resolve with key-based registration', () {
        // Arrange
        final bind = Bind.singleton<IService>((i) => ServiceImpl(), key: 'my-service');
        Bind.register(bind);

        // Act
        final service = Bind.get<IService>(key: 'my-service');

        // Assert
        expect(service, isA<IService>());
        expect(service.name, 'ServiceImplementation');
      });

      test('should throw when key does not match', () {
        // Arrange
        final bind = Bind.singleton<IService>((i) => ServiceImpl(), key: 'service1');
        Bind.register(bind);

        // Act & Assert - Key diferente
        expect(
          () => Bind.get<IService>(key: 'service2'),
          throwsA(isA<GoRouterModularException>()),
        );
      });

      test('should allow same type with different keys', () {
        // Arrange
        final bind1 = Bind.singleton<IService>((i) => ServiceImpl(), key: 'service1');
        final bind2 = Bind.singleton<IService>((i) => ServiceImpl(), key: 'service2');

        Bind.register(bind1);
        Bind.register(bind2);

        // Act
        final service1 = Bind.get<IService>(key: 'service1');
        final service2 = Bind.get<IService>(key: 'service2');

        // Assert
        expect(service1, isNot(same(service2)));
      });
    });
  });
}
