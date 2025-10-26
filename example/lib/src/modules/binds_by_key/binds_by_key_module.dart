import 'dart:async';

import 'package:example/src/modules/shared/module_singleton.dart';
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
  void binds(Injector i) {
    // Registrar BindSingleton com interface
    i.addLazySingleton<IBindSingleton>(() => BindSingleton());

    // Registrar Dio com keys
    i.addLazySingleton(() => DioFake(baseUrl: 'http://localhost:8080'), key: 'dio_local');
    i.addLazySingleton(() => DioFake(baseUrl: 'http://api.remote.com'), key: 'dio_remote');

    // ApiFake depende de DioFake com key 'dio_remote'
    i.add(() => ApiFake(dio: i.get<DioFake>(key: 'dio_remote')));
  }

  @override
  List<ModularRoute> get routes {
    return [
      // 🔑 Bind by Key Page - Transição específica rotate com fade
      ChildRoute(
        '/',
        child: (context, state) => const BindByKeyPage(),
        transition: GoTransitions.rotate.withFade,
        duration: Duration(milliseconds: 700),
      ),
    ];
  }
}

class BindsByKeyImportTest extends Module {
  @override
  void binds(Injector i) {
    i.add(() => DioFake(baseUrl: 'https://google.com'), key: 'dio_google');
  }
}

abstract class IDioFake {
  String get baseUrl;
}

class DioFake implements IDioFake {
  @override
  final String baseUrl;
  DioFake({required this.baseUrl});
}

abstract class IApiFake {
  IDioFake get dio;
}

class ApiFake implements IApiFake {
  @override
  final IDioFake dio;
  ApiFake({required this.dio});
}
