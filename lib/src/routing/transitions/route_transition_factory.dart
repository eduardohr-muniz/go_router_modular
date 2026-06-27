import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/src/routing/path/route_path_normalizer.dart';
import 'package:go_transitions/go_transitions.dart';

/// Constrói um [GoRoute] aplicando uma [GoTransition], incluindo o override de
/// duração via `GoTransition.defaultDuration`.
///
/// Extraído de `route_builder.dart` para isolar a responsabilidade de transição
/// (e a manipulação do estado global de duração do `go_transitions`).
class RouteTransitionFactory {
  const RouteTransitionFactory._();

  static GoRoute buildGoRouteWithTransition({
    required String path,
    String? name,
    required GoTransition transition,
    required Widget Function(BuildContext, GoRouterState) builder,
    GlobalKey<NavigatorState>? parentNavigatorKey,
    FutureOr<String?> Function(BuildContext, GoRouterState)? redirect,
    required bool topLevel,
    Duration? transitionDuration,
    FutureOr<bool> Function(BuildContext, GoRouterState)? onExit,
  }) {
    if (transitionDuration != null) {
      final customDuration = transitionDuration;

      pageBuilder(BuildContext context, GoRouterState state) {
        final widget = builder(context, state);
        final originalDuration = GoTransition.defaultDuration;
        GoTransition.defaultDuration = customDuration;

        try {
          final tempPage =
              transition.build(builder: (_, __) => widget)(context, state);

          if (tempPage is CustomTransitionPage) {
            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: widget,
              transitionsBuilder: tempPage.transitionsBuilder,
              transitionDuration: customDuration,
              reverseTransitionDuration: customDuration,
              opaque: tempPage.opaque,
              barrierDismissible: tempPage.barrierDismissible,
              barrierColor: tempPage.barrierColor,
              barrierLabel: tempPage.barrierLabel,
              maintainState: tempPage.maintainState,
            );
          }

          return tempPage;
        } finally {
          GoTransition.defaultDuration = originalDuration;
        }
      }

      return GoRoute(
        path: RoutePathNormalizer.normalizePath(path: path, topLevel: topLevel),
        name: name,
        pageBuilder: pageBuilder,
        parentNavigatorKey: parentNavigatorKey,
        redirect: redirect,
        onExit: onExit,
      );
    }

    return GoRoute(
      path: RoutePathNormalizer.normalizePath(path: path, topLevel: topLevel),
      name: name,
      pageBuilder: transition.build(builder: builder),
      parentNavigatorKey: parentNavigatorKey,
      redirect: redirect,
      onExit: onExit,
    );
  }
}
