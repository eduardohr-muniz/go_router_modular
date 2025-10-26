import 'dart:developer';
import 'package:go_router_modular/src/di/clean_bind.dart';
import 'package:go_router_modular/src/exceptions/exception.dart';
import 'package:go_router_modular/src/di/injector.dart';
import 'package:go_router_modular/src/core/injection_manager/injection_manager.dart';

/// Simplified Bind class that delegates to AutoInjector
///
/// ## Interface Registration (Seguindo padrão flutter_modular)
///
/// Para registrar uma interface, você deve registrar a implementação explicitamente:
///
/// ```dart
/// class MyModule extends Module {
///   @override
///  FutureBinds binds(Injector i) {
///     // Registrar a implementação
///     i.addLazySingleton<ClientDio>(() => ClientDio());
///
///     // Registrar a interface apontando para a implementação
///     i.addLazySingleton<IClient>(() => i.get<ClientDio>());
///   }
/// }
/// ```
///
/// Agora você pode usar tanto `Modular.get<IClient>()` quanto `Modular.get<ClientDio>()`.
/// Ambas retornam a MESMA instância!
///
/// **Alternativa mais elegante** (se você só precisa da interface):
/// ```dart
/// i.addLazySingleton<IClient>(() => ClientDio());
/// ```
/// Agora apenas `IClient` estará disponível, não `ClientDio` diretamente.
class Bind<T extends Object> {
  final T Function(Injector i) factoryFunction;
  final bool isSingleton;
  final bool isLazy;
  final String? key;
  final StackTrace stackTrace;
  T? _cachedInstance;

  Bind(this.factoryFunction, {this.isSingleton = true, this.isLazy = false, this.key}) : stackTrace = StackTrace.current;

  T get instance {
    if (_cachedInstance == null || !isSingleton) {
      _cachedInstance = factoryFunction(Injector());
    }
    return _cachedInstance!;
  }

  /// Register a bind using AutoInjector
  static void register<T extends Object>(Bind<T> bind) {
    try {
      final autoInjector = InjectionManager.instance.injector;
      final key = bind.key;

      // Registrar o bind no AutoInjector
      if (bind.isSingleton) {
        if (bind.isLazy) {
          autoInjector.addLazySingleton<T>(
            () => bind.factoryFunction(Injector()),
            key: key,
          );
        } else {
          autoInjector.addSingleton<T>(
            () => bind.factoryFunction(Injector()),
            key: key,
          );
        }
      } else {
        // Factory
        autoInjector.add<T>(
          () => bind.factoryFunction(Injector()),
          key: key,
        );
      }

      // NÃO fazer commit aqui! O commit será feito no InjectionManager
      // após registrar todos os binds do módulo
    } catch (e) {
      log('❌ Failed to register bind for type ${T.toString()} - $e', name: "GO_ROUTER_MODULAR");
      throw GoRouterModularException('❌ Bind registration failed for type ${T.toString()}: $e');
    }
  }

  /// Get instance using AutoInjector with module context
  static T get<T extends Object>({String? key}) {
    try {
      return InjectionManager.instance.getWithModuleContext<T>(key: key);
    } catch (e) {
      log('❌ Bind not found for type: ${T.toString()}${key != null ? ' with key: $key' : ''}', name: "GO_ROUTER_MODULAR");

      // Re-throw o erro com a mensagem detalhada do BindResolver
      throw GoRouterModularException(e.toString());
    }
  }

  /// Dispose singleton by type using AutoInjector
  static void dispose<T extends Object>() {
    if (T == Object) return;

    try {
      final autoInjector = InjectionManager.instance.injector;
      final instance = autoInjector.disposeSingleton<T>();

      // Chamar CleanBind.fromInstance se a instância existir
      if (instance != null) {
        CleanBind.fromInstance(instance);
      }
    } catch (e) {
      // Ignorar erros de dispose - pode não existir
      log('⚠️ Failed to dispose bind: ${T.toString()} - $e', name: "GO_ROUTER_MODULAR");
    }
  }

  /// Dispose singleton by key using AutoInjector
  static void disposeByKey(String key) {
    try {
      final autoInjector = InjectionManager.instance.injector;
      final instance = autoInjector.disposeSingleton<Object>(key: key);

      // Chamar CleanBind.fromInstance se a instância existir
      if (instance != null) {
        CleanBind.fromInstance(instance);
      }
    } catch (e) {
      log('⚠️ Failed to dispose bind with key: $key - $e', name: "GO_ROUTER_MODULAR");
    }
  }

  /// Clear all binds - not recommended in production
  static Future<void> clearAll() async {
    try {
      // Usar o método de limpeza do InjectionManager
      await InjectionManager.instance.clearAllForTesting();
      log('🧹 Cleared all binds using InjectionManager', name: "GO_ROUTER_MODULAR");
    } catch (e) {
      log('⚠️ clearAll() failed: $e', name: "GO_ROUTER_MODULAR");
    }
  }

  /// Get all available keys - not supported by AutoInjector
  static List<String> getAllKeys() {
    log('⚠️ getAllKeys() não é suportado pelo AutoInjector', name: "GO_ROUTER_MODULAR");
    return [];
  }

  /// Factory methods for creating binds
  static Bind<T> singleton<T extends Object>(T Function(Injector i) builder, {String? key}) {
    return Bind<T>(builder, isSingleton: true, isLazy: true, key: key);
  }

  static Bind<T> factory<T extends Object>(T Function(Injector i) builder, {String? key}) {
    return Bind<T>(builder, isSingleton: false, isLazy: false, key: key);
  }

  static Bind<T> lazy<T extends Object>(T Function(Injector i) builder, {String? key}) {
    return Bind<T>(builder, isSingleton: true, isLazy: true, key: key);
  }
}
