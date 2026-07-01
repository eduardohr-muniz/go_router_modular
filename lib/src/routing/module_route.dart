import 'package:go_router_modular/src/module/module.dart';
import 'package:go_router_modular/src/routing/guards/route_guard.dart';
import 'i_modular_route.dart';

class ModuleRoute extends ModularRoute {
  final String path;
  final Module module;
  final String? name;

  /// Guards que protegem todas as rotas deste módulo, avaliados após o registro
  /// dos binds e em curto-circuito ("primeiro que barrar vence"). Veja
  /// [RouteGuard].
  final List<RouteGuard> guards;

  ModuleRoute(
    this.path, {
    required this.module,
    this.name,
    this.guards = const [],
  });
}
