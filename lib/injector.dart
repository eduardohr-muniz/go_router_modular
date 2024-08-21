import 'package:go_router_modular/go_router_modular.dart';

class Injector {
  T get<T>() => Bind.get<T>();
}
