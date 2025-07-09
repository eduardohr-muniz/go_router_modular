import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'shared_service.dart';

class SharedModule extends Module {
  @override
  List<Bind<Object>> get binds {
    print('📦 [SHARED_MODULE] Obtendo binds');
    return [
      Bind.singleton<SharedService>((i) => SharedService()),
    ];
  }

  @override
  void initState(Injector i) {
    print('🚀 [SHARED_MODULE] initState chamado');
    super.initState(i);
    print('✅ [SHARED_MODULE] SharedModule inicializado com sucesso');
  }

  @override
  void dispose() {
    print('🗑️ [SHARED_MODULE] dispose chamado');
    super.dispose();
    print('✅ [SHARED_MODULE] SharedModule disposto com sucesso');
  }
}
