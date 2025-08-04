import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

void main() {
  group('Debug Module Structure - Testes', () {
    setUp(() {
      Bind.clearAll();
    });

    test('debug module structure', () {
      // Arrange - Simular a estrutura de módulos do app
      print('🔍 Simulando estrutura de módulos do app...');

      // Simular AppModule
      print('📦 Registrando AppModule...');
      Bind.register(Bind.singleton<HomeService>((i) => HomeService()));
      Bind.register(Bind.singleton<SharedService>((i) => SharedService()));

      // Simular BindsByKeyModule
      print('📦 Registrando BindsByKeyModule...');
      Bind.register(Bind.singleton<DioFake>((i) => DioFake(baseUrl: 'http://localhost:8080'), key: 'dio_local'));
      Bind.register(Bind.singleton<DioFake>((i) => DioFake(baseUrl: 'https://api.github.com'), key: 'dio_remote'));

      final injector = Injector();

      // Verificar que os binds foram registrados
      print('🔍 Testando busca:');
      final homeService = injector.get<HomeService>();
      final sharedService = injector.get<SharedService>();
      final dioLocal = injector.get<DioFake>(key: 'dio_local');
      final dioRemote = injector.get<DioFake>(key: 'dio_remote');

      print('HomeService: $homeService');
      print('SharedService: $sharedService');
      print('Dio Local: $dioLocal');
      print('Dio Remote: $dioRemote');

      expect(homeService, isA<HomeService>());
      expect(sharedService, isA<SharedService>());
      expect(dioLocal, isA<DioFake>());
      expect(dioRemote, isA<DioFake>());

      // Simular o que acontece quando o módulo é disposed
      print('🗑️ Simulando dispose do BindsByKeyModule...');

      // Verificar se o problema está na lógica de _isBindForAppModule
      // Vou simular a lógica manualmente
      print('🔍 Verificando se DioFake seria considerado do AppModule...');

      // Act - Simular dispose do DioFake
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

      // Verificar se os binds do AppModule ainda existem
      try {
        final home = injector.get<HomeService>();
        print('✅ HomeService ainda existe: $home');
      } catch (e) {
        print('❌ HomeService removido: $e');
      }

      try {
        final shared = injector.get<SharedService>();
        print('✅ SharedService ainda existe: $shared');
      } catch (e) {
        print('❌ SharedService removido: $e');
      }
    });
  });
}

class HomeService {
  String get name => 'HomeService';
}

class SharedService {
  String get name => 'SharedService';
}

class DioFake {
  final String baseUrl;
  DioFake({required this.baseUrl});
}
