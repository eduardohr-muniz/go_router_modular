import 'package:example/src/modules/async_binds/async_binds_module.dart';
import 'package:example/src/modules/auto_resolve/auto_resolve_module.dart';
import 'package:example/src/modules/binds_by_key/binds_by_key_module.dart';
import 'package:example/src/modules/example_event_module/example_event_module.dart';
import 'package:example/src/modules/home/home_module.dart';
import 'package:example/src/modules/imports_bug/imports_bug_module.dart';
import 'package:example/src/modules/shell_example/shell_module.dart';
import 'package:go_router_modular/go_router_modular.dart';

// Exportar tipos para uso em outros módulos
export 'package:example/src/modules/imports_bug/imports_bug_module.dart' show IClient, IAuthApi, ClientDioSimulated, AuthApiSimulated, AuthPhoneService;

/// AppModule que demonstra o problema de imports()
///
/// PROBLEMA:
/// - imports() é processado ANTES de binds()
/// - AuthPhoneModuleSimulated precisa de IClient durante seu binds()
/// - Mas IClient ainda não foi registrado porque AppModule.binds() não foi executado
class AppModule extends Module {
  @override
  // ❌ PROBLEMA: imports são processados ANTES de binds()
  // Quando AuthPhoneModuleSimulated tenta usar IClient durante seu binds(),
  // o IClient ainda não existe porque AppModule.binds() ainda não foi executado
  List<Module> imports() {
    return [AuthPhoneModuleSimulated()];
  }

  @override
  FutureBinds binds(Injector i) async {
    print('   ⏳ Simulando SharedPreferences.getInstance()...');
    await Future.delayed(Duration(seconds: 3));
    final sharedPrefs = FakeSharedPreferences();
    print('   ✅ SharedPreferences inicializado');

    i.addSingleton<ISharedPreferences>(() => sharedPrefs);

    print('   ┌─ AppModule.binds() INICIADO');

    // Registrar binds básicos (simulando IClient e IAuthApi)
    print('   │  Registrando IClient...');
    i.addSingleton<IClient>(
      () => ClientDioSimulated(baseUrl: 'https://api.example.com'),
    );
    print('   │  ✅ IClient registrado');

    // Tentar usar IClient que acabou de ser registrado
    print('   │  Registrando IAuthApi (usando IClient)...');
    i.addSingleton<IAuthApi>(
      () => AuthApiSimulated(client: i.get<IClient>()),
    );
    print('   │  ✅ IAuthApi registrado');

    // Manter o bind antigo para não quebrar outros exemplos
    print('   │  Registrando DioFake...');
    i.addSingleton(() => DioFake(baseUrl: 'https://padrao.com'));
    print('   │  ✅ DioFake registrado');

    print('   └─ AppModule.binds() CONCLUÍDO');
  }

  @override
  List<ModularRoute> get routes => [
        // Home - Fade
        ModuleRoute('/', module: HomeModule()),
        // Event - Slide Right to Left
        ModuleRoute('/event', module: ExampleEventModule()),
        // Auto Resolve - Rotate
        ModuleRoute('/auto-resolve', module: AutoResolveModule()),
        // Shell - Scale
        ModuleRoute('/shell', module: ShellModule()),
        // Binds by Key - Slide Bottom to Top
        ModuleRoute('/binds-by-key', module: BindsByKeyModule()),
        // Imports Bug Demo - Demonstra o problema de ordem de processamento
        ModuleRoute('/imports-bug', module: ImportsBugModule()),
        // Async Binds Demo - Demonstra binds assíncronos com imports
        ModuleRoute('/async-binds', module: AsyncBindsModule()),
      ];
}
