class DebugModular {
  static DebugModular? _instance;
  DebugModular._();
  static DebugModular get instance => _instance ??= DebugModular._();

  DebugModel _debug = DebugModel(
    debugLogEventBus: false,
    debugLogGoRouter: false,
    debugLogGoRouterModular: false,
  );
  bool get debugLogEventBus => _debug.debugLogEventBus;
  bool get debugLogGoRouter => _debug.debugLogGoRouter;
  bool get debugLogGoRouterModular => _debug.debugLogGoRouterModular;

  void setDebugModel(DebugModel value) {
    _debug = value;
  }
}

class DebugModel {
  final bool debugLogEventBus;
  final bool debugLogGoRouter;
  final bool debugLogGoRouterModular;

  DebugModel({
    required this.debugLogEventBus,
    required this.debugLogGoRouter,
    required this.debugLogGoRouterModular,
  });

  DebugModel copyWith({
    bool? debugLogEventBus,
    bool? debugLogGoRouter,
    bool? debugLogGoRouterModular,
  }) {
    return DebugModel(
      debugLogEventBus: debugLogEventBus ?? this.debugLogEventBus,
      debugLogGoRouter: debugLogGoRouter ?? this.debugLogGoRouter,
      debugLogGoRouterModular: debugLogGoRouterModular ?? this.debugLogGoRouterModular,
    );
  }
}
