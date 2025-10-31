import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

/// Teste que simula o caso REAL do usuário:
/// - AppModule com binds ASSÍNCRONOS (await SharedPreferences, etc)
/// - Imports que precisam acessar esses binds do AppModule
/// 
/// Este teste valida que:
/// 1. ✅ Aguardamos binds assíncronos antes de commitar
/// 2. ✅ Imports podem acessar binds registrados no AppModule assíncrono
/// 3. ✅ Não há "Injector committed!" error
void main() {
  group('Async Binds Test - Caso Real do Usuário', () {
    setUp(() {
      InjectionManager.instance.clearAllForTesting();
    });

    tearDown(() {
      InjectionManager.instance.clearAllForTesting();
    });

    test(
      '✅ AppModule com binds ASSÍNCRONOS deve funcionar corretamente',
      () async {
        print('\n🧪 SIMULANDO O CASO REAL DO USUÁRIO');
        print('════════════════════════════════════════════════════════════════');
        print('AppModule:');
        print('  1. Inicializa SharedPreferences (assíncrono)');
        print('  2. Cria CacheService');
        print('  3. Registra IClient, IAuthApi, etc');
        print('  4. Import AuthModule tenta usar IClient');
        print('════════════════════════════════════════════════════════════════\n');

        // Arrange: Criar AppModule que simula o caso real
        final appModule = RealWorldAppModule();

        // Act: Registrar AppModule (com binds assíncronos)
        print('📦 Registrando AppModule com binds assíncronos...');
        await InjectionManager.instance.registerAppModule(appModule);
        print('✅ AppModule registrado\n');

        // Assert 1: Verificar que os binds assíncronos foram registrados
        print('🔍 Verificando se binds assíncronos foram registrados...');
        final sharedPrefs = Modular.get<ISharedPreferences>();
        expect(sharedPrefs, isNotNull);
        expect(sharedPrefs, isA<FakeSharedPreferences>());
        print('✅ SharedPreferences disponível: ${sharedPrefs.runtimeType}\n');

        final cache = Modular.get<ICacheService>();
        expect(cache, isNotNull);
        expect(cache, isA<CacheService>());
        print('✅ CacheService disponível: ${cache.runtimeType}\n');

        final client = Modular.get<IClient>();
        expect(client, isNotNull);
        expect(client, isA<HttpClient>());
        print('✅ IClient disponível: ${client.runtimeType}\n');

        // Assert 2: Verificar que o import conseguiu usar IClient do AppModule
        print('🔍 Verificando se AuthModule conseguiu usar IClient...');
        final authApi = Modular.get<IAuthApi>();
        expect(authApi, isNotNull);
        expect(authApi, isA<AuthApi>());
        expect(authApi.client, isNotNull, 
          reason: 'AuthApi deve ter recebido IClient do AppModule');
        expect(authApi.client, same(client), 
          reason: 'Deve ser a MESMA instância do IClient do AppModule');
        print('✅ AuthApi disponível com IClient injetado: ${authApi.runtimeType}');
        print('✅ AuthApi.client = ${authApi.client.runtimeType} (mesmo do AppModule)\n');

        print('════════════════════════════════════════════════════════════════');
        print('✅ TESTE PASSOU! Binds assíncronos funcionam perfeitamente!');
        print('════════════════════════════════════════════════════════════════\n');
      },
    );

    test(
      '✅ Múltiplos módulos com binds assíncronos devem funcionar',
      () async {
        final appModule = RealWorldAppModuleMultiAsync();
        
        await InjectionManager.instance.registerAppModule(appModule);

        // Verificar que TODOS os binds assíncronos foram aguardados
        final config = Modular.get<IConfig>();
        expect(config, isNotNull);
        expect(config.apiUrl, equals('https://api.production.com'));

        final storage = Modular.get<IStorage>();
        expect(storage, isNotNull);

        final service = Modular.get<ComplexService>();
        expect(service, isNotNull);
        expect(service.config, same(config));
        expect(service.storage, same(storage));
      },
    );

    test(
      '📝 DOCUMENTAÇÃO: Problema que estava acontecendo antes do fix',
      () async {
        // Este teste documenta qual seria o comportamento SEM o fix
        
        print('\n📝 DOCUMENTAÇÃO: Comportamento SEM o fix');
        print('════════════════════════════════════════════════════════════════');
        print('PROBLEMA (que agora está RESOLVIDO):');
        print('');
        print('1. AppModule.binds() é chamado (retorna Future<void>)');
        print('2. ❌ SEM AWAIT: commit() é chamado IMEDIATAMENTE');
        print('3. ❌ binds() ainda está executando em background');
        print('4. ❌ Quando i.addSingleton() executa → ERRO: "Injector committed!"');
        print('');
        print('SOLUÇÃO (implementada):');
        print('');
        print('1. AppModule.binds() é chamado (retorna Future<void>)');
        print('2. ✅ COM AWAIT: aguarda bindsResult completar');
        print('3. ✅ Só então commit() é chamado');
        print('4. ✅ Todos os binds foram registrados com sucesso');
        print('════════════════════════════════════════════════════════════════\n');
        
        expect(true, isTrue, reason: 'Este teste é apenas documentação');
      },
    );
  });
}

// ============================================================================
// SIMULAÇÃO DO CASO REAL DO USUÁRIO
// ============================================================================

/// Simula o AppModule real com binds assíncronos
class RealWorldAppModule extends Module {
  @override
  List<Module> imports() => [RealWorldAuthModule()];

