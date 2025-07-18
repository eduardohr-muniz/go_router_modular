import 'package:flutter/material.dart';
import 'package:go_router_modular/src/utils/page_transition_enum.dart';

class Transition {
  Transition._();
  static Widget Function(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) builder({
    required PageTransition pageTransition,
    required void Function() configRouteManager,
  }) {
    return (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
      configRouteManager.call();
      switch (pageTransition) {
        case PageTransition.slideUp:
          return SlideTransition(
            position: Tween(begin: const Offset(0.0, 1.0), end: Offset.zero).animate(animation),
            child: child,
          );

        case PageTransition.slideDown:
          return SlideTransition(
            position: Tween(begin: const Offset(0.0, -1.0), end: Offset.zero).animate(animation),
            child: child,
          );

        case PageTransition.slideLeft:
          return SlideTransition(
            position: Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(animation),
            child: child,
          );

        case PageTransition.slideRight:
          return SlideTransition(
            position: Tween(begin: const Offset(-1.0, 0.0), end: Offset.zero).animate(animation),
            child: child,
          );

        case PageTransition.fade:
          return FadeTransition(
            opacity: animation,
            child: child,
          );

        case PageTransition.scale:
          return ScaleTransition(
            scale: animation,
            child: child,
          );

        case PageTransition.rotation:
          return RotationTransition(
            turns: animation,
            child: child,
          );
      }
    };
  }
}
