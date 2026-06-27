import 'package:go_router_modular/src/module/module.dart';
import 'i_modular_route.dart';

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
