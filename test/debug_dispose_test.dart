import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

void main() {
  group('Debug Dispose - Testes', () {
    setUp(() {
      Bind.clearAll();
    });

    test('debug dispose com keys', () {
      // Arrange
      Bind.register(Bind.singleton<DatabaseService>((i) => PostgreSQLService(), key: 'postgres_db'));
      Bind.register(Bind.singleton<DatabaseService>((i) => MySQLService(), key: 'mysql_db'));
      
      final injector = Injector();
      
      // Verificar que os binds foram registrados
      print('🔍 Antes do dispose:');
      print('PostgreSQL: ${injector.get<DatabaseService>(key: 'postgres_db')}');
      print('MySQL: ${injector.get<DatabaseService>(key: 'mysql_db')}');

      // Act
      print('🗑️ Fazendo dispose...');
      print('Tipo a ser removido: ${DatabaseService}');
      Bind.disposeByType(DatabaseService);
      print('Dispose concluído');

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