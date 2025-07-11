import 'package:flutter/material.dart';

class ShellPopWrapper extends StatefulWidget {
  final void Function() onExit;
  final Widget child;
  const ShellPopWrapper({super.key, required this.onExit, required this.child});

  @override
  State<ShellPopWrapper> createState() => _ShellPopWrapperState();
}

class _ShellPopWrapperState extends State<ShellPopWrapper> {
  @override
  void dispose() {
    widget.onExit();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
