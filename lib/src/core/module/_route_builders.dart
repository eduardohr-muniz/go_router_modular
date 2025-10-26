part of 'module.dart';

/// Builders para widgets de rota
extension RouteBuilders on Module {
  Widget _buildRouteChild(BuildContext context, {required GoRouterState state, required ChildRoute route}) {
    // Executa registro com prioridade (fire and forget - não bloqueia UI)
    return route.child(context, state);
  }

  Page<dynamic> _buildCustomTransitionPage(
    BuildContext context, {
    required GoRouterState state,
    required ChildRoute route,
    Duration? parentDuration,
    GoTransition? parentTransition,
    Module? module,
  }) {
    final resolvedTransition = route.resolveTransition(parentTransition);
    final resolvedDuration = route.resolveDuration(parentDuration);

    if (resolvedTransition != null) {
      // Configure default duration if transition is provided but duration is not
      if (resolvedDuration != null) {
        GoTransition.defaultDuration = resolvedDuration;
      }

      // Use GoTransition.build() correctly - it returns a GoRouterPageBuilder
      final pageBuilder = resolvedTransition.build(
        builder: (context, state) => ParentWidgetObserver(
          // initState: (module) async {},
          onDispose: (module) => _disposeModule(module),
          didChangeDependencies: (module) => _onDidChange(module),
          module: module ?? this,
          child: route.child(context, state),
        ),
      );

      // Call the pageBuilder to get the actual Page
      return pageBuilder(context, state);
    }

    // Fallback to default page if no transition is resolved
    return MaterialPage(
      key: state.pageKey,
      child: ParentWidgetObserver(
        // initState: (module) async {},
        onDispose: (module) => _disposeModule(module),
        didChangeDependencies: (module) => _onDidChange(module),
        module: module ?? this,
        child: route.child(context, state),
      ),
    );
  }
}
