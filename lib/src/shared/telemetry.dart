/// Telemetry of the modular runtime: one event per change in a module's bind
/// lifecycle and per message on the event bus, so the host app can forward them
/// to Sentry, Crashlytics, a logger, or anything else.
///
/// It is observability only: nothing here changes routing, disposal or event
/// delivery, and the listener runs in release builds as well — it is not gated
/// on `debugLogDiagnostics`, which drives the package's own `log` output.
///
/// What reaches the listener is chosen by a [ModularTelemetryFilter] passed to
/// `Modular.configure`. The filter is applied **before** the event is built, so
/// what you filter out costs nothing.
library;

/// What happened.
///
/// The first five are module lifecycle ([ModularModuleTelemetryEvent]); the
/// last two are the event bus ([ModularBusTelemetryEvent]).
enum ModularTelemetryKind {
  /// Binds registered: the module got its first active reference (0 → 1).
  injected,

  /// Binds disposed: the module's last reference was released (1 → 0).
  disposed,

  /// One more active reference to a module that was already injected.
  referenceOpened,

  /// A page took ownership of the navigation reference its route's `redirect`
  /// had opened. The count does not change — the reference only changes owner
  /// from "pending navigation" to "mounted page".
  referenceClaimed,

  /// A reference was released while other references remain, so the binds stay
  /// alive.
  referenceReleased,

  /// An event was published through `ModularEvent.fire`.
  eventFired,

  /// A listener registered with `ModularEvent.instance.on` received an event.
  eventReceived;

  /// Whether this kind describes a module's bind lifecycle.
  bool get isModule => !isEvent;

  /// Whether this kind describes traffic on the event bus.
  bool get isEvent => this == eventFired || this == eventReceived;

  /// The module lifecycle kinds.
  static const Set<ModularTelemetryKind> moduleKinds = <ModularTelemetryKind>{
    injected,
    disposed,
    referenceOpened,
    referenceClaimed,
    referenceReleased,
  };

  /// The event bus kinds.
  static const Set<ModularTelemetryKind> eventKinds = <ModularTelemetryKind>{eventFired, eventReceived};

  /// Just the two kinds that actually register and dispose binds.
  static const Set<ModularTelemetryKind> injectionKinds = <ModularTelemetryKind>{injected, disposed};
}

/// What caused the change reported by a [ModularModuleTelemetryEvent].
enum ModularTelemetryTrigger {
  /// `Modular.configure` registered the AppModule. It happens once, before any
  /// navigation, and its reference is never released.
  bootstrap,

  /// A navigation went through the module's route and its `redirect` registered
  /// the binds. The reference is pending until a page claims it.
  navigation,

  /// The module's page entered the navigation stack (`initState`).
  pageMounted,

  /// The module's page left the navigation stack (`dispose`).
  pageDisposed,

  /// A navigation reference no page ever claimed expired at the end of the
  /// frame that built the pages — a sibling route, a restore after a pop, or a
  /// guard that redirected away.
  unclaimedNavigationExpired,
}

/// One observation of the modular runtime.
///
/// Switch on it to tell the two families apart:
///
/// ```dart
/// switch (event) {
///   case ModularModuleTelemetryEvent m:
///     Sentry.addBreadcrumb(Breadcrumb(category: 'module', data: m.toMap()));
///   case ModularBusTelemetryEvent e:
///     Sentry.addBreadcrumb(Breadcrumb(category: 'event', data: e.toMap()));
/// }
/// ```
sealed class ModularTelemetryEvent {
  ModularTelemetryEvent({required this.kind, DateTime? timestamp}) : timestamp = timestamp ?? DateTime.now();

  /// What happened.
  final ModularTelemetryKind kind;

  /// When the event was emitted, by the device clock.
  final DateTime timestamp;

  /// Flat representation for a breadcrumb's `data` / an event's `extra`.
  Map<String, Object?> toMap();
}

/// A change in the lifecycle of a module's binds.
///
/// Forward it as a breadcrumb (see [toMap]) to spot, for example, a dispose
/// burst arriving long after the navigation that caused it — which is what
/// happens on the web when a hidden tab stops receiving frames and then catches
/// up all at once.
final class ModularModuleTelemetryEvent extends ModularTelemetryEvent {
  ModularModuleTelemetryEvent({
    required super.kind,
    required this.trigger,
    required this.module,
    required this.instanceId,
    required this.referenceCount,
    this.binds = const <String>[],
    super.timestamp,
  });

