// ignore_for_file: avoid_print

import 'package:example/src/modules/shared/test_controller.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'pages/shell_page.dart';
import 'pages/profile_page.dart';
import 'pages/settings_page.dart';

class ShellModule extends Module {
  @override
  void binds(Injector i) {
    i.addLazySingleton(() => ShellService());
  }

  @override
  List<ModularRoute> get routes => [
        ShellModularRoute(
          builder: (context, state, child) => ShellPage(child: child),
          routes: [
            // 👤 Profile Module - Transição específica scale com fade
            ModuleRoute(
              '/profile',
              module: ProfileModule(),
              transition: GoTransitions.scale.withFade,
              duration: Duration(milliseconds: 400),
            ),

            // ⚙️ Settings Module - Transição específica slide de baixo
            ModuleRoute(
              '/settings',
              module: SettingsModule(),
              transition: GoTransitions.slide.toBottom.withFade,
              duration: Duration(milliseconds: 500),
            ),
          ],
        ),
      ];

  @override
  void initState(Injector i) {
    TestController.instance.enterModule('ShellModule');
    print('🐚 ShellModule iniciado');
  }

  @override
  void dispose() {
    TestController.instance.exitModule('ShellModule');
    print('🐚 ShellModule disposed');
  }
}

class ProfileModule extends Module {
  @override
  void binds(Injector i) {
    i.addLazySingleton<ProfileService>(() => ProfileService());
  }

  @override
  List<ModularRoute> get routes => [
        ChildRoute(
          '/',
          child: (context, state) => const ProfilePage(),
        ),
      ];

  @override
  void initState(Injector i) {
    TestController.instance.enterModule('ProfileModule');
    print('👤 ProfileModule iniciado');
  }

  @override
  void dispose() {
    TestController.instance.exitModule('ProfileModule');
    print('👤 ProfileModule disposed');
  }
}

class SettingsModule extends Module {
  @override
  void binds(Injector i) {
    i.addLazySingleton<SettingsService>(() => SettingsService());
  }

  @override
  List<ModularRoute> get routes => [
        ChildRoute(
          '/',
          child: (context, state) => const SettingsPage(),
        ),
      ];

  @override
  void initState(Injector i) {
    TestController.instance.enterModule('SettingsModule');
    print('⚙️ SettingsModule iniciado');
  }

  @override
  void dispose() {
    TestController.instance.exitModule('SettingsModule');
    print('⚙️ SettingsModule disposed');
  }
}

// Services para teste
class ShellService {
  ShellService() {
    print('🐚 ShellService criado');
  }

  String get name => 'Shell Service';

  void dispose() {
    print('🐚 ShellService disposed');
  }
}

class ProfileService {
  ProfileService() {
    print('👤 ProfileService criado');
  }

  String get name => 'Profile Service';

  void dispose() {
    print('👤 ProfileService disposed');
  }
}

class SettingsService {
  SettingsService() {
    print('⚙️ SettingsService criado');
  }

  String get name => 'Settings Service';

  void dispose() {
    print('⚙️ SettingsService disposed');
  }
}
