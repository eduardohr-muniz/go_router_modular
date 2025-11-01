import 'dart:async';

import 'package:example/src/modules/shared/module_singleton.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_transitions/go_transitions.dart';
import 'pages/bind_by_key_page.dart';

class BindsByKeyModule extends Module {
  @override
  FutureOr<List<Module>> imports() {
    return [
      BindsByKeyImportTest(),
    ];
  }

  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<BindSingleton>((i) => BindSingleton());
    i.addSingleton<DioFake>((i) => DioFake(baseUrl: 'http://localhost:8080'), key: 'dio_local');
    i.addFactory<DioFake>((i) => DioFake(baseUrl: 'http://api.remote.com'), key: 'dio_remote');
    i.addFactory<ApiFake>((i) => ApiFake(dio: i.get<IDioFake>(key: 'dio_remote')));
  }

  @override
  List<ModularRoute> get routes {
    return [
      ChildRoute(
        '/',
        child: (context, state) => const BindByKeyPage(),
        transition: GoTransitions.slide.toLeft.withFade, // Slide para esquerda com fade
        transitionDuration: Duration(milliseconds: 500), // Média - 500ms
      ),
    ];
  }
}

class BindsByKeyImportTest extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addFactory<DioFake>((i) => DioFake(baseUrl: 'https://google.com'), key: 'dio_google');
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
