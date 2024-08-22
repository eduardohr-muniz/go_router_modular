import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/module.dart';
import 'package:go_router_modular/src/routes/i_modular_route.dart';

class ModuleRoute extends ModularRoute {
  final String path;
  final Module module;
  final String? name;

  ModuleRoute(
    this.path, {
    required this.module,
    this.name,
  });
}
