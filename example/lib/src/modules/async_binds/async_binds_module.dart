import 'package:go_router_modular/go_router_modular.dart';
import 'pages/async_binds_page.dart';

/// Módulo que demonstra o uso de binds ASSÍNCRONOS
///
/// Caso de uso real: inicializar SharedPreferences, carregar configs, etc.
class AsyncBindsModule extends Module {
  @override
  List<Module> imports() => []; // SEM imports!

  @override
  Future<void> binds(Injector i) async {
    print('   🔧 AsyncBindsModule.binds() INÍCIO (assíncrono)');

    // 1. Simula inicialização assíncrona (como SharedPreferences.getInstance())

    // 2. Simula carregamento de config remoto
    print('   ⏳ Simulando carregamento de config remoto...');
    await Future.delayed(Duration(milliseconds: 30));
    final config = AppConfig(apiUrl: 'https://api.example.com', timeout: 30);
    print('   ✅ Config carregado: ${config.apiUrl}');

    i.addSingleton<IAppConfig>(() => config);

    // 3. Cria cache (depende de SharedPreferences)
    print('   🔧 Criando CacheService...');
    final cache = CacheService(sharedPreferences: i.get<ISharedPreferences>());
    i.addSingleton<ICacheService>(() => cache);
    print('   ✅ CacheService criado');

    // 4. Registra HttpClient (usado internamente)
    print('   🔧 Registrando HttpClient...');
    i.addSingleton<IHttpClient>(
      () => HttpClient(baseUrl: config.apiUrl, timeout: config.timeout),
    );
    print('   ✅ HttpClient registrado');

    // 5. Registra AuthService diretamente aqui (não em um import)
    print('   🔧 Registrando AuthService...');
    i.addSingleton<IAuthService>(() {
      print('         🔍 Criando AuthService...');
      final client = i.get<IHttpClient>();
      final cacheService = i.get<ICacheService>();
      print('         ✅ Dependências resolvidas');
      return AuthService(client: client, cache: cacheService);
    });
    print('   ✅ AuthService registrado');

    print('   🏁 AsyncBindsModule.binds() CONCLUÍDO');
  }

  @override
  List<ModularRoute> get routes => [
        ChildRoute(
          '/',
          child: (context, state) => const AsyncBindsPage(),
        ),
      ];
}

/// Módulo importado que usa INJEÇÃO POR CONSTRUTOR
///
/// ✅ SOLUÇÃO CORRETA: Use .new em vez de i.get() durante binds()
/// O auto_injector resolve as dependências automaticamente após commit
class AsyncAuthModule extends Module {
  @override
  void binds(Injector i) {
    print('      🔧 AsyncAuthModule.binds() INÍCIO');
    print('      ✅ Usando factory com i.get() para buscar dependências do pai');

    // ✅ SOLUÇÃO: Usar factory function em vez de constructor injection
    // Isso permite buscar dependências do módulo pai em runtime, não durante commit
    i.addSingleton<IAuthService>(() {
      print('         🔍 Buscando IHttpClient do módulo pai...');
      final client = i.get<IHttpClient>();
      print('         ✅ IHttpClient encontrado');

      print('         🔍 Buscando ICacheService do módulo pai...');
      final cache = i.get<ICacheService>();
      print('         ✅ ICacheService encontrado');

      return AuthService(client: client, cache: cache);
    });

    print('      ✅ IAuthService registrado com factory function');
    print('      🏁 AsyncAuthModule.binds() CONCLUÍDO');
  }

  @override
  List<ModularRoute> get routes => [];
}

// ============================================================================
// INTERFACES E IMPLEMENTAÇÕES
// ============================================================================

abstract class ISharedPreferences {
  String? getString(String key);
  Future<bool> setString(String key, String value);
  Map<String, String> getAll();
}

class FakeSharedPreferences implements ISharedPreferences {
  final Map<String, String> _data = {
    'user_token': 'fake_token_123',
    'user_email': 'user@example.com',
  };

  @override
  String? getString(String key) => _data[key];

  @override
  Future<bool> setString(String key, String value) async {
    await Future.delayed(Duration(milliseconds: 10));
    _data[key] = value;
    return true;
  }

  @override
  Map<String, String> getAll() => Map.from(_data);
}

abstract class IAppConfig {
  String get apiUrl;
  int get timeout;
}

class AppConfig implements IAppConfig {
  @override
  final String apiUrl;
  @override
  final int timeout;

  AppConfig({required this.apiUrl, required this.timeout});
}

abstract class ICacheService {
  Future<void> save(String key, String value);
  String? get(String key);
  Map<String, String> getAll();
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

  @override
  Map<String, String> getAll() => sharedPreferences.getAll();
}

abstract class IHttpClient {
  String get baseUrl;
  int get timeout;
  Future<Map<String, dynamic>> get(String path);
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> data);
}

class HttpClient implements IHttpClient {
  @override
  final String baseUrl;
  @override
  final int timeout;

  HttpClient({required this.baseUrl, required this.timeout});

  @override
  Future<Map<String, dynamic>> get(String path) async {
    await Future.delayed(Duration(milliseconds: 100));
    return {'status': 200, 'data': 'GET $baseUrl$path'};
  }

  @override
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> data) async {
    await Future.delayed(Duration(milliseconds: 150));
    return {'status': 200, 'data': 'POST $baseUrl$path', 'received': data};
  }
}

abstract class IAuthService {
  IHttpClient get client;
  Future<bool> login(String username, String password);
  Future<void> logout();
  String? get cachedToken;
}

class AuthService implements IAuthService {
  @override
  final IHttpClient client;
  final ICacheService cache;

  AuthService({required this.client, required this.cache});

  @override
  Future<bool> login(String username, String password) async {
    final response = await client.post('/auth/login', {
      'username': username,
      'password': password,
    });

    if (response['status'] == 200) {
      await cache.save('auth_token', 'token_${DateTime.now().millisecondsSinceEpoch}');
      return true;
    }
    return false;
  }

  @override
  Future<void> logout() async {
    await cache.save('auth_token', '');
  }

  @override
  String? get cachedToken => cache.get('auth_token');
}
