import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

void main() {
  group('Debug Key Registration - Testes', () {
    setUp(() {
      Bind.clearAll();
    });

    test('debug key registration', () {
      // Arrange
      print('🔍 Registrando binds...');
      
      // Bind com key explícita
      Bind.register(Bind.singleton<DatabaseService>((i) => PostgreSQLService(), key: 'postgres_db'));
      
      // Bind sem key explícita
      Bind.register(Bind.singleton<DatabaseService>((i) => MySQLService()));
      
      final injector = Injector();
      
      // Act & Assert
      print('🔍 Testando busca com key explícita:');
      final postgres = injector.get<DatabaseService>(key: 'postgres_db');
      print('PostgreSQL: $postgres');
      
      print('🔍 Testando busca sem key:');
      final mysql = injector.get<DatabaseService>();
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