import 'package:example/src/modules/auto_resolve/auto_resolve_module.dart';
import 'package:example/src/modules/binds_by_key/binds_by_key_module.dart';
import 'package:example/src/modules/example_event_module/example_event_module.dart';
import 'package:example/src/modules/home/home_module.dart';
import 'package:example/src/modules/shell_example/shell_module.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AppModule extends Module {
  @override
  void binds(Injector i) {
    i.addSingleton(() => DioFake(baseUrl: 'https://padrao.com'));
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
        ModuleRoute('/binds-by-key', module: BindsByKeyModule())
      ];
}
