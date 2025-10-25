import 'package:go_router_modular/go_router_modular.dart';

class ModuleSingleton extends Module {
  @override
  void binds(Injector i) {
    // Registrar a implementação concreta
    i.addLazySingleton<BindSingleton>(() => BindSingleton());

    // Registrar a interface apontando para a mesma instância
    // Seguindo o padrão do auto_injector: usar get() para obter a instância já registrada
    i.addLazySingleton<IBindSingleton>(() => i.get<BindSingleton>());
  }
}

abstract interface class IBindSingleton {
  void printHash();
}

class BindSingleton implements IBindSingleton {
  @override
  void printHash() {
    print('BindSingleton hashcode: ${this.hashCode}');
  }
}
