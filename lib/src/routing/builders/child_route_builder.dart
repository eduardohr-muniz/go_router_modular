import 'package:go_router/go_router.dart';
import 'package:go_router_modular/src/routing/child_route.dart';
import 'package:go_router_modular/src/routing/guards/guard_resolver.dart';
import 'package:go_router_modular/src/routing/modular_router_runtime.dart';
import 'package:go_router_modular/src/routing/path/route_path_normalizer.dart';
import 'package:go_router_modular/src/routing/transitions/route_transition_factory.dart';
import 'package:go_router_modular/src/ui/once_builder.dart';

/// Constrói o [GoRoute] de uma [ChildRoute] (rota folha), aplicando
/// `pageBuilder`/transição quando presentes e envolvendo o widget em
/// [OnceBuilder] para evitar reinstanciar binds factory no rebuild.
class ChildRouteBuilder {
  const ChildRouteBuilder();

  GoRoute build({required ChildRoute childRoute, required bool topLevel}) {
    final redirect = resolveGuards(
      childRoute.guards,
      // ignore: deprecated_member_use_from_same_package
      legacyRedirect: childRoute.redirect,
    );

    if (childRoute.pageBuilder != null) {
      return GoRoute(
        path: RoutePathNormalizer.normalizePath(
            path: childRoute.path, topLevel: topLevel),
        name: childRoute.name,
        pageBuilder: childRoute.pageBuilder,
        parentNavigatorKey: childRoute.parentNavigatorKey,
        redirect: redirect,
        onExit: childRoute.onExit,
      );
    }

    final transition = childRoute.transition ?? modularDefaultTransition;

    if (transition != null) {
      return RouteTransitionFactory.buildGoRouteWithTransition(
        path: childRoute.path,
        name: childRoute.name,
        transition: transition,
        builder: (context, state) => OnceBuilder(
          builder: (_) => childRoute.child(context, state),
        ),
        parentNavigatorKey: childRoute.parentNavigatorKey,
        redirect: redirect,
        topLevel: topLevel,
        transitionDuration: childRoute.transitionDuration,
        onExit: childRoute.onExit,
      );
    }

    return GoRoute(
      path: RoutePathNormalizer.normalizePath(
          path: childRoute.path, topLevel: topLevel),
      name: childRoute.name,
      builder: (context, state) => OnceBuilder(
        builder: (_) => childRoute.child(context, state),
      ),
      parentNavigatorKey: childRoute.parentNavigatorKey,
      redirect: redirect,
      onExit: childRoute.onExit,
    );
  }
}
