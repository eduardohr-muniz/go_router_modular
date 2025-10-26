import 'dart:developer';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

void main() {
  setUp(() async {
    await InjectionManager.instance.clearAllForTesting();
  });

  tearDown(() async {
    await InjectionManager.instance.clearAllForTesting();
  });

  test('✅ Teste Complexo: Múltiplas interfaces com dependências', () async {
    log('🔬 Iniciando teste complexo de inferência automática...', name: 'TEST');

    // Criar AppModule vazio
    final appModule = AppModuleEmpty();
    await InjectionManager.instance.registerAppModule(appModule);

    final module = _ComplexModule();

    // Registrar o módulo
    await InjectionManager.instance.registerBindsModule(module);
    await Future.delayed(Duration(milliseconds: 10));

    // Definir contexto
    InjectionManager.instance.setModuleContext(_ComplexModule);

    log('🔍 Tentando resolver dependências...', name: 'TEST');

    // ✅ TESTE: Verificar se as dependências foram resolvidas corretamente
    final repository = Modular.get<IRepository>();
    log('✅ Repository resolvido: ${repository.runtimeType}', name: 'TEST');
    expect(repository, isA<MyRepository>());

    final service = Modular.get<IService>();
    log('✅ Service resolvido: ${service.runtimeType}', name: 'TEST');
    expect(service, isA<MyService>());
    expect(service.repository, isNotNull); // ⚠️ DEVE TER DEPENDÊNCIA RESOLVIDA!

    final controller = Modular.get<IController>();
    log('✅ Controller resolvido: ${controller.runtimeType}', name: 'TEST');
    expect(controller, isA<MyController>());
    expect(controller.service, isNotNull); // ⚠️ DEVE TER DEPENDÊNCIA RESOLVIDA!

    log('🎉 TESTE PASSOU! Auto-resolução de dependências funcionou!', name: 'TEST');
  });
}

// AppModule vazio para o teste
class AppModuleEmpty extends Module {
  @override
  void binds(Injector i) {
    // Vazio
  }
}

// ============ MÓDULO COM REBIS SEM TIPAGEM ============
class _ComplexModule extends Module {
  @override
  void binds(Injector i) {
    log('📝 Registrando binds...', name: 'TEST');

    // Registrar as interfaces com suas implementações
    // auto_injector resolve dependências automaticamente!

    i.add<IRepository>(() => MyRepository()); // Factory simples
    i.add<IService>(() => MyService(i.get<IRepository>())); // Resolve dependência manualmente
    i.add<IController>(() => MyController(i.get<IService>())); // Resolve dependência manualmente

    log('📝 Binds registrados!', name: 'TEST');
  }
}

// ============ INTERFACES ============
abstract class IRepository {
  String getData();
}

abstract class IService {
  IRepository get repository;
  String processData();
}

abstract class IController {
  IService get service;
  void handleRequest();
}

abstract class IApiClient {
  void makeRequest();
}

abstract class IApiService {
  IApiClient get client;
  void fetchData();
}

// ============ IMPLEMENTAÇÕES ============
class MyRepository implements IRepository {
  @override
  String getData() => 'Data from MyRepository';
}

class MyService implements IService {
  final IRepository _repository;

  MyService(this._repository);

  @override
  IRepository get repository => _repository;

  @override
  String processData() => 'Processed: ${_repository.getData()}';
}

class MyController implements IController {
  final IService _service;

  MyController(this._service);

  @override
  IService get service => _service;

  @override
  void handleRequest() {
    log('Controller handling: ${_service.processData()}', name: 'CONTROLLER');
  }
}

class HttpApiClient implements IApiClient {
  @override
  void makeRequest() {
    log('Making HTTP request', name: 'API_CLIENT');
  }
}

class MyApiService implements IApiService {
  final IApiClient _client;

  MyApiService(this._client);

  @override
  IApiClient get client => _client;

  @override
  void fetchData() {
    log('Fetching data via API client', name: 'API_SERVICE');
    _client.makeRequest();
  }
}
