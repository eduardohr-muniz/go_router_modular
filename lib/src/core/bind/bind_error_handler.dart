import 'package:go_router_modular/src/core/bind/bind_storage.dart';
import 'package:go_router_modular/src/exceptions/exception.dart';

/// Responsável APENAS por tratar erros de busca
/// Responsabilidade única: Geração de mensagens de erro apropriadas
class BindErrorHandler {
  final BindStorage _storage = BindStorage.instance;

  /// Lança exceção apropriada quando bind não é encontrado
  Never throwNotFound(Type type, String? key, int attemptCount) {
    // Se uma key específica foi solicitada e não foi encontrada
    if (key != null) {
      throw GoRouterModularException(
        '❌ Bind not found for type "${type.toString()}" with key: $key'
      );
    }

    // Se não há binds pendentes e já tentamos algumas vezes, falha imediatamente
    if (_storage.pendingObjectBinds.isEmpty && attemptCount >= 2) {
      throw GoRouterModularException(
        '❌ Bind not found for type "${type.toString()}". '
        'No pending binds available after $attemptCount attempts.'
      );
    }

    throw GoRouterModularException(
      '❌ Bind not found for type "${type.toString()}"'
    );
  }
}

