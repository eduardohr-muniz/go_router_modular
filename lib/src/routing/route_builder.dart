import 'package:go_router/go_router.dart';
import 'package:go_router_modular/src/module/module.dart';
import 'package:go_router_modular/src/routing/builders/child_route_builder.dart';
import 'package:go_router_modular/src/routing/builders/module_route_builder.dart';
import 'package:go_router_modular/src/routing/builders/shell_route_builder.dart';
import 'package:go_router_modular/src/routing/child_route.dart';
import 'package:go_router_modular/src/routing/module_route.dart';
import 'package:go_router_modular/src/routing/path/route_path_normalizer.dart';
import 'package:go_router_modular/src/routing/redirect/module_route_lifecycle.dart';

/// Orquestrador que constrói as rotas do `go_router` a partir das rotas de um
/// [Module], delegando a construção de cada tipo de rota ao builder coeso
/// correspondente (child, module, shell/stateful).
class ModularRouteBuilder {
  final Module module;

  ModularRouteBuilder(this.module);

  List<RouteBase> buildRoutes({String modulePath = '', bool topLevel = false}) {
    final lifecycle = ModuleRouteLifecycle(module);
    const childBuilder = ChildRouteBuilder();
    final moduleBuilder = ModuleRouteBuilder(
      lifecycle: lifecycle,
      buildNested: (nestedModule, nestedPath) => ModularRouteBuilder(nestedModule)
          .buildRoutes(modulePath: nestedPath, topLevel: false),
    );
    final shellBuilder = ModularShellRouteBuilder(
      parentModule: module,
      childBuilder: childBuilder,
      moduleBuilder: moduleBuilder,
      lifecycle: lifecycle,
    );

    return [
      ...module.routes
          .whereType<ChildRoute>()
          .where((route) => RoutePathNormalizer.adjustRoute(route.path) != '/')
          .map((route) => childBuilder.build(childRoute: route, topLevel: topLevel)),
      ...module.routes
          .whereType<ModuleRoute>()
          .map((moduleRoute) => moduleBuilder.build(
              module: moduleRoute, modulePath: modulePath, topLevel: topLevel)),
      ...shellBuilder.buildShellRoutes(topLevel, modulePath),
      ...shellBuilder.buildStatefulShellRoutes(topLevel, modulePath),
    ];
  }
}
