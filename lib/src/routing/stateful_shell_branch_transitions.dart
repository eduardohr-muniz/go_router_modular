import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_transitions/go_transitions.dart';

/// Presets de [ShellNavigationContainerBuilder] para animar a troca entre **branches**
/// de um [StatefulShellRoute], no padrão do exemplo oficial
/// [custom stateful shell](https://github.com/flutter/packages/blob/main/packages/go_router/example/lib/others/custom_stateful_shell_route.dart)
/// ([AnimatedBranchContainer]).
///
/// Para usar o mesmo visual das rotas configuradas com `GoTransitions` (ex.: fade,
/// slide), utilize [StatefulShellBranchTransitions.withGoTransition].
abstract final class StatefulShellBranchTransitions {
  StatefulShellBranchTransitions._();

  /// Troca entre branches usando o mesmo construtor [GoTransitions] aplicado ao
  /// `pageBuilder` das [GoRoute] (via [GoTransitionRoute.buildTransitions]).
  ///
  /// [transitionDuration] / [reverseTransitionDuration] opcionais substituem as de
  /// [GoTransition.settings] (como ao configurar uma rota com duração custom).
  /// Quando **ambos** são `null`, a transição é usada como está (`settings` do preset).
  /// O resolver do `StatefulShellModularRoute` em geral envia durações já resolvidas
  /// (defaults globais inclusos), logo normalmente entra pelo ramo com `copyWith`.
  static ShellNavigationContainerBuilder withGoTransition(
    GoTransition transition, {
    Duration? transitionDuration,
    Duration? reverseTransitionDuration,
  }) {
    final merged = transitionDuration == null && reverseTransitionDuration == null
        ? transition
        : transition.copyWith(
            settings: transition.settings.copyWith(
              duration: transitionDuration ?? transition.settings.duration,
              reverseDuration: reverseTransitionDuration ?? transition.settings.reverseDuration,
            ),
          );

    return (
      BuildContext context,
      StatefulNavigationShell navigationShell,
      List<Widget> children,
    ) {
      assert(children.isNotEmpty, 'StatefulShell deve ter pelo menos uma branch.');
      return _ShellGoTransitionSwitcher(
        navigationShell: navigationShell,
        branchChildren: children,
        transition: merged,
      );
    };
  }

  /// Fade entre branches; [duration] usa [GoTransition.defaultDuration] quando omitida.
  ///
  /// Para alinhar de fato ao pacote `go_transitions`, prefira
  /// [withGoTransition] com `GoTransitions.fade`.
  static ShellNavigationContainerBuilder animatedFadeBetweenBranches({
    Duration? duration,
    Curve curve = Curves.easeOut,
  }) {
    final effectiveDuration = duration ?? GoTransition.defaultDuration;

    return (
      BuildContext context,
      StatefulNavigationShell navigationShell,
      List<Widget> children,
    ) {
      final currentIndex = navigationShell.currentIndex;
      return Stack(
        fit: StackFit.expand,
        children: [
          for (var i = 0; i < children.length; i++)
            AnimatedOpacity(
              opacity: i == currentIndex ? 1 : 0,
              duration: effectiveDuration,
              curve: curve,
              child: _branchNavigatorWrapper(i, currentIndex, children[i]),
            ),
        ],
      );
    };
  }

  /// Fade com leve escala (como o exemplo do go_router com `scale` 1 → 1.5).
  static ShellNavigationContainerBuilder animatedFadeScaleBetweenBranches({
    Duration? duration,
    Curve curve = Curves.easeOut,
    double inactiveScale = 1.05,
  }) {
    final effectiveDuration = duration ?? GoTransition.defaultDuration;

    return (
      BuildContext context,
      StatefulNavigationShell navigationShell,
      List<Widget> children,
    ) {
      final currentIndex = navigationShell.currentIndex;
      return Stack(
        fit: StackFit.expand,
        children: [
          for (var i = 0; i < children.length; i++)
            AnimatedScale(
              scale: i == currentIndex ? 1 : inactiveScale,
              duration: effectiveDuration,
              curve: curve,
              child: AnimatedOpacity(
                opacity: i == currentIndex ? 1 : 0,
                duration: effectiveDuration,
                curve: curve,
                child: _branchNavigatorWrapper(i, currentIndex, children[i]),
              ),
            ),
        ],
      );
    };
  }

  static Widget _branchNavigatorWrapper(int index, int currentIndex, Widget navigator) {
    return IgnorePointer(
      ignoring: index != currentIndex,
      child: TickerMode(enabled: index == currentIndex, child: navigator),
    );
  }
}

class _ShellGoTransitionSwitcher extends StatefulWidget {
  const _ShellGoTransitionSwitcher({
    required this.navigationShell,
    required this.branchChildren,
    required this.transition,
  });