  /// What caused it.
  final ModularTelemetryTrigger trigger;

  /// `runtimeType` of the module, for example `HomeModule`.
  final String module;

  /// Identity of the module instance (`identityHashCode`), stable while the
  /// instance lives.
  ///
  /// References are counted per **instance**, not per type: two instances of
  /// the same module share [module] but never [instanceId]. Reading it is what
  /// tells a re-entered instance (`A → B → A` over the same object, whose count
  /// goes 1 → 2) apart from a freshly built one (a second object, starting its
  /// own count at 1) — without it both look like the same `refs` sequence.
  final int instanceId;

  /// The module's active reference count **after** the event. Reaching 0 means
  /// the binds were disposed.
  final int referenceCount;

  /// Binds registered ([ModularTelemetryKind.injected]) or disposed
  /// ([ModularTelemetryKind.disposed]) by this event.
  ///
  /// Always empty for the reference kinds, which do not touch binds, and also
  /// when the filter has `includeBinds: false` — in which case they are never
  /// even named.
  final List<String> binds;

  @override
  Map<String, Object?> toMap() => <String, Object?>{
        'kind': kind.name,
        'trigger': trigger.name,
        'module': module,
        'instanceId': instanceId,
        'referenceCount': referenceCount,
        if (binds.isNotEmpty) 'binds': binds,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  String toString() => 'ModularModuleTelemetryEvent(${kind.name} $module#$instanceId '
      'refs: $referenceCount, trigger: ${trigger.name}'
      '${binds.isEmpty ? '' : ', binds: ${binds.join(', ')}'})';
}

/// A message on the modular event bus — published by `ModularEvent.fire`
/// ([ModularTelemetryKind.eventFired]) or delivered to a listener registered
/// with `ModularEvent.instance.on` ([ModularTelemetryKind.eventReceived]).
///
/// One `fire` produces one `eventFired` plus one `eventReceived` per listening
/// subscription, which is what shows an event published with nobody listening,
/// or delivered twice.
final class ModularBusTelemetryEvent extends ModularTelemetryEvent {
  ModularBusTelemetryEvent({
    required super.kind,
    required this.event,
    required this.busId,
    super.timestamp,
  });

  /// `runtimeType` of the payload, for example `UserLoggedIn`.
  ///
  /// The payload itself is deliberately not carried: it routinely holds
  /// personal data, and telemetry usually leaves the device.
  final String event;

  /// Identity of the `EventBus` the message went through. The default bus and
  /// each custom one have their own id, which is what tells apart an event
  /// fired on a bus nobody listens to.
  final int busId;

  @override
  Map<String, Object?> toMap() => <String, Object?>{
        'kind': kind.name,
        'event': event,
        'busId': busId,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  String toString() => 'ModularBusTelemetryEvent(${kind.name} $event, bus: $busId)';
}

/// Signature of the `onTelemetry` callback of `Modular.configure`.
typedef ModularTelemetryCallback = void Function(ModularTelemetryEvent event);

/// Chooses what reaches the `onTelemetry` callback.
///
/// Everything here is applied **before** the event is built, so filtering is
/// also how you keep telemetry cheap. Watching only module injection and
/// disposal, without naming the binds:
///
/// ```dart
/// Modular.configure(
///   appModule: AppModule(),
///   onTelemetry: (e) => Sentry.addBreadcrumb(Breadcrumb(data: e.toMap())),
///   telemetryFilter: const ModularTelemetryFilter.injections(),
/// );
/// ```
///
/// Or only what a feature does, binds included:
///
/// ```dart
/// telemetryFilter: ModularTelemetryFilter(
///   module: (name) => name.startsWith('Checkout'),
/// ),
/// ```
class ModularTelemetryFilter {
  /// Reports everything: both families, binds included.
  const ModularTelemetryFilter({
    this.kinds,
    this.includeBinds = true,
    this.module,
    this.event,
  });

