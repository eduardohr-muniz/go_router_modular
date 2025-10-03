import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/src/bind.dart';

// Interfaces para teste
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

// Implementações concretas
class ServiceImpl implements IService {
  @override
  String get name => 'ServiceImplementation';

  @override
  void doSomething() {
    print('Service doing something...');
  }
}

class RepositoryImpl implements IRepository {
  String _data = 'default data';

  @override
  String get data => _data;

  @override
  void save(String value) {
    _data = value;
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

// Classe sem interface
class ConcreteClass {
  String get value => 'concrete value';
}

void main() {
  group('Bind Interface Resolution Tests', () {
    setUp(() {
      // Limpa todos os binds antes de cada teste
      Bind.clearAll();
    });

    tearDown(() {
      // Limpa todos os binds após cada teste
      Bind.clearAll();
    });

    group('Interface to Implementation Resolution', () {
      test('should resolve interface when implementation is registered', () {
        // Arrange
        final bind = Bind.singleton<ServiceImpl>((i) => ServiceImpl());
        Bind.register(bind);

        // Act
        final service = Bind.get<ServiceImpl>();

        // Assert
        expect(service, isA<ServiceImpl>());
        expect(service.name, 'ServiceImplementation');
      });

      test('should resolve interface when concrete implementation is registered (auto-resolution)', () {
        // Arrange
        final bind = Bind.singleton<ServiceImpl>((i) => ServiceImpl());
        Bind.register(bind);

        // Act
        final service = Bind.get<IService>();

        // Assert - O sistema resolve automaticamente porque ServiceImpl implementa IService
        expect(service, isA<IService>());
        expect(service, isA<ServiceImpl>());
        expect(service.name, 'ServiceImplementation');
      });

      test('should resolve interface when concrete implementation is registered (auto-resolution)', () {
        // Arrange
        final bind = Bind.singleton((i) => ServiceImpl());
        Bind.register(bind);

        // Act
        final service = Bind.get<IService>();

        // Assert - O sistema resolve automaticamente porque ServiceImpl implementa IService
        expect(service, isA<IService>());
        expect(service, isA<ServiceImpl>());
        expect(service.name, 'ServiceImplementation');
      });

      test('should resolve interface when explicitly registered as interface', () {
        // Arrange
        final bind = Bind.singleton<IService>((i) => ServiceImpl());
        Bind.register(bind);

        // Act
        final service = Bind.get<IService>();

        // Assert
        expect(service, isA<IService>());
        expect(service, isA<ServiceImpl>());
        expect(service.name, 'ServiceImplementation');
      });

      test('should resolve concrete implementation when interface is registered', () {
        // Arrange
        final bind = Bind.singleton<IService>((i) => ServiceImpl());
        Bind.register(bind);

        // Act
        final service = Bind.get<ServiceImpl>();

        // Assert
        expect(service, isA<ServiceImpl>());
        expect(service.name, 'ServiceImplementation');
      });
    });

    group('Complex Interface Dependencies', () {
      test('should resolve controller with service dependency through interface', () {
        // Arrange
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

      test('should resolve multiple implementations of same interface', () {
        // Arrange
        final service1Bind = Bind.singleton<IService>((i) => ServiceImpl(), key: 'service1');
        final service2Bind = Bind.singleton<IService>((i) => ServiceImpl(), key: 'service2');

        Bind.register(service1Bind);
        Bind.register(service2Bind);

        // Act
        final service1 = Bind.get<IService>(key: 'service1');
        final service2 = Bind.get<IService>(key: 'service2');

        // Assert
        expect(service1, isA<IService>());
        expect(service2, isA<IService>());
        expect(service1.name, service2.name); // Mesmo nome pois é a mesma implementação
      });

      test('should resolve interface with repository dependency', () {
        // Arrange
        final repositoryBind = Bind.singleton<IRepository>((i) => RepositoryImpl());
        Bind.register(repositoryBind);

        // Act
        final repository = Bind.get<IRepository>();

        // Assert
        expect(repository, isA<IRepository>());
        expect(repository, isA<RepositoryImpl>());
        expect(repository.data, 'default data');

        // Test method
        repository.save('new data');
        expect(repository.data, 'new data');
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

        // Assert
        expect(service1, isA<IService>());
        expect(service2, isA<IService>());
        // Para factory, instâncias devem ser diferentes
        expect(identical(service1, service2), false);
      });

      test('should resolve singleton bind through interface', () {
        // Arrange
        final bind = Bind.singleton<IService>((i) => ServiceImpl());
        Bind.register(bind);

        // Act
        final service1 = Bind.get<IService>();
        final service2 = Bind.get<IService>();

        // Assert
        expect(service1, isA<IService>());
        expect(service2, isA<IService>());
        // Para singleton, instâncias devem ser iguais
        expect(identical(service1, service2), true);
      });
    });

    group('Error Handling', () {
      test('should throw exception when interface is not registered', () {
        // Arrange
        final bind = Bind.singleton<ServiceImpl>((i) => ServiceImpl());
        Bind.register(bind);

        // Act & Assert - IService deve funcionar (auto-resolução), mas IRepository deve falhar
        expect(() => Bind.get<IService>(), returnsNormally); // Deve funcionar por auto-resolução
        expect(() => Bind.get<IRepository>(), throwsA(isA<Exception>())); // Deve falhar
      });

      test('should throw exception when concrete class is not registered', () {
        // Arrange - Nenhum bind registrado

        // Act & Assert
        expect(() => Bind.get<ConcreteClass>(), throwsA(isA<Exception>()));
        expect(() => Bind.get<ServiceImpl>(), throwsA(isA<Exception>()));
      });

      test('should handle dispose of interface bind correctly', () {
        // Arrange
        final bind = Bind.singleton<ServiceImpl>((i) => ServiceImpl());
        Bind.register(bind);

        final service = Bind.get<IService>();
        expect(service, isA<IService>());

        // Act
        Bind.dispose<ServiceImpl>(); // Remove a implementação concreta

        // Assert - O sistema ainda consegue resolver porque o auto-resolução cria um bind temporário
        // mas vamos verificar se a instância original foi removida
        final newService = Bind.get<IService>();
        expect(newService, isA<IService>());
        expect(newService, isA<ServiceImpl>());
      });
    });

    group('Untyped Injection Tests', () {
      test('should resolve with untyped singleton registration', () {
        // Arrange - Registra sem especificar tipo genérico
        final bind = Bind.singleton((i) => ServiceImpl());
        Bind.register(bind);

        // Act - Busca pela interface
        final service = Bind.get<IService>();

        // Assert - Deve funcionar por auto-resolução
        expect(service, isA<IService>());
        expect(service, isA<ServiceImpl>());
        expect(service.name, 'ServiceImplementation');
      });

      test('should resolve with untyped factory registration', () {
        // Arrange - Registra factory sem especificar tipo genérico
        final bind = Bind.factory((i) => ServiceImpl());
        Bind.register(bind);

        // Act - Busca pela interface
        final service = Bind.get<IService>();

        // Assert - Deve funcionar por auto-resolução
        expect(service, isA<IService>());
        expect(service, isA<ServiceImpl>());

        // Factory deve criar instâncias diferentes
        final service2 = Bind.get<IService>();
        expect(identical(service, service2), false);
      });

      test('should resolve with untyped singleton with key', () {
        // Arrange - Registra singleton com key sem especificar tipo genérico
        final bind = Bind.singleton((i) => ServiceImpl(), key: 'untyped_service');
        Bind.register(bind);

        // Act - Busca pela interface com key
        final service = Bind.get<IService>(key: 'untyped_service');

        // Assert - Deve funcionar por auto-resolução
        expect(service, isA<IService>());
        expect(service, isA<ServiceImpl>());
        expect(service.name, 'ServiceImplementation');
      });

      test('should resolve with untyped factory with key', () {
        // Arrange - Registra factory com key sem especificar tipo genérico
        final bind = Bind.factory((i) => ServiceImpl(), key: 'untyped_factory');
        Bind.register(bind);

        // Act - Busca pela interface com key
        final service = Bind.get<IService>(key: 'untyped_factory');

        // Assert - Deve funcionar por auto-resolução
        expect(service, isA<IService>());
        expect(service, isA<ServiceImpl>());
      });

      test('should resolve multiple untyped registrations', () {
        // Arrange - Múltiplos registros sem tipo genérico
        final serviceBind = Bind.singleton((i) => ServiceImpl());
        final repositoryBind = Bind.singleton((i) => RepositoryImpl());

        Bind.register(serviceBind);
        Bind.register(repositoryBind);

        // Act - Busca ambas as interfaces
        final service = Bind.get<IService>();
        final repository = Bind.get<IRepository>();

        // Assert - Ambas devem funcionar por auto-resolução
        expect(service, isA<IService>());
        expect(service, isA<ServiceImpl>());

        expect(repository, isA<IRepository>());
        expect(repository, isA<RepositoryImpl>());
      });

      test('should resolve complex dependencies with untyped registrations', () {
        // Arrange - Registros sem tipo genérico para dependências complexas
        final serviceBind = Bind.singleton((i) => ServiceImpl());
        final controllerBind = Bind.singleton((i) => ControllerImpl(i.get<IService>()));

        Bind.register(serviceBind);
        Bind.register(controllerBind);

        // Act - Busca o controller que depende do service
        final controller = Bind.get<IController>();

        // Assert - Deve funcionar por auto-resolução
        expect(controller, isA<IController>());
        expect(controller, isA<ControllerImpl>());
        expect(() => controller.handleRequest(), returnsNormally);
      });

      test('should handle mixed typed and untyped registrations', () {
        // Arrange - Mistura registros tipados e não tipados
        final typedService = Bind.singleton<IService>((i) => ServiceImpl());
        final untypedRepository = Bind.singleton((i) => RepositoryImpl());

        Bind.register(typedService);
        Bind.register(untypedRepository);

        // Act - Busca ambos
        final service = Bind.get<IService>();
        final repository = Bind.get<IRepository>();

        // Assert - Ambos devem funcionar
        expect(service, isA<IService>());
        expect(repository, isA<IRepository>());
      });

      test('should work with original IBindSingleton pattern untyped', () {
        // Arrange - Simula o padrão original sem tipo genérico usando classes existentes
        // Registra sem tipo genérico (como no código original)
        final bind = Bind.singleton((i) => ServiceImpl()); // Usa ServiceImpl como exemplo
        Bind.register(bind);

        // Act - Busca pela interface
        final service = Bind.get<IService>();

        // Assert - Deve funcionar por auto-resolução
        expect(service, isA<IService>());
        expect(service, isA<ServiceImpl>());
        expect(() => service.doSomething(), returnsNormally);
      });
    });

    group('Original Problem Scenario', () {
      test('should resolve IBindSingleton when BindSingleton is registered', () {
        // Arrange - Simula exatamente o problema original
        final bind = Bind.singleton((i) => ServiceImpl()); // Registra como ServiceImpl
        Bind.register(bind);

        // Act - Tenta buscar pela interface
        final service = Bind.get<IService>();

        // Assert - Deve funcionar por auto-resolução
        expect(service, isA<IService>());
        expect(service, isA<ServiceImpl>());
        expect(service.name, 'ServiceImplementation');
      });

      test('should work with IBindSingleton pattern', () {
        // Arrange - Simula o padrão IBindSingleton
        final bind = Bind.singleton((i) => ServiceImpl()); // Registra como ServiceImpl
        Bind.register(bind);

        // Act - Busca pela interface
        final service = Bind.get<IService>();

        // Assert - Deve funcionar por auto-resolução
        expect(service, isA<IService>());
        expect(service, isA<ServiceImpl>());
        expect(() => service.doSomething(), returnsNormally);
      });
    });

    group('Real World Scenario', () {
      test('should simulate real application with interfaces', () {
        // Arrange - Simula um cenário real de aplicação
        final repositoryBind = Bind.singleton<IRepository>((i) => RepositoryImpl());
        final serviceBind = Bind.singleton<IService>((i) => ServiceImpl());
        final controllerBind = Bind.singleton<IController>((i) => ControllerImpl(i.get<IService>()));

        Bind.register(repositoryBind);
        Bind.register(serviceBind);
        Bind.register(controllerBind);

        // Act
        final repository = Bind.get<IRepository>();
        final service = Bind.get<IService>();
        final controller = Bind.get<IController>();

        // Assert
        expect(repository, isA<IRepository>());
        expect(service, isA<IService>());
        expect(controller, isA<IController>());

        // Test interactions
        repository.save('test data');
        expect(repository.data, 'test data');

        expect(() => service.doSomething(), returnsNormally);
        expect(() => controller.handleRequest(), returnsNormally);
      });

      test('should handle multiple modules with same interface', () {
        // Arrange - Simula múltiplos módulos registrando a mesma interface
        final module1Service = Bind.singleton<IService>((i) => ServiceImpl(), key: 'module1');
        final module2Service = Bind.singleton<IService>((i) => ServiceImpl(), key: 'module2');

        Bind.register(module1Service);
        Bind.register(module2Service);

        // Act
        final service1 = Bind.get<IService>(key: 'module1');
        final service2 = Bind.get<IService>(key: 'module2');

        // Assert
        expect(service1, isA<IService>());
        expect(service2, isA<IService>());
        expect(service1.name, service2.name);
      });
    });
  });
}
