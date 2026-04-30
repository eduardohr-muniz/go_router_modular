import 'package:event_bus/event_bus.dart';
import 'package:go_router_modular/src/events/modular_event.dart';

/// Ponto de entrada para disparar eventos no bus global durante testes.
///
/// Encapsula [ModularEvent.fire] com um nome semântico para o contexto de
/// testes, evitando importar o barrel principal só para disparar eventos.
///
/// Uso:
/// ```dart
/// ModularEventBus.fire(PaymentProcessedEvent(MoneyAmount(100)));
/// await Future.delayed(Duration(milliseconds: 50));
/// ```
abstract final class ModularEventBus {
  /// Dispara [event] no EventBus global (ou no [eventBus] fornecido).
  static void fire<T>(T event, {EventBus? eventBus}) {
    ModularEvent.fire<T>(event, eventBus: eventBus);
  }
}
