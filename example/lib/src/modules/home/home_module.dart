import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import '../shared/shared_module.dart';
import 'pages/home_page.dart';
import 'pages/demo_page.dart';

class HomeModule extends Module {
  // Controle de estado do módulo
  final bool _isInitialized = false;
  Timer? _homeTimer;
  StreamSubscription? _homeSubscription;

  @override
  List<Module> get imports {
    return [SharedModule()];
  }

  @override
  List<Bind<Object>> get binds {
    return [
      Bind.singleton<HomeService>((i) => HomeService()),
    ];
  }

  @override
  List<ModularRoute> get routes {
    return [
      ChildRoute(
        '/',
        child: (context, state) => const HomePage(),
      ),
      ChildRoute(
        '/demo',
        child: (context, state) => const DemoPage(),
      ),
    ];
  }

  @override
  void initState(Injector i) {
    print('init home module');
  }

  @override
  void dispose() {
    print('dispose home module');
  }
}

class HomeService {
  HomeService();

  void dispose() {}
}
