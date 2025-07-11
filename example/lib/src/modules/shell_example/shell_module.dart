import 'dart:async';
import 'package:go_router_modular/go_router_modular.dart';
import '../shared/shared_module.dart';
import 'pages/shell_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/profile_page.dart';
import 'pages/settings_page.dart';

class ShellExampleModule extends Module {
  @override
  FutureOr<List<Module>> imports() {
    return [SharedModule()];
  }

  @override
  FutureOr<List<Bind<Object>>> binds() {
    return [
      Bind.singleton<ShellService>((i) => ShellService()),
    ];
  }

  @override
  List<ModularRoute> get routes {
    return [
      // Shell Route com navegação por tabs
      ShellModularRoute(
        builder: (context, state, child) => ShellPage(child: child),
        routes: [
          ChildRoute(
            '/dashboard',
            child: (context, state) => const DashboardPage(),
            name: 'dashboard',
          ),
          ChildRoute(
            '/profile',
            child: (context, state) => const ProfilePage(),
            name: 'profile',
          ),
          ChildRoute(
            '/settings',
            child: (context, state) => const SettingsPage(),
            name: 'settings',
          ),
        ],
      ),
    ];
  }

  @override
  void initState(Injector i) {
    // Inicialização do módulo shell
  }

  @override
  void dispose() {
    // Limpeza do módulo shell
  }
}

class ShellService {
  ShellService();

  void dispose() {}
}
