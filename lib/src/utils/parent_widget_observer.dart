import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class ParentWidgetObserver extends StatefulWidget {
  final void Function(Module module) onDispose;
  final void Function(Module module) didChangeDependencies;

  final Widget child;
  final Module module;
  const ParentWidgetObserver({super.key, required this.onDispose, required this.child, required this.didChangeDependencies, required this.module});

  @override
  State<ParentWidgetObserver> createState() => _ParentWidgetObserverState();
}

class _ParentWidgetObserverState extends State<ParentWidgetObserver> {
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
    return widget.child;
  }
}
