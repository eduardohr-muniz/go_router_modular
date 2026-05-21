import 'package:flutter/widgets.dart';

/// Wraps a [WidgetBuilder] and calls it exactly once per widget lifecycle.
///
/// The built child is cached in state and returned on every subsequent
/// [build] call, so GoRouter's internal rebuilds (hot-reload, InheritedWidget
/// changes, route configuration updates) never re-invoke the builder.
///
/// This is critical for route closures that call [Modular.get] with factory
/// binds: without caching, each rebuild would create a fresh instance and
/// silently discard the previous cubit / state.
class OnceBuilder extends StatefulWidget {
  const OnceBuilder({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  State<OnceBuilder> createState() => _OnceBuilderState();
}

class _OnceBuilderState extends State<OnceBuilder> {
  Widget? _cache;

  @override
  Widget build(BuildContext context) => _cache ??= widget.builder(context);
}
