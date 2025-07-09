import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'shared_service.dart';

class SharedModule extends Module {
  // Controle de estado do módulo
  final bool _isInitialized = false;

  @override
  List<Bind<Object>> get binds {
    print('📦 [SHARED_MODULE] Obtendo binds');
    return [
      Bind.singleton<SharedService>((i) => SharedService()),
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

  // Métodos de exemplo para demonstrar inicialização
  void _setupSharedServices() {
    print('🔧 [SHARED_MODULE] Configurando serviços compartilhados');
    // Simula configuração de serviços
  }

  void _loadGlobalConfig() {
    print('⚙️ [SHARED_MODULE] Carregando configurações globais');
    // Simula carregamento de configurações
  }

  // Métodos de exemplo para demonstrar limpeza
  void _cleanupSharedServices() {
    print('🧹 [SHARED_MODULE] Limpando serviços compartilhados');
    // Simula limpeza de serviços
  }

  void _cleanupGlobalConfig() {
    print('🗑️ [SHARED_MODULE] Limpando configurações globais');
    // Simula limpeza de configurações
  }
}
