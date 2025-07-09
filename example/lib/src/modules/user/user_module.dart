import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import '../shared/shared_module.dart';
import 'domain/repositories/user_repository.dart';
import 'presenters/user_page.dart';
import 'presenters/user_name_page.dart';

class UserModule extends Module {
  // Controle de estado do módulo
  bool _isInitialized = false;
  Timer? _userTimer;
  StreamSubscription? _userSubscription;

  @override
  List<Module> get imports {
    print('📦 [USER_MODULE] Obtendo imports');
    return [SharedModule()];
  }

  @override
  List<Bind<Object>> get binds {
    print('📦 [USER_MODULE] Obtendo binds');
    return [
      Bind.singleton<IUserRepository>((i) => UserRepository()),
    ];
  }

  @override
  List<ModularRoute> get routes {
    print('🛣️ [USER_MODULE] Obtendo rotas');
    return [
      ChildRoute(
        '/',
        child: (context, state) => const UserPage(),
      ),
      ChildRoute(
        '/user_name/:name',
        child: (context, state) {
          final name = state.pathParameters['name'] ?? 'Usuário';
          return UserNamePage(userName: name);
        },
      ),
    ];
  }

  @override
  void initState(Injector i) {
    print('🚀 [USER_MODULE] initState chamado');

    if (_isInitialized) {
      print('⚠️ [USER_MODULE] Módulo já inicializado');
      return;
    }

    try {
      // Obtém o UserRepository injetado
      final userRepository = i.get<IUserRepository>();
      print('👤 [USER_MODULE] UserRepository obtido: ${userRepository.runtimeType}');

      // Simula configuração de listeners de usuário
      _setupUserListeners();

      // Simula carregamento de dados de usuário
      _loadUserData();

      // Simula configuração de permissões
      _setupUserPermissions();

      _isInitialized = true;
      print('✅ [USER_MODULE] UserModule inicializado com sucesso');
    } catch (e) {
      print('❌ [USER_MODULE] Erro na inicialização: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    print('🗑️ [USER_MODULE] dispose chamado');

    if (!_isInitialized) {
      print('⚠️ [USER_MODULE] Módulo não estava inicializado');
      return;
    }

    try {
      // Cancela timer de usuário
      _userTimer?.cancel();
      _userTimer = null;
      print('⏰ [USER_MODULE] Timer de usuário cancelado');

      // Cancela subscription de usuário
      _userSubscription?.cancel();
      _userSubscription = null;
      print('📡 [USER_MODULE] Subscription de usuário cancelado');

      // Simula limpeza de dados de usuário
      _clearUserData();

      // Simula fechamento de conexões de usuário
      _closeUserConnections();

      _isInitialized = false;
      print('✅ [USER_MODULE] UserModule disposto com sucesso');
    } catch (e) {
      print('❌ [USER_MODULE] Erro na disposição: $e');
      rethrow;
    }
  }

  // Métodos de exemplo para demonstrar inicialização
  void _setupUserListeners() {
    print('🔧 [USER_MODULE] Configurando listeners de usuário');
    // Simula configuração de listeners
  }

  void _loadUserData() {
    print('📊 [USER_MODULE] Carregando dados de usuário');
    // Simula carregamento de dados
  }

  void _setupUserPermissions() {
    print('🔐 [USER_MODULE] Configurando permissões de usuário');
    // Simula configuração de permissões
  }

  // Métodos de exemplo para demonstrar limpeza
  void _clearUserData() {
    print('🧹 [USER_MODULE] Limpando dados de usuário');
    // Simula limpeza de dados
  }

  void _closeUserConnections() {
    print('🔌 [USER_MODULE] Fechando conexões de usuário');
    // Simula fechamento de conexões
  }
}

class UserService {
  UserService() {
    print('👤 UserService criado');
  }

  void dispose() {
    print('👤 UserService disposto');
  }
}
