import 'package:flutter/material.dart';

class ParentWidgetObserver extends StatefulWidget {
  final void Function() onDispose;
  final Widget child;
  const ParentWidgetObserver({super.key, required this.onDispose, required this.child});

  @override
  State<ParentWidgetObserver> createState() => _ParentWidgetObserverState();
}

class _ParentWidgetObserverState extends State<ParentWidgetObserver> {
  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