  /// Only module injection and disposal, without naming the binds.
  ///
  /// The cheapest useful setting, and the one to reach for to watch modules
  /// coming and going without caring what is inside them.
  const ModularTelemetryFilter.injections({this.module})
      : kinds = ModularTelemetryKind.injectionKinds,
        includeBinds = false,
        event = null;

  /// The whole module lifecycle, references included.
  const ModularTelemetryFilter.modules({
    this.includeBinds = true,
    this.module,
  })  : kinds = ModularTelemetryKind.moduleKinds,
        event = null;

  /// Only traffic on the event bus.
  const ModularTelemetryFilter.events({this.event})
      : kinds = ModularTelemetryKind.eventKinds,
        includeBinds = false,
        module = null;

  /// Kinds that reach the callback. `null` means every kind.
  final Set<ModularTelemetryKind>? kinds;

  /// Whether [ModularModuleTelemetryEvent.binds] is filled.
  ///
  /// `false` skips walking the module's bind identifiers and naming each one,
  /// which is the only part of building an event that is not O(1).
  final bool includeBinds;

  /// Keeps only the modules whose `runtimeType` name this accepts. `null`
  /// keeps every module.
  final bool Function(String module)? module;

  /// Keeps only the payloads whose `runtimeType` name this accepts. `null`
  /// keeps every event.
  final bool Function(String event)? event;

  /// Whether a module event of [kind] for [moduleName] should be reported.
  bool allowsModule(ModularTelemetryKind kind, String moduleName) {
    if (kinds != null && !kinds!.contains(kind)) return false;
    return module?.call(moduleName) ?? true;
  }

  /// Whether a bus event of [kind] carrying [eventName] should be reported.
  bool allowsEvent(ModularTelemetryKind kind, String eventName) {
    if (kinds != null && !kinds!.contains(kind)) return false;
    return event?.call(eventName) ?? true;
  }

  /// Whether any kind in [candidates] can get through, so a caller can skip
  /// work before it even knows the module or event name.
  bool allowsAnyOf(Set<ModularTelemetryKind> candidates) => kinds == null || kinds!.any(candidates.contains);
}

/// Holds the `onTelemetry` listener plus its filter, and delivers events.
///
/// Internal to the package: apps register their listener through
/// `Modular.configure(onTelemetry: ..., telemetryFilter: ...)`, which is why
/// this class is not exported by
/// `package:go_router_modular/go_router_modular.dart`.
///
/// Delivery is synchronous and failure-proof: an exception thrown by the
/// listener is swallowed, because telemetry must never break a navigation or
/// an event.
class ModularTelemetry {
  ModularTelemetry._();

  static ModularTelemetryCallback? _listener;
  static ModularTelemetryFilter _filter = const ModularTelemetryFilter();

  /// Whether a listener was registered — checked before assembling an event so
  /// that apps without telemetry pay nothing.
  static bool get hasListener => _listener != null;

  /// The active filter.
  static ModularTelemetryFilter get filter => _filter;

  /// Registers the listener and its filter. Called by `Modular.configure`.
  static void setListener(ModularTelemetryCallback? listener, {ModularTelemetryFilter? filter}) {
    _listener = listener;
    _filter = filter ?? const ModularTelemetryFilter();
  }

  /// Drops the listener and restores the default filter.
  static void reset() {
    _listener = null;
    _filter = const ModularTelemetryFilter();
  }

  /// Whether a module event of [kind] for [module] would be delivered.
  ///
  /// Call it before doing any work to build one.
  static bool wantsModule(ModularTelemetryKind kind, String module) => _listener != null && _filter.allowsModule(kind, module);

  /// Whether a bus event of [kind] carrying [event] would be delivered.
  static bool wantsEvent(ModularTelemetryKind kind, String event) => _listener != null && _filter.allowsEvent(kind, event);

  /// Whether any bus event at all would be delivered, so `fire`/`on` can skip
  /// even naming the payload's type.
  static bool get wantsAnyEvent => _listener != null && _filter.allowsAnyOf(ModularTelemetryKind.eventKinds);

  /// Delivers [event] to the listener, if there is one.
  static void emit(ModularTelemetryEvent event) {
    final listener = _listener;
    if (listener == null) return;
    try {
      listener(event);
    } catch (_) {
      // A failing listener must never interrupt registration, disposal or an
      // event delivery.
    }
  }
}
