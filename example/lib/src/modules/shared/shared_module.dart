import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'shared_service.dart';

class SharedModule extends Module {
  // Controle de estado do módulo
  bool _isInitialized = false;

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

    if (_isInitialized) {
      print('⚠️ [SHARED_MODULE] Módulo já inicializado');
      return;
    }

    try {
      // Obtém o SharedService injetado
      final sharedService = i.get<SharedService>();
      print('🔧 [SHARED_MODULE] SharedService obtido: ${sharedService.runtimeType}');

      // Simula configuração de serviços compartilhados
      _setupSharedServices();

      // Simula carregamento de configurações globais
      _loadGlobalConfig();

      _isInitialized = true;
      print('✅ [SHARED_MODULE] SharedModule inicializado com sucesso');
    } catch (e) {
      print('❌ [SHARED_MODULE] Erro na inicialização: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    print('🗑️ [SHARED_MODULE] dispose chamado');

    if (!_isInitialized) {
      print('⚠️ [SHARED_MODULE] Módulo não estava inicializado');
      return;
    }

    try {
      // Simula limpeza de serviços compartilhados
      _cleanupSharedServices();

      // Simula limpeza de configurações globais
      _cleanupGlobalConfig();

      _isInitialized = false;
      print('✅ [SHARED_MODULE] SharedModule disposto com sucesso');
    } catch (e) {
      print('❌ [SHARED_MODULE] Erro na disposição: $e');
      rethrow;
    }
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
