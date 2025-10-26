import 'package:go_router_modular/src/core/injection_manager/_bind_registration.dart';
import 'package:go_router_modular/src/core/injection_manager/_module_registry.dart';

/// Formatador de logs para binds
class BindLogFormatter {
  static String formatBinds(List<BindRegistration> binds, Type moduleType, ModuleRegistry registry, bool isDisposing) {
    if (binds.isEmpty) return '';

    return binds.map((b) => " ${isDisposing ? "💥" : "♻️"} ${_formatBind(b, moduleType, registry)}").join("\n");
  }

  static String _formatBind(BindRegistration bind, Type moduleType, ModuleRegistry registry) {
    final typeName = bind.type.toString().split('.').last;

    // Se não tem instanceName, retorna só o nome da classe
    if (bind.instanceName == null) return typeName;

    // Se é a key padrão (ModuleName_TypeName), retorna só o nome da classe
    final defaultKey = registry.getPrefix(moduleType) + bind.type.toString();
    if (bind.instanceName == defaultKey) return typeName;

    // Remove o prefixo do módulo se estiver presente na key
    final prefix = registry.getPrefix(moduleType);
    final key = bind.instanceName!.startsWith(prefix) ? bind.instanceName!.substring(prefix.length) : bind.instanceName!;

    return "$typeName(key: '$key')";
  }
}
