import 'package:go_router_modular/go_router_modular.dart';

class ModuleRoute extends ModularRoute {
  final Module module;
  final String? name;

  ModuleRoute(
    super.route, {
    required this.module,
    this.name,
  });
}
