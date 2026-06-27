import 'dart:async';

/// Serviço de completers de navegação usado pelas variantes assíncronas de
/// navegação (`goAsync`, `pushAsync`, …) e pelo registro de binds em rotas de
/// módulo, para aguardar a conclusão de uma navegação.
///
/// Extraído de `go_router_modular_configure.dart` para isolar a
/// responsabilidade de gerenciamento de completers (Single Responsibility).
class RouteWithCompleterService {
  const RouteWithCompleterService._();

  /// Map to store route completers.
  static final List<Completer> _stackCompleters = [];

  /// Completes the navigation for a specific route.
  ///
  /// - [route]: The route path to complete.
  static void setCompleteRoute(String route) {
    _stackCompleters.add(Completer<void>());
  }

  static Completer getLastCompleteRoute() {
    final completer = _stackCompleters.isNotEmpty ? _stackCompleters.removeLast() : Completer<void>();
    return completer;
  }

  /// Checks if any route completer exists.
  static bool hasRouteCompleter() {
    return _stackCompleters.isNotEmpty;
  }

  static Future<void> awaitCompleteRoute() async {
    if (_stackCompleters.isEmpty) return;
    await _stackCompleters.first.future;
  }
}
