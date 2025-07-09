import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import '../shared/shared_module.dart';
import 'pages/home_page.dart';
import 'pages/demo_page.dart';

class HomeModule extends Module {
  // Controle de estado do módulo
  bool _isInitialized = false;
  Timer? _homeTimer;
  StreamSubscription? _homeSubscription;

  @override
  List<Module> get imports {
    print('📦 [HOME_MODULE] Obtendo imports');
    return [SharedModule()];
  }

  @override
  List<Bind<Object>> get binds {
    print('📦 [HOME_MODULE] Obtendo binds');
    return [
      Bind.singleton<HomeService>((i) => HomeService()),
    ];
  }

  @override
  List<ModularRoute> get routes {
    print('🛣️ [HOME_MODULE] Obtendo rotas');
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
    print('🚀 [HOME_MODULE] initState chamado');

    if (_isInitialized) {
      print('⚠️ [HOME_MODULE] Módulo já inicializado');
      return;
    }

    try {
      // Obtém o HomeService injetado
      final homeService = i.get<HomeService>();
      print('🏠 [HOME_MODULE] HomeService obtido: ${homeService.runtimeType}');

      // Simula configuração de listeners do home
      _setupHomeListeners();

      // Simula carregamento de dados iniciais
      _loadInitialData();

      // Simula configuração de analytics
      _setupAnalytics();

      _isInitialized = true;
      print('✅ [HOME_MODULE] HomeModule inicializado com sucesso');
    } catch (e) {
      print('❌ [HOME_MODULE] Erro na inicialização: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    print('🗑️ [HOME_MODULE] dispose chamado');

    if (!_isInitialized) {
      print('⚠️ [HOME_MODULE] Módulo não estava inicializado');
      return;
    }

    try {
      // Cancela timer do home
      _homeTimer?.cancel();
      _homeTimer = null;
      print('⏰ [HOME_MODULE] Timer do home cancelado');

      // Cancela subscription do home
      _homeSubscription?.cancel();
      _homeSubscription = null;
      print('📡 [HOME_MODULE] Subscription do home cancelado');

      // Simula limpeza de dados do home
      _clearHomeData();

      // Simula fechamento de conexões do home
      _closeHomeConnections();

      _isInitialized = false;
      print('✅ [HOME_MODULE] HomeModule disposto com sucesso');
    } catch (e) {
      print('❌ [HOME_MODULE] Erro na disposição: $e');
      rethrow;
    }
  }

  // Métodos de exemplo para demonstrar inicialização
  void _setupHomeListeners() {
    print('🔧 [HOME_MODULE] Configurando listeners do home');
    // Simula configuração de listeners
  }

  void _loadInitialData() {
    print('📊 [HOME_MODULE] Carregando dados iniciais do home');
    // Simula carregamento de dados
  }

  void _setupAnalytics() {
    print('📈 [HOME_MODULE] Configurando analytics do home');
    // Simula configuração de analytics
  }

  // Métodos de exemplo para demonstrar limpeza
  void _clearHomeData() {
    print('🧹 [HOME_MODULE] Limpando dados do home');
    // Simula limpeza de dados
  }

  void _closeHomeConnections() {
    print('🔌 [HOME_MODULE] Fechando conexões do home');
    // Simula fechamento de conexões
  }
}

class HomeService {
  HomeService() {
    print('🏠 [HOME_SERVICE] HomeService criado');
  }

  void dispose() {
    print('🏠 [HOME_SERVICE] HomeService disposto');
  }
}
