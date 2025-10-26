import 'package:go_router_modular/go_router_modular.dart';

class ModuleRoute extends ModularRoute {
  final String path;
  final Module module;
  final String? name;
  final GoTransition? transition;
  final Duration? duration;

  ModuleRoute(
    this.path, {
    required this.module,
    this.name,
    this.transition,
    this.duration,
  });

  /// Resolves the transition for this route, inheriting from parent scope if not defined
  GoTransition? resolveTransition(GoTransition? parentTransition) {
    return transition ?? parentTransition;
  }

  /// Resolves the duration for this route, inheriting from parent scope if not defined
  Duration? resolveDuration(Duration? parentDuration) {
    return duration ?? parentDuration;
  }
}
