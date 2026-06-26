import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class ParentWidgetObserver extends StatefulWidget {
  final void Function(Module module) onDispose;
  final void Function(Module module) didChangeDependencies;
  final Module module;

  /// Pre-built widget — use for shell/stateful-shell routes where the child
  /// is a live Navigator provided by GoRouter and must not be cached.
  final Widget? child;

  /// Lazy builder — use for module routes whose child closure may call
  /// `Modular.get<FactoryBind>()`. Built exactly once (on the first `build`
  /// call) and cached for all subsequent rebuilds, so hot-reload and
  /// GoRouter's internal rebuilds never create extra factory instances.
  final WidgetBuilder? childBuilder;

  const ParentWidgetObserver({
    super.key,
    required this.onDispose,
    required this.didChangeDependencies,
    required this.module,
    this.child,
    this.childBuilder,
  }) : assert(child != null || childBuilder != null,
            'Provide either child or childBuilder');

  @override
  State<ParentWidgetObserver> createState() => _ParentWidgetObserverState();
}

class _ParentWidgetObserverState extends State<ParentWidgetObserver> {
  Widget? _cachedChild;

  @override
  void dispose() {
    widget.onDispose(widget.module);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    widget.didChangeDependencies(widget.module);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.child != null) return widget.child!;
    return _cachedChild ??= widget.childBuilder!(context);
  }
}
