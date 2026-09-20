import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

/// [GoRouterDelegate] that reports when a navigation has been resolved.
///
/// `Router` calls [setNewRoutePath] at the end of **every** parse, even when the
/// resulting configuration equals the current one (the case of a guard that
/// redirects back to the route we are already on). It is the only point where
/// the redirects of that navigation are known to be finished and the new pages
/// are known to be built on the next frame.
class ModularRouterDelegate extends GoRouterDelegate {
  ModularRouterDelegate({
    required super.configuration,
    required super.builderWithNav,
    required super.errorPageBuilder,
    required super.errorBuilder,
    required super.observers,
    required super.routerNeglect,
    super.restorationScopeId,
    super.requestFocus,
    this.onNavigationSettled,
  });

  /// Called at the end of the frame that builds the pages of a resolved
  /// navigation, with the committed configuration.
  final void Function(RouteMatchList configuration)? onNavigationSettled;

  @override
  Future<void> setNewRoutePath(RouteMatchList configuration) {
    final settled = onNavigationSettled;
    if (settled == null) return super.setNewRoutePath(configuration);
    // `super.setNewRoutePath` may be asynchronous (it awaits `onExit`), and the
    // Router only schedules the frame that builds the pages once it has applied
    // the configuration, so the callback must go to the end of *that* frame.
    return super.setNewRoutePath(configuration).then((_) {
      SchedulerBinding.instance.addPostFrameCallback((_) => settled(currentConfiguration));
      SchedulerBinding.instance.ensureVisualUpdate();
    });
  }
}
