import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import '../shared/shared_module.dart';
import 'auth_store.dart';
import 'pages/login_page.dart';
import 'pages/splash_page.dart';

class AuthModule extends Module {
  // Controle de estado do módulo
  bool _isInitialized = false;
  Timer? _authTimer;
  StreamSubscription? _authSubscription;

  @override
  List<Module> get imports {
    print('📦 [AUTH_MODULE] Obtendo imports');
    return [SharedModule()];
  }

  @override
  List<Bind<Object>> get binds {
    print('📦 [AUTH_MODULE] Obtendo binds');
    return [Bind.singleton<AuthStore>((i) => AuthStore())];
  }

  @override
  List<ModularRoute> get routes {
    print('🛣️ [AUTH_MODULE] Obtendo rotas');
    return [
      ChildRoute(
        '/',
        child: (context, state) => const SplashPage(),
      ),
      ChildRoute(
        '/login',
        child: (context, state) => const LoginPage(),
      ),
    ];
  }

  @override
  void initState(Injector i) {
    print('🚀 [AUTH_MODULE] initState chamado');

    if (_isInitialized) {
      print('⚠️ [AUTH_MODULE] Módulo já inicializado');
      return;
    }

    try {
      // Obtém o AuthStore injetado
      final authStore = i.get<AuthStore>();
      print('🔐 [AUTH_MODULE] AuthStore obtido: ${authStore.runtimeType}');

      // Simula configuração de listeners de autenticação
      _setupAuthListeners();

      // Simula carregamento de configurações
      _loadAuthConfig();

      // Simula verificação de token salvo
      _checkSavedToken();

      _isInitialized = true;
      print('✅ [AUTH_MODULE] AuthModule inicializado com sucesso');
    } catch (e) {
      print('❌ [AUTH_MODULE] Erro na inicialização: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    print('🗑️ [AUTH_MODULE] dispose chamado');

    if (!_isInitialized) {
      print('⚠️ [AUTH_MODULE] Módulo não estava inicializado');
      return;
    }

    try {
      // Cancela timer de autenticação
      _authTimer?.cancel();
      _authTimer = null;
      print('⏰ [AUTH_MODULE] Timer de autenticação cancelado');

      // Cancela subscription de autenticação
      _authSubscription?.cancel();
      _authSubscription = null;
      print('📡 [AUTH_MODULE] Subscription de autenticação cancelado');

      // Simula limpeza de dados temporários
      _clearTempAuthData();

      // Simula fechamento de conexões
      _closeAuthConnections();

      _isInitialized = false;
      print('✅ [AUTH_MODULE] AuthModule disposto com sucesso');
    } catch (e) {
      print('❌ [AUTH_MODULE] Erro na disposição: $e');
      rethrow;
    }
  }

  // Métodos de exemplo para demonstrar inicialização
  void _setupAuthListeners() {
    print('🔧 [AUTH_MODULE] Configurando listeners de autenticação');
    // Simula configuração de listeners
  }

  void _loadAuthConfig() {
    print('⚙️ [AUTH_MODULE] Carregando configurações de autenticação');
    // Simula carregamento de configurações
  }

  void _checkSavedToken() {
    print('🔍 [AUTH_MODULE] Verificando token salvo');
    // Simula verificação de token
  }

  // Métodos de exemplo para demonstrar limpeza
  void _clearTempAuthData() {
    print('🧹 [AUTH_MODULE] Limpando dados temporários de autenticação');
    // Simula limpeza de dados
  }

  void _closeAuthConnections() {
    print('🔌 [AUTH_MODULE] Fechando conexões de autenticação');
    // Simula fechamento de conexões
  }
}
