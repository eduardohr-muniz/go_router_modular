import 'package:example/src/modules/auto_resolve/auto_resolve_module.dart';
import 'package:example/src/modules/example_event_module/example_event_module.dart';
import 'package:example/src/modules/home/home_module.dart';
import 'package:example/src/modules/shell_example/shell_module.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AppModule extends Module {
  @override
  List<ModularRoute> get routes => [
        ModuleRoute('/', module: HomeModule()),
        ModuleRoute('/event', module: ExampleEventModule()),
        ModuleRoute(
          '/auto-resolve',
          module: AutoResolveModule(),
        ),
        ModuleRoute(
          '/shell',
          module: ShellModule(),
        )
      ];
}
