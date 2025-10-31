import 'package:go_router_modular/go_router_modular.dart';
import 'pages/imports_bug_page.dart';

/// Módulo de exemplo que reproduz o bug de imports no AppModule
///
/// Este módulo demonstra o problema onde:
/// 1. AppModule tem imports() que retorna AuthPhoneModule
/// 2. AppModule registra IClient e IAuthApi em binds()
/// 3. AuthPhoneModule (import) precisa de IClient durante seu binds()
/// 4. O problema: imports são processados ANTES de binds(), então IClient não existe ainda!
class ImportsBugModule extends Module {
  @override
  List<ModularRoute> get routes => [
        ChildRoute(
          '/',
          child: (context, state) => const ImportsBugPage(),
        ),
      ];
}

/// Simula o AuthPhoneModule que é importado pelo AppModule
/// Este módulo precisa de IClient do AppModule durante seu binds()
class AuthPhoneModuleSimulated extends Module {
  @override
  void binds(Injector i) {
    print('   ┌─ AuthPhoneModuleSimulated.binds() INICIADO');
    print('   │  Tentando buscar IClient do AppModule...');
    
    // ❌ PROBLEMA: Tenta usar IClient que ainda não foi registrado
    // porque AppModule.binds() ainda não foi executado
    // (imports são processados ANTES de binds)
    try {
      print('   │  Chamando i.get<IClient>()...');
      final client = i.get<IClient>();
      print('   │  ✅ IClient encontrado: ${client.runtimeType}');
      
      i.addSingleton<IAuthApi>(
        () => AuthApiSimulated(client: client),
      );
      print('   │  ✅ IAuthApi registrado');
      
      i.addSingleton<AuthPhoneService>(
        () => AuthPhoneService(api: i.get<IAuthApi>()),
      );
      print('   │  ✅ AuthPhoneService registrado COM api');
    } catch (e) {
      // Se falhar, registra sem dependência (para não quebrar o exemplo)
      print('   │  ❌ ERRO ao buscar IClient: $e');
      print('   │  ⚠️  Registrando AuthPhoneService SEM api (api=null)');
      i.addSingleton<AuthPhoneService>(
        () => AuthPhoneService(api: null),
      );
      print('   │  ✅ AuthPhoneService registrado SEM api');
    }
    
    print('   └─ AuthPhoneModuleSimulated.binds() CONCLUÍDO');
  }

  @override
  List<ModularRoute> get routes => [];
}

/// Interface para cliente HTTP (simula IClient)
abstract class IClient {
  String get baseUrl;
  Future<String> get(String path);
}

/// Implementação fake do cliente
class ClientDioSimulated implements IClient {
  final String _baseUrl;

  ClientDioSimulated({required String baseUrl}) : _baseUrl = baseUrl;

  @override
  String get baseUrl => _baseUrl;

  @override
  Future<String> get(String path) async {
    return 'GET $_baseUrl$path';
  }
}

/// Interface para API de autenticação (simula IAuthApi)
abstract class IAuthApi {
  Future<bool> authenticate(String phone);
}

/// Implementação da API de autenticação
class AuthApiSimulated implements IAuthApi {
  final IClient client;

  AuthApiSimulated({required this.client});

  @override
  Future<bool> authenticate(String phone) async {
    final response = await client.get('/auth/$phone');
    return response.contains('success');
  }
}

/// Serviço de autenticação por telefone
class AuthPhoneService {
  final IAuthApi? api;

  AuthPhoneService({this.api});

  Future<bool> login(String phone) async {
    if (api == null) {
      throw Exception('IAuthApi não foi injetado corretamente!');
    }
    return api!.authenticate(phone);
  }
}

