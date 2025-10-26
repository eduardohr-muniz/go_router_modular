import 'package:go_router_modular/go_router_modular.dart';
import 'shared_service.dart';
import 'module_singleton.dart';

class SharedModule extends Module {
  @override
  FutureModules imports() {
    return [ModuleSingleton()];
  }

  @override
  FutureBinds binds(Injector i) {
    i.add(() => SharedService());
  }
}
