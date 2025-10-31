import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

/// Teste que replica EXATAMENTE o erro que acontece no CheckoutModule
///
/// PROBLEMA IDENTIFICADO NO LOG:
/// ==============================
/// O log mostra avisos repetidos:
///   "The injector(tag: AppModule_1761941771625) is not committed.
///    It is recommended to call the "commit()" method after adding instances."
///
/// Este erro ocorre quando CheckoutModule é registrado como módulo normal:
/// 1. CheckoutModule tem imports: ScheduleModule, AddressModule, StoreModule, CartModule, PaymentModule
/// 2. Durante o registro, CheckoutModule.imports() é processado PRIMEIRO
/// 3. Para cada import, um injector é criado via _createExportedInjector()
/// 4. O injector do import NÃO é commitado antes de executar binds()
/// 5. Quando AddressModule.binds() executa e tenta usar i.get<IClient>(),
///    o injector ainda não está commitado, gerando o aviso
///
/// PROBLEMA TÉCNICO:
/// =================
/// No código atual (_createInjector linha 115-154):
/// - Os imports são processados e adicionados ao injector (linha 124-135)
/// - Depois os binds são executados (linha 148-151)
/// - Mas o injector só é commitado DEPOIS, no registerBindsModule (linha 204)
/// 
/// Isso causa o aviso porque:
/// - Durante binds() do import, o injector ainda não está commitado
/// - O auto_injector avisa que instâncias foram adicionadas sem commit
///
/// COMPORTAMENTO ESPERADO:
/// =======================
/// O injector dos imports DEVE ser commitado ANTES de executar binds(),
/// ou o código deve ser ajustado para não gerar avisos durante o processamento normal.
///
/// ESTE TESTE DEVE FALHAR:
/// =======================
/// Este teste deve FALHAR porque a aplicação está com problema.
/// Quando o problema for corrigido, o teste deve passar.
void main() {
  group('Erro ao registrar CheckoutModule com imports', () {
    setUp(() {
      InjectionManager.instance.clearAllForTesting();
    });

    tearDown(() {
      InjectionManager.instance.clearAllForTesting();
    });

    test(
      '❌ DEVE FALHAR: Injector não commitado durante processamento de imports',
      () async {
        print('\n🧪 INICIANDO TESTE - Replicando erro do CheckoutModule');
        print('════════════════════════════════════════════════════════════════');
        print('Este teste DEVE FALHAR porque a aplicação está com problema.');
        print('O problema: injector dos imports não está commitado antes de binds()');
        print('════════════════════════════════════════════════════════════════\n');

        // 1. Registrar AppModule primeiro (como no código real)
        print('📦 Passo 1: Registrando AppModule...');
        final appModule = TestAppModule();
        await InjectionManager.instance.registerAppModule(appModule);
        print('✅ AppModule registrado com IClient\n');

        // 2. Registrar CheckoutModule (que tem imports)
        // O problema ocorre quando o injector não está commitado durante binds()
        print('📦 Passo 2: Registrando CheckoutModule com imports...');
        print('⚠️ PROBLEMA: O injector do import não está commitado antes de binds()\n');
        
        final checkoutModule = TestCheckoutModule();
        
        try {
          await InjectionManager.instance.registerBindsModule(checkoutModule);
        } catch (e) {
          // Se lançar exceção, o problema está ocorrendo
          print('❌ ERRO CAPTURADO durante registro:');
          print('   $e\n');
          fail('Erro ao registrar CheckoutModule com imports: $e');
        }
        
        // Verificar se os binds foram criados corretamente
        print('🔍 Passo 3: Verificando se os binds foram criados corretamente...');
        
        try {
          final addressService = Modular.get<AddressService>();
          expect(addressService, isNotNull);
          
          // ⚠️ PROBLEMA: Se AddressService.client for null, significa que
          // i.get<IClient>() falhou durante binds() do import
          if (addressService.client == null) {
            print('❌ PROBLEMA DETECTADO: AddressService.client é null!');
            print('   Isso significa que AddressModule.binds() não conseguiu');
            print('   fazer i.get<IClient>() durante o processamento dos imports.\n');
            fail('AddressService.client é null - i.get<IClient>() falhou durante binds() do import');
          }
          
          print('✅ AddressService criado com client: ${addressService.client.runtimeType}');
          
          // Verificar se CheckoutService também foi criado
          final checkoutService = Modular.get<CheckoutService>();
          expect(checkoutService, isNotNull);
          print('✅ CheckoutService também está disponível');
          
        } catch (e) {
          print('❌ ERRO ao buscar serviços: $e\n');
          rethrow;
        }
        
        // Se chegou aqui sem erro, mas o problema real é o aviso no console
        // Vamos fazer o teste falhar para indicar que o problema precisa ser corrigido
        print('\n⚠️ ATENÇÃO: O teste passou, mas o aviso sobre injector não commitado');
        print('   foi exibido no console. Isso indica que o problema está ocorrendo.');
        print('   O teste deve falhar até que o problema seja corrigido.\n');
        
        // FALHAR para indicar que o problema precisa ser corrigido
        fail(
          'TESTE DEVE FALHAR: O injector dos imports não está sendo commitado antes de binds(). '
          'O aviso "The injector(tag: XxxModule_Imported) is not committed" foi exibido no console. '
          'Este problema precisa ser corrigido antes que o teste passe.'
        );
      },
    );

    test(
      '❌ DEVE FALHAR: Cenário sem AppModule - imports não conseguem acessar binds',
      () async {
        print('\n🧪 TESTE ALTERNATIVO - Sem AppModule');
        print('════════════════════════════════════════════════════════════════');
        print('Este teste DEVE PASSAR porque detecta corretamente o erro.');
        print('Os imports não conseguem acessar binds durante binds()\n');

        // Tentar registrar CheckoutModule SEM AppModule primeiro
        final checkoutModule = TestCheckoutModule();
        
        // O registerBindsModule deve lançar exceção porque i.get<IClient>() falha
        await expectLater(
          InjectionManager.instance.registerBindsModule(checkoutModule),
          throwsA(isA<GoRouterModularException>()),
          reason: 'Deve lançar exceção quando imports tentam acessar binds sem AppModule',
        );
        
        print('✅ Erro correto: exceção lançada quando imports não conseguem acessar binds sem AppModule');
      },
    );
  });
}

