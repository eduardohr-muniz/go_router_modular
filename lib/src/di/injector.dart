import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/core/bind.dart';
import 'package:go_router_modular/src/core/injection_manager.dart';

class Injector {
  T get<T>({String? key}) {
    try {
      // Use auto_injector para obter instância
      final instance = InjectionManager.instance.injector.get<T>(key: key);
      return instance;
    } catch (e) {
      // Fallback para o sistema antigo se necessário
      return Bind.get<T>(key: key);
    }
  }
}