  @override
  Future<void> binds(Injector i) async {
    print('   🔧 AppModule.binds() INÍCIO (assíncrono)');
    
    // 1. Simula inicialização assíncrona (como SharedPreferences.getInstance())
    print('   ⏳ Aguardando SharedPreferences.getInstance()...');
    await Future.delayed(Duration(milliseconds: 10)); // Simula delay real
    final sharedPrefs = FakeSharedPreferences();
    print('   ✅ SharedPreferences inicializado');
    
    i.addSingleton<ISharedPreferences>(() => sharedPrefs);
    
    // 2. Cria cache (depende de SharedPreferences)
    print('   🔧 Criando CacheService...');
    final cache = CacheService(sharedPreferences: sharedPrefs);
    i.addSingleton<ICacheService>(() => cache);
    print('   ✅ CacheService criado');
    
    // 3. Registra IClient (usado por imports)
    print('   🔧 Registrando IClient...');
    i.addSingleton<IClient>(() => HttpClient(baseUrl: 'https://api.example.com'));
    print('   ✅ IClient registrado');
    
    // 4. Outro delay para simular múltiplas operações assíncronas
    await Future.delayed(Duration(milliseconds: 5));
    
    print('   🏁 AppModule.binds() CONCLUÍDO');
  }

  @override
  List<ModularRoute> get routes => [];
}

/// Módulo importado que PRECISA usar IClient do AppModule
class RealWorldAuthModule extends Module {
  @override
  Future<void> binds(Injector i) async {
    print('      🔧 AuthModule.binds() INÍCIO');
    print('      🔍 Tentando buscar IClient do AppModule...');
    
    // Este i.get() deve funcionar porque AppModule.binds() foi aguardado
    final client = i.get<IClient>();
    print('      ✅ IClient encontrado via fallback: ${client.runtimeType}');
    
    // Registrar AuthApi com o client
    i.addSingleton<IAuthApi>(() => AuthApi(client: client));
    print('      ✅ IAuthApi registrado com client injetado');
    print('      🏁 AuthModule.binds() CONCLUÍDO');
  }

  @override
  List<ModularRoute> get routes => [];
}

/// AppModule com MÚLTIPLAS operações assíncronas
class RealWorldAppModuleMultiAsync extends Module {
  @override
  List<Module> imports() => [RealWorldComplexModule()];

  @override
  Future<void> binds(Injector i) async {
    // Múltiplas operações assíncronas em sequência
    await Future.delayed(Duration(milliseconds: 5));
    i.addSingleton<IConfig>(() => Config(apiUrl: 'https://api.production.com'));
    
    await Future.delayed(Duration(milliseconds: 5));
    i.addSingleton<IStorage>(() => Storage());
    
    await Future.delayed(Duration(milliseconds: 5));
    i.addSingleton<ILogger>(() => Logger());
  }

  @override
  List<ModularRoute> get routes => [];
}

class RealWorldComplexModule extends Module {
  @override
  void binds(Injector i) {
    // Busca múltiplos binds do AppModule (que foram registrados assincronamente)
    final config = i.get<IConfig>();
    final storage = i.get<IStorage>();
    
    i.addSingleton<ComplexService>(
      () => ComplexService(config: config, storage: storage),
    );
  }

  @override
  List<ModularRoute> get routes => [];
}

// ============================================================================
// INTERFACES E IMPLEMENTAÇÕES DE TESTE
// ============================================================================

abstract class ISharedPreferences {
  String? getString(String key);
  Future<bool> setString(String key, String value);
}

class FakeSharedPreferences implements ISharedPreferences {
  final Map<String, String> _data = {};
  
  @override
  String? getString(String key) => _data[key];
  
  @override
  Future<bool> setString(String key, String value) async {
    _data[key] = value;
    return true;
  }
}

abstract class ICacheService {
  Future<void> save(String key, String value);
  String? get(String key);
}

class CacheService implements ICacheService {
  final ISharedPreferences sharedPreferences;
  
  CacheService({required this.sharedPreferences});
  
  @override
  Future<void> save(String key, String value) async {
    await sharedPreferences.setString(key, value);
  }
  
  @override
  String? get(String key) => sharedPreferences.getString(key);
}

abstract class IClient {
  String get baseUrl;
  Future<dynamic> get(String path);
}

class HttpClient implements IClient {
  @override
  final String baseUrl;
  
  HttpClient({required this.baseUrl});
  
  @override
  Future<dynamic> get(String path) async {
    return {'data': 'mock'};
  }
}

abstract class IAuthApi {
  IClient get client;
  Future<void> login(String username, String password);
}

class AuthApi implements IAuthApi {
  @override
  final IClient client;
  
  AuthApi({required this.client});
  
  @override
  Future<void> login(String username, String password) async {
    await client.get('/auth/login');
  }
}

abstract class IConfig {
  String get apiUrl;
}

class Config implements IConfig {
  @override
  final String apiUrl;
  
  Config({required this.apiUrl});
}

abstract class IStorage {
  Future<void> write(String key, String value);
}

class Storage implements IStorage {
  @override
  Future<void> write(String key, String value) async {}
}

abstract class ILogger {
  void log(String message);
}

class Logger implements ILogger {
  @override
  void log(String message) {}
}

class ComplexService {
  final IConfig config;
  final IStorage storage;
  
  ComplexService({required this.config, required this.storage});
}