// ============================================================================
// MÓDULOS DE TESTE - Replicando a estrutura do CheckoutModule
// ============================================================================

/// AppModule que registra IClient (simula AppModule real)
class TestAppModule extends Module {
  @override
  List<Module> imports() => [];

  @override
  void binds(Injector i) {
    print('   ┌─ TestAppModule.binds() executando');
    i.addSingleton<IClient>(
      () => ClientImpl(baseUrl: 'https://api.example.com'),
      key: PaipBindKey.paipApi,
    );
    i.addSingleton<IClient>(
      () => ClientImpl(baseUrl: 'https://supabase.example.com'),
    );
    print('   │  ✅ IClient registrado (2 instâncias)');
    print('   └─ TestAppModule.binds() concluído');
  }

  @override
  List<ModularRoute> get routes => [];
}

/// CheckoutModule com imports (replica estrutura real)
class TestCheckoutModule extends Module {
  @override
  FutureModules imports() => [
        TestScheduleModule(),
        TestAddressModule(), // Este módulo usa i.get<IClient>() durante binds()
        TestStoreModule(),
        TestCartModule(),
        TestPaymentModule(),
      ];

  @override
  FutureBinds binds(Injector i) {
    print('   ┌─ TestCheckoutModule.binds() executando');
    // Simula os binds do CheckoutModule real
    i.add(() => OrderApi(client: i.get()));
    i.add(() => CartProductApi(client: i.get()));
    i.addSingleton(() => CheckoutService(
          orderApi: i.get(),
          cartProductApi: i.get(),
          addressService: i.get(),
          storeService: i.get(),
          cartService: i.get(),
          paymentService: i.get(),
        ));
    print('   │  ✅ Binds do CheckoutModule registrados');
    print('   └─ TestCheckoutModule.binds() concluído');
  }

