import 'dart:async';

import 'package:example/src/modules/injector_error/domain/injector_error_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router_modular/go_router_modular.dart';

class InjectorErrorModule extends Module {
  @override
  Future<List<Bind<Object>>> binds() async {
    await Future.delayed(const Duration(seconds: 2));
    return [
      Bind.singleton<IInjectorErrorRepository>((i) => InjectorErrorRepository(i.get())),
      Bind.singleton<InjectorErrorRepository2>((i) => InjectorErrorRepository2(i.get())),
    ];
  }

  @override
  List<ModularRoute> get routes {
    return [
      ChildRoute(
        '/',
        child: (context, state) => const Center(
          child: Text('Injector Error'),
        ),
      ),
    ];
  }
}

class InjectorErrorService {}
