import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

void main() {
  group('Debug Dispose DioFake - Testes', () {
    setUp(() {
      Bind.clearAll();
    });

    test('debug dispose DioFake', () {
      // Arrange
      print('🔍 Registrando DioFake binds...');
      
      Bind.register(Bind.singleton<DioFake>((i) => DioFake(baseUrl: 'http://localhost:8080'), key: 'dio_local'));
      Bind.register(Bind.singleton<DioFake>((i) => DioFake(baseUrl: 'https://api.github.com'), key: 'dio_remote'));
      
      final injector = Injector();
      
      // Verificar que os binds foram registrados
      print('🔍 Testando busca com keys:');
      final dioLocal = injector.get<DioFake>(key: 'dio_local');
      final dioRemote = injector.get<DioFake>(key: 'dio_remote');
      
      print('Dio Local: $dioLocal');
      print('Dio Remote: $dioRemote');
      
      expect(dioLocal, isA<DioFake>());
      expect(dioRemote, isA<DioFake>());
      
      // Act
      print('🗑️ Fazendo dispose...');
      Bind.disposeByType(DioFake);
      
      // Assert
      print('🔍 Após o dispose:');
      try {
        final local = injector.get<DioFake>(key: 'dio_local');
        print('❌ Dio Local ainda existe: $local');
      } catch (e) {
        print('✅ Dio Local removido: $e');
      }
      
      try {
        final remote = injector.get<DioFake>(key: 'dio_remote');
        print('❌ Dio Remote ainda existe: $remote');
      } catch (e) {
        print('✅ Dio Remote removido: $e');
      }
    });
  });
}

class DioFake {
  final String baseUrl;
  DioFake({required this.baseUrl});
} 