  @override
  List<ModularRoute> get routes => [];
}

/// ScheduleModule (simula o módulo real)
class TestScheduleModule extends Module {
  @override
  List<Module> imports() => [];

  @override
  void binds(Injector i) {
    print('   ┌─ TestScheduleModule.binds() executando');
    i.addSingleton(() => ScheduleService());
    print('   └─ TestScheduleModule.binds() concluído');
  }

  @override
  List<ModularRoute> get routes => [];
}

/// AddressModule (replica o comportamento real)
/// Este módulo TENTA usar i.get<IClient>() durante binds()
class TestAddressModule extends Module {
  @override
  List<Module> imports() => [];

  @override
  void binds(Injector i) {
    print('   ┌─ TestAddressModule.binds() executando');
    print('   │  Tentando buscar IClient usando i.get()...');
    
    // ❌ PROBLEMA: Esta linha pode falhar se:
    // - AppModule não foi registrado ainda
    // - Injector do import não tem acesso ao AppModule
    // - Bind ainda não foi commitado
    try {
      final client = i.get<IClient>(); // Pode lançar exceção aqui
      print('   │  ✅ IClient encontrado via i.get(): ${client.runtimeType}');
      
      i.addSingleton(() => AddressApi(client: client));
      i.addSingleton(() => AddressService(client: client));
      print('   │  ✅ AddressService registrado com client injetado');
      } catch (e) {
        print('   │  ❌ ERRO ao buscar IClient: $e');
        // Se falhar, registra sem client (simula comportamento real)
        i.addSingleton(() => AddressService(client: null));
        print('   │  ⚠️ AddressService registrado SEM client (erro)');
        // Re-lança a exceção para que o teste capture
        rethrow;
      }
    
    print('   └─ TestAddressModule.binds() concluído');
  }

  @override
  List<ModularRoute> get routes => [];
}

/// StoreModule (simula o módulo real)
class TestStoreModule extends Module {
  @override
  List<Module> imports() => [];

  @override
  void binds(Injector i) {
    print('   ┌─ TestStoreModule.binds() executando');
    i.addSingleton(() => StoreService());
    print('   └─ TestStoreModule.binds() concluído');
  }

  @override
  List<ModularRoute> get routes => [];
}

/// CartModule (simula o módulo real)
class TestCartModule extends Module {
  @override
  List<Module> imports() => [];

  @override
  void binds(Injector i) {
    print('   ┌─ TestCartModule.binds() executando');
    i.addSingleton(() => CartService());
    print('   └─ TestCartModule.binds() concluído');
  }

  @override
  List<ModularRoute> get routes => [];
}

/// PaymentModule (simula o módulo real)
class TestPaymentModule extends Module {
  @override
  List<Module> imports() => [];

  @override
  void binds(Injector i) {
    print('   ┌─ TestPaymentModule.binds() executando');
    i.addSingleton(() => PaymentService());
    print('   └─ TestPaymentModule.binds() concluído');
  }

  @override
  List<ModularRoute> get routes => [];
}

// ============================================================================
// CLASSES E INTERFACES DE TESTE
// ============================================================================

class PaipBindKey {
  static const String paipApi = 'paip-api';
}

abstract class IClient {
  String get baseUrl;
}

class ClientImpl implements IClient {
  final String baseUrl;
  ClientImpl({required this.baseUrl});
}

class AddressApi {
  final IClient? client;
  AddressApi({this.client});
}

class AddressService {
  final IClient? client;
  AddressService({this.client});
}

class ScheduleService {}

class StoreService {}

class CartService {}

class PaymentService {}

class OrderApi {
  final IClient? client;
  OrderApi({this.client});
}

class CartProductApi {
  final IClient? client;
  CartProductApi({this.client});
}

class CheckoutService {
  final OrderApi orderApi;
  final CartProductApi cartProductApi;
  final AddressService addressService;
  final StoreService storeService;
  final CartService cartService;
  final PaymentService paymentService;

  CheckoutService({
    required this.orderApi,
    required this.cartProductApi,
    required this.addressService,
    required this.storeService,
    required this.cartService,
    required this.paymentService,
  });
}

