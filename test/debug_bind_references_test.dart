import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

void main() {
  group('Debug Bind References - Testes', () {
    setUp(() {
      Bind.clearAll();
    });

    test('debug bind references issue', () {
      // Arrange - Simular o problema
      print('🔍 Simulando problema de _bindReferences...');

      // Registrar binds
      Bind.register(Bind.singleton<DioFake>((i) => DioFake(baseUrl: 'http://localhost:8080'), key: 'dio_local'));
      Bind.register(Bind.singleton<DioFake>((i) => DioFake(baseUrl: 'https://api.github.com'), key: 'dio_remote'));

      final injector = Injector();

      // Usar os binds
      final dioLocal = injector.get<DioFake>(key: 'dio_local');
      final dioRemote = injector.get<DioFake>(key: 'dio_remote');

      print('Dio Local: $dioLocal');
      print('Dio Remote: $dioRemote');

      expect(dioLocal, isA<DioFake>());
      expect(dioRemote, isA<DioFake>());

      // Simular o que acontece quando o módulo é disposed
      print('🗑️ Simulando dispose...');

      // Act - Fazer dispose diretamente
      print('🗑️ Fazendo dispose do DioFake...');
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
