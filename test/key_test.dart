import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

void main() {
  group('Sistema de Keys - Testes', () {
    late Injector injector;

    setUp(() {
      // Limpa todos os binds antes de cada teste
      Bind.clearAll();
      injector = Injector();
    });

    group('Registro de Binds com Keys', () {
      test('deve registrar binds com keys diferentes', () {
        // Arrange
        final bind1 = Bind.singleton<UserService>((i) => UserService(), key: 'user_service');
        final bind2 = Bind.singleton<UserService>((i) => AdminUserService(), key: 'admin_user_service');

        // Act
        Bind.register(bind1);
        Bind.register(bind2);

        // Assert
        expect(Bind.getAllKeys(), contains('user_service'));
        expect(Bind.getAllKeys(), contains('admin_user_service'));
      });

      test('deve registrar binds sem keys', () {
        // Arrange
        final bind = Bind.singleton<LoggerService>((i) => LoggerService());

        // Act
        Bind.register(bind);

        // Assert
        expect(Bind.getAllKeys(), isEmpty);
      });
    });

    group('Busca por Key Específica', () {
      test('deve encontrar bind por key específica', () {
        // Arrange
        final bind = Bind.singleton<UserService>((i) => UserService(), key: 'user_service');
        Bind.register(bind);

        // Act
        final result = injector.get<UserService>(key: 'user_service');

        // Assert
        expect(result, isA<UserService>());
      });

      test('deve lançar exceção quando key não existe', () {
        // Arrange
        final bind = Bind.singleton<ApiService>((i) => ApiService(), key: 'api_service');
        Bind.register(bind);

        // Act & Assert
        expect(
          () => injector.get<UserService>(key: 'non_existent_key'),
          throwsA(anything),
        );
      });

      test('deve buscar por tipo quando key não é fornecida', () {
        // Arrange
        final bind = Bind.singleton<UserService>((i) => UserService());
        Bind.register(bind);

        // Act
        final result = injector.get<UserService>();

        // Assert
        expect(result, isA<UserService>());
      });
    });

    group('Casos de Uso Reais', () {
      test('deve suportar múltiplas implementações do mesmo tipo', () {
        // Arrange
        Bind.register(Bind.singleton<DatabaseService>((i) => PostgreSQLService(), key: 'postgres_db'));
        Bind.register(Bind.singleton<DatabaseService>((i) => MySQLService(), key: 'mysql_db'));
        Bind.register(Bind.singleton<DatabaseService>((i) => SQLiteService(), key: 'sqlite_db'));

        // Act
        final postgresDb = injector.get<DatabaseService>(key: 'postgres_db');
        final mysqlDb = injector.get<DatabaseService>(key: 'mysql_db');
        final sqliteDb = injector.get<DatabaseService>(key: 'sqlite_db');

        // Assert
        expect(postgresDb, isA<PostgreSQLService>());
        expect(mysqlDb, isA<MySQLService>());
        expect(sqliteDb, isA<SQLiteService>());
      });

      test('deve suportar serviços por ambiente', () {
        // Arrange
        Bind.register(Bind.singleton<ApiService>((i) => ProductionApiService(), key: 'prod_api'));
        Bind.register(Bind.singleton<ApiService>((i) => DevelopmentApiService(), key: 'dev_api'));
        Bind.register(Bind.singleton<ApiService>((i) => MockApiService(), key: 'test_api'));

        // Act
        final prodApi = injector.get<ApiService>(key: 'prod_api');
        final devApi = injector.get<ApiService>(key: 'dev_api');
        final testApi = injector.get<ApiService>(key: 'test_api');

        // Assert
        expect(prodApi, isA<ProductionApiService>());
        expect(devApi, isA<DevelopmentApiService>());
        expect(testApi, isA<MockApiService>());
      });

      test('deve manter compatibilidade com binds sem keys', () {
        // Arrange
        Bind.register(Bind.singleton<LoggerService>((i) => LoggerService()));
        Bind.register(Bind.singleton<LoggerService>((i) => FileLoggerService(), key: 'file_logger'));

        // Act
        final defaultLogger = injector.get<LoggerService>();
        final fileLogger = injector.get<LoggerService>(key: 'file_logger');

        // Assert
        expect(defaultLogger, isA<LoggerService>());
        expect(fileLogger, isA<FileLoggerService>());
      });
    });

    group('Dispose de Binds', () {
      test('deve remover bind por tipo', () {
        // Arrange
        final bind = Bind.singleton<UserService>((i) => UserService(), key: 'user_service');
        Bind.register(bind);

        // Act
        Bind.dispose(bind);

        // Assert
        expect(Bind.getAllKeys(), isEmpty);
      });

      test('deve remover bind por key', () {
        // Arrange
        final bind = Bind.singleton<UserService>((i) => UserService(), key: 'user_service');
        Bind.register(bind);

        // Act
        Bind.dispose(bind);

        // Assert
        expect(Bind.getAllKeys(), isEmpty);
      });
    });

    group('Integração com HomePage', () {
      test('deve funcionar com o padrão usado na HomePage', () {
        // Arrange - Simulando o padrão usado na HomePage
        Bind.register(Bind.singleton<SharedService>((i) => SharedService()));
        Bind.register(Bind.singleton<TestController>((i) => TestController.instance));

        // Act
        final sharedService = injector.get<SharedService>();
        final testController = injector.get<TestController>();

        // Assert
        expect(sharedService, isA<SharedService>());
        expect(testController, isA<TestController>());
      });
    });
  });
}

