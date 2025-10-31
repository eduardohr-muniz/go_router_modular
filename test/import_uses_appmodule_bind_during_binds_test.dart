import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

/// Teste focado que replica o erro EXATO:
/// Um import do AppModule tenta usar i.get<T>() durante binds() para buscar
/// um bind que foi registrado no AppModule.
///
/// COMPORTAMENTO ESPERADO:
/// ✅ O import DEVE conseguir buscar binds do AppModule durante seu binds()
///
/// PROBLEMA ATUAL:
/// ❌ O import NÃO consegue porque:
///    1. AppModule.imports() é processado ANTES de AppModule.binds()
///    2. Quando import.binds() executa, AppModule.binds() ainda não foi chamado
///    3. Resultado: i.get<IClient>() lança exceção
///
/// SOLUÇÃO NECESSÁRIA:
/// Para AppModule especificamente, processar:
/// 1. AppModule.binds() PRIMEIRO
/// 2. AppModule.imports() DEPOIS
///
/// Este teste deve PASSAR quando a solução estiver implementada.
void main() {
  group('Import usa i.get() durante binds() para buscar bind do AppModule', () {
    setUp(() {
      InjectionManager.instance.clearAllForTesting();
    });

    tearDown(() {
      InjectionManager.instance.clearAllForTesting();
    });

    test(
      'Import DEVE conseguir buscar bind do AppModule usando i.get() durante binds()',
      () async {
        print('\n🧪 INICIANDO TESTE');
        print('════════════════════════════════════════════════════════════════');

        // Criar AppModule que:
        // 1. Tem imports (AuthModule)
        // 2. Registra IClient em binds()
        final appModule = TestAppModule();

        print('📦 Registrando AppModule...');
        await InjectionManager.instance.registerAppModule(appModule);
        print('✅ AppModule registrado\n');

        // Verificar que AppModule registrou IClient
        print('🔍 Verificando se IClient do AppModule está disponível...');
        final client = Modular.get<IClient>();
        expect(client, isNotNull, reason: 'IClient deve estar registrado no AppModule');
        expect(client, isA<ClientImpl>());
        print('✅ IClient encontrado: ${client.runtimeType}\n');

        // Buscar AuthService (que foi registrado pelo import)
        print('🔍 Buscando AuthService do módulo importado...');
        final authService = Modular.get<AuthService>();
        expect(authService, isNotNull, reason: 'AuthService deve estar registrado');
        print('✅ AuthService encontrado\n');

        // TESTE PRINCIPAL: AuthService.client NÃO deve ser null
        // Se for null, significa que o import não conseguiu buscar IClient durante binds()
        print('🎯 VERIFICAÇÃO PRINCIPAL:');
        print('   AuthService.client deveria ter sido injetado durante AuthModule.binds()');
        print('   usando i.get<IClient>() que busca no AppModule');
        
        expect(
          authService.client,
          isNotNull,
          reason:
              'AuthService.client NÃO deve ser null! '
              'AuthModule.binds() deve ter conseguido fazer i.get<IClient>() '
              'para buscar IClient do AppModule',
        );
        
        print('   ✅ AuthService.client = ${authService.client.runtimeType}');
        expect(authService.client, isA<IClient>());
        expect(authService.client!.name, equals('ClientImpl from AppModule'));
        
        print('\n════════════════════════════════════════════════════════════════');
        print('✅ TESTE PASSOU! Import conseguiu usar i.get() durante binds()');
        print('════════════════════════════════════════════════════════════════\n');
      },
    );

    test(
      'Import consegue usar i.get() para MÚLTIPLOS binds do AppModule',
      () async {
        final appModule = TestAppModuleWithMultipleBinds();
        await InjectionManager.instance.registerAppModule(appModule);

        final complexService = Modular.get<ComplexService>();
        expect(complexService, isNotNull);
        
        // Verifica que TODOS os binds foram resolvidos durante AuthModule.binds()
        expect(complexService.client, isNotNull, reason: 'IClient deve ter sido injetado');
        expect(complexService.config, isNotNull, reason: 'Config deve ter sido injetado');
        expect(complexService.logger, isNotNull, reason: 'Logger deve ter sido injetado');
        
        expect(complexService.client!.name, equals('ClientImpl from AppModule'));
        expect(complexService.config!.apiUrl, equals('https://api.example.com'));
        expect(complexService.logger!.level, equals('DEBUG'));
      },
    );
  });
}

// ============================================================================
// MÓDULOS DE TESTE
// ============================================================================

/// AppModule que importa AuthModule e registra IClient
class TestAppModule extends Module {
  @override
  List<Module> imports() {
    return [TestAuthModule()];
  }

  @override
  void binds(Injector i) {
    print('   ┌─ TestAppModule.binds() executando');
    i.addSingleton<IClient>(() => ClientImpl());
    print('   │  ✅ IClient registrado');
    print('   └─ TestAppModule.binds() concluído');
  }

  @override
  List<ModularRoute> get routes => [];
}

/// Módulo importado que PRECISA usar i.get<IClient>() durante binds()
class TestAuthModule extends Module {
  @override
  void binds(Injector i) {
    print('   ┌─ TestAuthModule.binds() executando');
    print('   │  Tentando buscar IClient do AppModule usando i.get()...');
    
    // TESTE CRÍTICO: Esta linha deve FUNCIONAR
    // i.get<IClient>() deve buscar no AppModule
    final client = i.get<IClient>();
    print('   │  ✅ IClient encontrado via i.get(): ${client.runtimeType}');
    
    i.addSingleton<AuthService>(() => AuthService(client: client));
    print('   │  ✅ AuthService registrado com client injetado');
    print('   └─ TestAuthModule.binds() concluído');
  }

  @override
  List<ModularRoute> get routes => [];
}

/// AppModule com múltiplos binds
class TestAppModuleWithMultipleBinds extends Module {
  @override
  List<Module> imports() {
    return [TestAuthModuleComplex()];
  }

  @override
  void binds(Injector i) {
    i.addSingleton<IClient>(() => ClientImpl());
    i.addSingleton<IConfig>(() => ConfigImpl());
    i.addSingleton<ILogger>(() => LoggerImpl());
  }

  @override
  List<ModularRoute> get routes => [];
}

/// Módulo que busca MÚLTIPLOS binds do AppModule
class TestAuthModuleComplex extends Module {
  @override
  void binds(Injector i) {
    // Busca múltiplos binds do AppModule durante binds()
    final client = i.get<IClient>();
    final config = i.get<IConfig>();
    final logger = i.get<ILogger>();
    
    i.addSingleton<ComplexService>(
      () => ComplexService(
        client: client,
        config: config,
        logger: logger,
      ),
    );
  }

  @override
  List<ModularRoute> get routes => [];
}

// ============================================================================
// CLASSES DE TESTE
// ============================================================================

abstract class IClient {
  String get name;
}

class ClientImpl implements IClient {
  @override
  String get name => 'ClientImpl from AppModule';
}

class AuthService {
  final IClient? client;
  AuthService({this.client});
}

abstract class IConfig {
  String get apiUrl;
}

class ConfigImpl implements IConfig {
  @override
  String get apiUrl => 'https://api.example.com';
}

abstract class ILogger {
  String get level;
}

class LoggerImpl implements ILogger {
  @override
  String get level => 'DEBUG';
}

class ComplexService {
  final IClient? client;
  final IConfig? config;
  final ILogger? logger;
  
  ComplexService({
    this.client,
    this.config,
    this.logger,
  });
}

