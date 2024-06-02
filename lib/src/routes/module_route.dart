import 'package:go_router_modular/go_router_modular.dart';

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
