import 'package:example/src/modules/auto_resolve/auto_resolve_module.dart';
import 'package:example/src/modules/binds_by_key/binds_by_key_module.dart';
import 'package:example/src/modules/example_event_module/example_event_module.dart';
import 'package:example/src/modules/home/home_module.dart';
import 'package:example/src/modules/shell_example/shell_module.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AppModule extends Module {
  @override
  FutureBinds binds(Injector i) {
    i.addSingleton(() => DioFake(baseUrl: 'https://padrao.com'));
  }

  @override
  List<ModularRoute> get routes => [
        // 🏠 Home Module - Transição padrão fadeUpwards
        ModuleRoute(
          '/',
          module: HomeModule(),
          transition: GoTransitions.fadeUpwards,
          duration: Duration(milliseconds: 300),
        ),

        // 🎉 Event Module - Transição slide da direita com fade
        ModuleRoute(
          '/event',
          module: ExampleEventModule(),
          transition: GoTransitions.slide.toRight.withFade,
          duration: Duration(milliseconds: 400),
        ),

        // 🔧 Auto Resolve Module - Transição scale com fade
        ModuleRoute(
          '/auto-resolve',
          module: AutoResolveModule(),
          transition: GoTransitions.scale.withFade,
          duration: Duration(milliseconds: 500),
        ),

        // 🐚 Shell Module - Transição cupertino (iOS style)
        ModuleRoute(
          '/shell',
          module: ShellModule(),
          transition: GoTransitions.cupertino,
          duration: Duration(milliseconds: 350),
        ),

        // 🔑 Binds by Key Module - Transição slide de baixo para cima
        ModuleRoute(
          '/binds-by-key',
          module: BindsByKeyModule(),
          transition: GoTransitions.slide.toTop.withFade,
          duration: Duration(milliseconds: 450),
        )
      ];
}
