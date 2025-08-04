import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

void main() {
  group('Debug Mixed Binds - Testes', () {
    setUp(() {
      Bind.clearAll();
    });

    test('debug binds mistos', () {
      // Arrange
      Bind.register(Bind.singleton<DatabaseService>((i) => PostgreSQLService(), key: 'postgres_db'));
      Bind.register(Bind.singleton<DatabaseService>((i) => MySQLService(), key: 'mysql_db'));
      Bind.register(Bind.singleton<DatabaseService>((i) => SQLiteService())); // Sem key
      
      final injector = Injector();
      
      // Verificar que os binds foram registrados
      print('🔍 Testando binds com keys:');
      print('PostgreSQL: ${injector.get<DatabaseService>(key: 'postgres_db')}');
      print('MySQL: ${injector.get<DatabaseService>(key: 'mysql_db')}');
      
      print('🔍 Testando bind sem key:');
      print('Sem key: ${injector.get<DatabaseService>()}');
      
      // Act
      print('🗑️ Fazendo dispose...');
      Bind.disposeByType(DatabaseService);
      
      // Assert
      print('🔍 Após o dispose:');
      try {
        final postgres = injector.get<DatabaseService>(key: 'postgres_db');
        print('❌ PostgreSQL ainda existe: $postgres');
      } catch (e) {
        print('✅ PostgreSQL removido: $e');
      }
      
      try {
        final mysql = injector.get<DatabaseService>(key: 'mysql_db');
        print('❌ MySQL ainda existe: $mysql');
      } catch (e) {
        print('✅ MySQL removido: $e');
      }
      
      try {
        final sqlite = injector.get<DatabaseService>();
        print('❌ SQLite ainda existe: $sqlite');
      } catch (e) {
        print('✅ SQLite removido: $e');
      }
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

class SQLiteService extends DatabaseService {
  @override
  String get name => 'SQLiteService';
} 