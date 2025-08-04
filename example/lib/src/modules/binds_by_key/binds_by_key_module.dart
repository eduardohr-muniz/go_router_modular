import 'dart:async';

import 'package:go_router_modular/go_router_modular.dart';
import 'pages/bind_by_key_page.dart';

class BindsByKeyModule extends Module {
  @override
  FutureOr<List<Module>> imports() {
    return [
      BindsByKeyImportTest(),
    ];
  }

  @override
  FutureOr<List<Bind<Object>>> binds() {
    return [
      Bind.singleton((i) => DioFake(baseUrl: 'http://localhost:8080'), key: 'dio_local'),
      Bind.singleton((i) => DioFake(baseUrl: 'http://api.remote.com'), key: 'dio_remote'),
      Bind.singleton((i) => DioFake(baseUrl: 'https://padrao.com')),
    ];
  }

  @override
  List<ModularRoute> get routes {
    return [
      ChildRoute(
        '/',
        child: (context, state) => const BindByKeyPage(),
      ),
    ];
  }
}

class BindsByKeyImportTest extends Module {
  @override
  FutureOr<List<Bind<Object>>> binds() {
    return [
      Bind.singleton((i) => DioFake(baseUrl: 'https://google.com'), key: 'dio_google'),
    ];
  }
}

class DioFake {
  final String baseUrl;
  DioFake({required this.baseUrl});
}
