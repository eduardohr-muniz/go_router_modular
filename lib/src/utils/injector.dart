import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/bind.dart';

class Injector {
  T get<T>({String? key}) => Bind.get<T>(key: key);
}
