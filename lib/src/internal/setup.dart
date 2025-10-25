class SetupModular {
  static SetupModular? _instance;
  SetupModular._();
  static SetupModular get instance => _instance ??= SetupModular._();

  SetupModel _debug = SetupModel(
    debugLogEventBus: false,
    debugLogGoRouter: false,
    debugLogGoRouterModular: false,
    autoDisposeEvents: true,
  );
  bool get debugLogEventBus => _debug.debugLogEventBus;
  bool get debugLogGoRouter => _debug.debugLogGoRouter;
  bool get debugLogGoRouterModular => _debug.debugLogGoRouterModular;
  bool get autoDisposeEvents => _debug.autoDisposeEvents;

  void setDebugModel(SetupModel value) {
    _debug = value;
  }
}

class SetupModel {
  final bool debugLogEventBus;
  final bool debugLogGoRouter;
  final bool debugLogGoRouterModular;
  final bool autoDisposeEvents;

  SetupModel({
    required this.debugLogEventBus,
    required this.debugLogGoRouter,
    required this.debugLogGoRouterModular,
    required this.autoDisposeEvents,
  });

  SetupModel copyWith({
    bool? debugLogEventBus,
    bool? debugLogGoRouter,
    bool? debugLogGoRouterModular,
    bool? autoDisposeEvents,
  }) {
    return SetupModel(
      debugLogEventBus: debugLogEventBus ?? this.debugLogEventBus,
      debugLogGoRouter: debugLogGoRouter ?? this.debugLogGoRouter,
      debugLogGoRouterModular: debugLogGoRouterModular ?? this.debugLogGoRouterModular,
      autoDisposeEvents: autoDisposeEvents ?? this.autoDisposeEvents,
    );
  }
}
