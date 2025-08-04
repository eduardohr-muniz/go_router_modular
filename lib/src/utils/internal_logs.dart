import 'dart:developer';

/// Constante para controlar se os logs internos do go_router_modular devem ser exibidos
const bool kInternalLogs = false;

/// Função para exibir logs internos do go_router_modular
/// Só exibe se [kInternalLogs] for true
void iLog(String message, {String name = "INTERNAL_LOG"}) {
  if (kInternalLogs) {
    log(message, name: name);
  }
}
