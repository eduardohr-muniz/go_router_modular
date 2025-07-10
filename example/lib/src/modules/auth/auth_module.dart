import 'dart:async';
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
    return [SharedModule()];
  }

  @override
  List<Bind<Object>> get binds {
    return [Bind.singleton<AuthStore>((i) => AuthStore())];
  }

  @override
  List<ModularRoute> get routes {
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
    if (_isInitialized) {
      return;
    }

    try {
      // Obtém o AuthStore injetado

      // Simula configuração de listeners de autenticação
      _setupAuthListeners();

      // Simula carregamento de configurações
      _loadAuthConfig();

      // Simula verificação de token salvo
      _checkSavedToken();

      _isInitialized = true;
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    if (!_isInitialized) {
      return;
    }

    try {
      // Cancela timer de autenticação
      _authTimer?.cancel();
      _authTimer = null;

      // Cancela subscription de autenticação
      _authSubscription?.cancel();
      _authSubscription = null;

      // Simula limpeza de dados temporários
      _clearTempAuthData();

      // Simula fechamento de conexões
      _closeAuthConnections();

      _isInitialized = false;
    } catch (e) {
      rethrow;
    }
  }

  // Métodos de exemplo para demonstrar inicialização
  void _setupAuthListeners() {
    // Simula configuração de listeners
  }

  void _loadAuthConfig() {
    // Simula carregamento de configurações
  }

  void _checkSavedToken() {
    // Simula verificação de token
  }

  // Métodos de exemplo para demonstrar limpeza
  void _clearTempAuthData() {
    // Simula limpeza de dados
  }

  void _closeAuthConnections() {
    // Simula fechamento de conexões
  }
}
