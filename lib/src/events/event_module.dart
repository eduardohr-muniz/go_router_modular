import 'package:event_bus/event_bus.dart';
import 'package:go_router_modular/src/module/module.dart';
import 'package:go_router_modular/src/di/injector.dart';
import 'package:go_router_modular/src/events/modular_event.dart';
import 'package:go_router_modular/src/events/modular_event_listener.dart';

/// Abstract module that adds event support via [EventListenerMixin].
///
/// Override [listen] to register handlers with [on].
/// Override [eventImports] to add [ModularEventListener] instances.
abstract class EventModule extends Module with EventListenerMixin {
  EventModule({EventBus? eventBus}) {
    internalEventBus = eventBus ?? defaultModularEventBus;
  }

  /// Listeners to register when the module initializes.
  List<ModularEventListener> eventImports() => [];

  @override
  void initState(InjectorReader i) {
    for (final listener in eventImports()) {
      listener.listen();
    }
    super.initState(i);
  }
}
