import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

/// Teste que demonstra o problema de imports tentando usar binds do AppModule durante binds()
///
/// PROBLEMA REAL DO FLUTTER_MODULAR:
/// ==================================
/// No flutter_modular, quando um módulo é importado pelo AppModule, o fluxo é:
///
/// 1. AppModule.imports() é processado PRIMEIRO
///    - Cria injector para cada import
///    - Chama binds() de cada import
///    - Neste momento, AppModule.binds() AINDA NÃO FOI EXECUTADO
///
/// 2. AppModule.binds() é executado DEPOIS
///    - Registra os binds do AppModule
///
/// RESULTADO:
/// Se um import tentar usar i.get<T>() durante seu binds() para buscar
/// algo do AppModule, ele não encontrará porque o AppModule ainda não registrou!
///
/// SOLUÇÃO NO FLUTTER_MODULAR:
/// O flutter_modular resolve isso de duas formas:
/// 1. Os imports não devem depender de binds do módulo pai durante binds()
/// 2. Se precisarem, devem receber via construtor ou usar lazy initialization
///
/// Este teste DEVE FALHAR para demonstrar o problema.
void main() {
  group('AppModule com imports - Problema de ordem de processamento', () {
    setUp(() {
      InjectionManager.instance.clearAllForTesting();
    });

    tearDown(() {
      InjectionManager.instance.clearAllForTesting();
    });

    test(
      '❌ DEMONSTRA O PROBLEMA: Import não consegue usar i.get() durante binds() para buscar bind do AppModule',
      () async {
        // Criar AppModule que tem imports E registra IClient
        final appModule = AppModuleWithClientBind();

        // Registrar AppModule (que vai processar imports primeiro, depois binds)
        await InjectionManager.instance.registerAppModule(appModule);

        // Buscar AuthService do módulo importado
        // Este módulo tentou fazer i.get<IClient>() durante seu binds()
        final authService = Modular.get<AuthService>();

        // ❌ PROBLEMA DEMONSTRADO: AuthService foi criado, mas client é NULL
        // porque IClient não estava disponível durante binds() do AuthModule
        expect(authService, isNotNull);
        expect(
          authService.client,
          isNull,
          reason: 'AuthModule tentou fazer i.get<IClient>() durante binds(), '
              'mas IClient ainda não existia porque AppModule.binds() não foi executado ainda. '
              'Por isso, AuthService foi criado com client=null',
        );

        // Agora IClient está disponível (porque AppModule.binds() já executou)
        final client = Modular.get<IClient>();
        expect(client, isNotNull);
        expect(client.baseUrl, equals('https://api.example.com'));
      },
    );

    test(
      '✅ DEVE PASSAR: Import pode usar Modular.get() FORA de binds() (depois que tudo foi registrado)',
      () async {
        // Criar AppModule que registra IClient ANTES de processar imports
        final appModule = AppModuleWithClientBindFixed();

        // Registrar AppModule
        await InjectionManager.instance.registerAppModule(appModule);

        // Buscar AuthService (que foi registrado sem tentar usar i.get durante binds)
        final authService = Modular.get<AuthServiceLazy>();
        expect(authService, isNotNull);

        // Agora AuthService pode buscar IClient via Modular.get() em seus métodos
        final client = authService.getClient();
        expect(client, isNotNull);
        expect(client, isA<IClient>());
      },
    );

    test(
      '✅ DEVE PASSAR: Import recebe dependências via construtor',
      () async {
        // Criar AppModule que passa IClient via construtor para o import
        final appModule = AppModuleWithClientPassedToImport();

        // Registrar AppModule
        await InjectionManager.instance.registerAppModule(appModule);

        // Buscar AuthService (que recebeu IClient via construtor)
        final authService = Modular.get<AuthServiceWithConstructor>();
        expect(authService, isNotNull);
        expect(authService.client, isNotNull);
        expect(authService.client, isA<IClient>());
      },
    );
  });
}

