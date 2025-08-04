import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

void main() {
  group('Auto Key - Testes', () {
    setUp(() {
      Bind.clearAll();
    });

    test('deve usar nome da classe como key automaticamente', () {
      // Arrange
      Bind.register(Bind.singleton<DatabaseService>((i) => PostgreSQLService()));
      Bind.register(Bind.singleton<LoggerService>((i) => LoggerService()));
      
      final injector = Injector();
      
      // Act & Assert
      print('🔍 Testando busca sem key:');
      final db = injector.get<DatabaseService>();
      final logger = injector.get<LoggerService>();
      
      print('DatabaseService: $db');
      print('LoggerService: $logger');
      
      expect(db, isA<PostgreSQLService>());
      expect(logger, isA<LoggerService>());
    });

    test('deve funcionar com keys explícitas', () {
      // Arrange
      Bind.register(Bind.singleton<DatabaseService>((i) => PostgreSQLService(), key: 'postgres_db'));
      Bind.register(Bind.singleton<DatabaseService>((i) => MySQLService(), key: 'mysql_db'));
      
      final injector = Injector();
      
      // Act & Assert
      print('🔍 Testando busca com keys explícitas:');
      final postgres = injector.get<DatabaseService>(key: 'postgres_db');
      final mysql = injector.get<DatabaseService>(key: 'mysql_db');
      
      print('PostgreSQL: $postgres');
      print('MySQL: $mysql');
      
      expect(postgres, isA<PostgreSQLService>());
      expect(mysql, isA<MySQLService>());
    });

    test('deve funcionar com misto de keys explícitas e automáticas', () {
      // Arrange
      Bind.register(Bind.singleton<DatabaseService>((i) => PostgreSQLService(), key: 'postgres_db'));
      Bind.register(Bind.singleton<DatabaseService>((i) => MySQLService())); // Key automática
      
      final injector = Injector();
      
      // Act & Assert
      print('🔍 Testando busca mista:');
      final postgres = injector.get<DatabaseService>(key: 'postgres_db');
      final mysql = injector.get<DatabaseService>(); // Usa key automática
      
      print('PostgreSQL: $postgres');
      print('MySQL: $mysql');
      
      expect(postgres, isA<PostgreSQLService>());
      expect(mysql, isA<MySQLService>());
    });
  });
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

class LoggerService {
  String get name => 'LoggerService';
} 