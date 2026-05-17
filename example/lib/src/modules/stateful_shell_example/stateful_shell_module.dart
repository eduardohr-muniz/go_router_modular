// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:example/src/modules/shared/test_controller.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'pages/stateful_home_page.dart';
import 'pages/stateful_favorites_page.dart';
import 'pages/stateful_profile_page.dart';

// ==================== SHELL MODULE ====================

class StatefulShellExampleModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<StatefulShellService>(
      (i) => StatefulShellService(),
    );
  }

  @override
  List<ModularRoute> get routes => [
        StatefulShellModularRoute(
          builder: (context, state, navigationShell) => _StatefulShellScaffold(
            navigationShell: navigationShell,
          ),
          branches: [
            ModularBranch(
              routes: [
                ModuleRoute('/home', module: HomeBranchModule()),
              ],
            ),
            ModularBranch(
              routes: [
                ModuleRoute('/favorites', module: FavoritesBranchModule()),
              ],
            ),
            ModularBranch(
              routes: [
                ModuleRoute('/profile', module: ProfileBranchModule()),
              ],
            ),
          ],
        ),
      ];

  @override
  void initState(InjectorReader i) {
    TestController.instance.enterModule('StatefulShellExampleModule');
    print('🔄 StatefulShellExampleModule iniciado');
  }

  @override
  void dispose() {
    TestController.instance.exitModule('StatefulShellExampleModule');
    print('🔄 StatefulShellExampleModule disposed');
  }
}

// ==================== BRANCH MODULES ====================

class HomeBranchModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<HomeBranchService>((i) => HomeBranchService());
  }

  @override
  List<ModularRoute> get routes => [
        ChildRoute(
          '/',
          child: (context, state) => const StatefulHomePage(),
        ),
      ];

  @override
  void initState(InjectorReader i) {
    print('🏠 HomeBranchModule iniciado');
  }

  @override
  void dispose() {
    print('🏠 HomeBranchModule disposed');
  }
}

class FavoritesBranchModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<FavoritesBranchService>((i) => FavoritesBranchService());
  }

  @override
  List<ModularRoute> get routes => [
        ChildRoute(
          '/',
          child: (context, state) => const StatefulFavoritesPage(),
        ),
      ];

  @override
  void initState(InjectorReader i) {
    print('❤️ FavoritesBranchModule iniciado');
  }

  @override
  void dispose() {
    print('❤️ FavoritesBranchModule disposed');
  }
}

class ProfileBranchModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<ProfileBranchService>((i) => ProfileBranchService());
  }

  @override
  List<ModularRoute> get routes => [
        ChildRoute(
          '/',
          child: (context, state) => const StatefulProfilePage(),
        ),
      ];

  @override
  void initState(InjectorReader i) {
    print('👤 ProfileBranchModule iniciado');
  }

  @override
  void dispose() {
    print('👤 ProfileBranchModule disposed');
  }
}

// ==================== SERVICES ====================

class StatefulShellService {
  StatefulShellService() {
    print('🔄 StatefulShellService criado');
  }

  String get name => 'Stateful Shell Service';

  void dispose() {
    print('🔄 StatefulShellService disposed');
  }
}

class HomeBranchService {
  HomeBranchService() {
    print('🏠 HomeBranchService criado');
  }

  String get name => 'Home Branch Service';
}

class FavoritesBranchService {
  FavoritesBranchService() {
    print('❤️ FavoritesBranchService criado');
  }

  String get name => 'Favorites Branch Service';
}

class ProfileBranchService {
  ProfileBranchService() {
    print('👤 ProfileBranchService criado');
  }

  String get name => 'Profile Branch Service';
}

// ==================== SHELL SCAFFOLD ====================

class _StatefulShellScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _StatefulShellScaffold({
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stateful Shell'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