// ============================================================================
// MÓDULOS E CLASSES DE TESTE
// ============================================================================

/// AppModule que demonstra o PROBLEMA: imports processados antes de binds
class AppModuleWithClientBind extends Module {
  @override
  List<Module> imports() {
    // ❌ PROBLEMA: AuthModuleThatUsesGet será processado ANTES de binds()
    // Quando AuthModule.binds() executar, IClient ainda não existe
    return [AuthModuleThatUsesGet()];
  }

  @override
  void binds(Injector i) {
    // IClient é registrado DEPOIS que imports foram processados
    i.addSingleton<IClient>(() => ClientImpl());
  }

  @override
  List<ModularRoute> get routes => [];
}

/// Módulo importado que TENTA usar i.get() durante binds() - VAI FALHAR
class AuthModuleThatUsesGet extends Module {
  @override
  void binds(Injector i) {
    // ❌ PROBLEMA: Tenta usar i.get<IClient>() durante binds()
    // Mas IClient ainda não foi registrado porque AppModule.binds() não executou ainda
    try {
      final client = i.get<IClient>(); // ❌ Vai lançar exceção
      i.addSingleton<AuthService>(() => AuthService(client: client));
    } catch (e) {
      // Falha ao buscar IClient, registra sem client
      print('❌ Erro ao buscar IClient durante binds: $e');
      i.addSingleton<AuthService>(() => AuthService(client: null));
    }
  }

  @override
  List<ModularRoute> get routes => [];
}

/// AppModule com SOLUÇÃO 1: Use Modular.get() FORA de binds()
class AppModuleWithClientBindFixed extends Module {
  @override
  List<Module> imports() {
    return [AuthModuleLazy()];
  }

  @override
  void binds(Injector i) {
    i.addSingleton<IClient>(() => ClientImpl());
  }

  @override
  List<ModularRoute> get routes => [];
}

/// Módulo que NÃO tenta usar i.get() durante binds()
/// Usa lazy initialization via Modular.get() em métodos
class AuthModuleLazy extends Module {
  @override
  void binds(Injector i) {
    // ✅ SOLUÇÃO: Registra sem tentar buscar IClient
    // AuthServiceLazy buscará IClient via Modular.get() quando precisar
    i.addSingleton<AuthServiceLazy>(() => AuthServiceLazy());
  }

  @override
  List<ModularRoute> get routes => [];
}

/// AppModule com SOLUÇÃO 2: Passa dependências via construtor
class AppModuleWithClientPassedToImport extends Module {
  @override
  List<Module> imports() {
    // Passa IClient via construtor
    final client = ClientImpl();
    return [AuthModuleWithConstructorParam(client: client)];
  }

  @override
  void binds(Injector i) {
    // Também registra para uso geral
    i.addSingleton<IClient>(() => ClientImpl());
  }

  @override
  List<ModularRoute> get routes => [];
}

/// Módulo que recebe dependências via construtor
class AuthModuleWithConstructorParam extends Module {
  final IClient client;

  AuthModuleWithConstructorParam({required this.client});

  @override
  void binds(Injector i) {
    // ✅ SOLUÇÃO: Usa client recebido via construtor
    i.addSingleton<AuthServiceWithConstructor>(
      () => AuthServiceWithConstructor(client: client),
    );
  }

  @override
  List<ModularRoute> get routes => [];
}

// ============================================================================
// INTERFACES E IMPLEMENTAÇÕES
// ============================================================================

abstract class IClient {
  String get baseUrl;
}

class ClientImpl implements IClient {
  @override
  String get baseUrl => 'https://api.example.com';
}

class AuthService {
  final IClient? client;
  AuthService({this.client});
}

class AuthServiceLazy {
  // ✅ Busca IClient apenas quando necessário, não durante binds()
  IClient getClient() => Modular.get<IClient>();
}

class AuthServiceWithConstructor {
  final IClient client;
  AuthServiceWithConstructor({required this.client});
}