// Classes de teste para o sistema de keys
class UserService {
  String get name => 'UserService';
}

class AdminUserService extends UserService {
  @override
  String get name => 'AdminUserService';
}

class ApiService {
  String get name => 'ApiService';
}

class ProductionApiService extends ApiService {
  @override
  String get name => 'ProductionApiService';
}

class DevelopmentApiService extends ApiService {
  @override
  String get name => 'DevelopmentApiService';
}

class MockApiService extends ApiService {
  @override
  String get name => 'MockApiService';
}

class DatabaseService {
  String get name => 'DatabaseService';
}

class PostgreSQLService extends DatabaseService {
  @override
  String get name => 'PostgreSQLService';
}

class MySQLService extends DatabaseService {
  @override
  String get name => 'MySQLService';
}

class SQLiteService extends DatabaseService {
  @override
  String get name => 'SQLiteService';
}

class LoggerService {
  String get name => 'LoggerService';
}

class FileLoggerService extends LoggerService {
  @override
  String get name => 'FileLoggerService';
}

// Classes necessárias para integração com HomePage
class SharedService {
  String name = 'SharedService';
  void setName(String newName) => name = newName;
}

class TestController {
  static final TestController instance = TestController._();
  TestController._();

  String? currentModule;
  int testCount = 0;
  List<TestResult> testResults = [];
  List<String> navigationHistory = [];
  List<String> bindHistory = [];

  void clearAll() {
    testResults.clear();
    navigationHistory.clear();
    bindHistory.clear();
    testCount = 0;
  }

  void clearTestResults() {
    testResults.clear();
  }

  TestResult testShellNavigation(String route, List<String> subRoutes) {
    testCount++;
    return TestResult(
      id: testCount,
      message: 'Shell Navigation Test',
      success: true,
      moduleName: 'TestModule',
      timestamp: DateTime.now().toString(),
      details: {
        'route': route,
        'subRoutes': subRoutes.join(', '),
      },
    );
  }

  TestResult testBindDisposal(String moduleName, Map<String, Function> dependencies) {
    testCount++;
    return TestResult(
      id: testCount,
      message: 'Bind Disposal Test',
      success: true,
      moduleName: moduleName,
      timestamp: DateTime.now().toString(),
      details: {
        'dependencies': dependencies.keys.join(', '),
      },
    );
  }
}

class TestResult {
  final int id;
  final String message;
  final bool success;
  final String moduleName;
  final String timestamp;
  final Map<String, String> details;

  TestResult({
    required this.id,
    required this.message,
    required this.success,
    required this.moduleName,
    required this.timestamp,
    required this.details,
  });
}