  final StatefulNavigationShell navigationShell;
  final List<Widget> branchChildren;
  final GoTransition transition;

  @override
  State<_ShellGoTransitionSwitcher> createState() => _ShellGoTransitionSwitcherState();
}

class _ShellGoTransitionSwitcherState extends State<_ShellGoTransitionSwitcher>
    with SingleTickerProviderStateMixin {
  static const Animation<double> _steadyPrimary = AlwaysStoppedAnimation<double>(1);
  static const Animation<double> _steadySecondary = AlwaysStoppedAnimation<double>(0);

  late GoTransitionRoute _route;
  late AnimationController _controller;

  int _steadyIndex = 0;
  int _fromIndex = 0;
  int _toIndex = 0;
  bool _animatingBetweenBranches = false;

  Duration get _effectiveDuration =>
      widget.transition.settings.duration ?? GoTransition.defaultDuration;

  Duration get _effectiveReverseDuration =>
      widget.transition.settings.reverseDuration ??
      GoTransition.defaultReverseDuration ??
      _effectiveDuration;

  @override
  void initState() {
    super.initState();

    final index = widget.navigationShell.currentIndex;
    _steadyIndex = index;
    _fromIndex = index;
    _toIndex = index;

    _route = GoTransitionRoute(
      transition: widget.transition,
      builder: (_) => const SizedBox.shrink(),
    );

    _controller = AnimationController(
      vsync: this,
      duration: _effectiveDuration,
      reverseDuration: _effectiveReverseDuration,
    )..value = 1;

    _controller.addStatusListener(_onAnimationStatus);
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (!_animatingBetweenBranches) return;
    setState(() {
      _steadyIndex = _toIndex;
      _animatingBetweenBranches = false;
      _fromIndex = _steadyIndex;
      _toIndex = _steadyIndex;
      _controller.value = 1;
    });
  }

  void _applyTransitionConfig() {
    _route = GoTransitionRoute(
      transition: widget.transition,
      builder: (_) => const SizedBox.shrink(),
    );
    _controller.duration = _effectiveDuration;
    _controller.reverseDuration = _effectiveReverseDuration;
  }

  /// Encerra animação atual e mantém o destino da última navegação (_toIndex) estável.
  void _snapInterruptedAnimationToEnd() {
    if (!_animatingBetweenBranches) return;
    _controller.stop();
    _controller.value = 1;
    _steadyIndex = _toIndex;
    _animatingBetweenBranches = false;
    _fromIndex = _steadyIndex;
    _toIndex = _steadyIndex;
  }

  @override
  void didUpdateWidget(covariant _ShellGoTransitionSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);

    final transitionChanged = !identical(widget.transition, oldWidget.transition);

    if (transitionChanged) {
      if (_animatingBetweenBranches) {
        _snapInterruptedAnimationToEnd();
      }
      _applyTransitionConfig();
      if (!_animatingBetweenBranches) {
        _controller.value = 1;
      }
    }

    final target = widget.navigationShell.currentIndex;

    if (target == _steadyIndex && !_animatingBetweenBranches) {
      return;
    }

    if (_animatingBetweenBranches && target != _toIndex) {
      _snapInterruptedAnimationToEnd();
    }

    if (target == _steadyIndex && !_animatingBetweenBranches) {
      return;
    }

    setState(() {
      _animatingBetweenBranches = true;
      _fromIndex = _steadyIndex;
      _toIndex = target;
      _controller.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final children = widget.branchChildren;

    if (!_animatingBetweenBranches) {
      return Stack(
        fit: StackFit.expand,
        children: [
          for (var i = 0; i < children.length; i++)
            Positioned.fill(
              child: Offstage(
                offstage: i != _steadyIndex,
                child: IgnorePointer(
                  ignoring: i != _steadyIndex,
                  child: TickerMode(
                    enabled: i == _steadyIndex,
                    child: _route.buildTransitions(
                      context,
                      _steadyPrimary,
                      _steadySecondary,
                      children[i],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          if (i != _fromIndex && i != _toIndex)
            Positioned.fill(
              child: Offstage(
                offstage: true,
                child: IgnorePointer(
                  ignoring: true,
                  child: TickerMode(
                    enabled: false,
                    child: children[i],
                  ),
                ),
              ),
            )
          else if (i == _fromIndex)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: TickerMode(
                  enabled: _controller.isAnimating,
                  child: _route.buildTransitions(
                    context,
                    ReverseAnimation(_controller.view),
                    _steadySecondary,
                    children[i],
                  ),
                ),
              ),
            )
          else
            Positioned.fill(
              child: IgnorePointer(
                ignoring: false,
                child: TickerMode(
                  enabled: true,
                  child: _route.buildTransitions(
                    context,
                    _controller.view,
                    _steadySecondary,
                    children[i],
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
