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

      // Uncommit temporariamente para permitir adicionar novos binds
      // Isso é necessário porque o injector foi commitado via callback 'on'
      autoInjector.uncommit();

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

      // Re-commit após adicionar o bind
      autoInjector.commit();
    } catch (e) {
      throw GoRouterModularException('❌ Bind registration failed for type ${T.toString()}: $e');
    }
  }

  /// Get instance using AutoInjector - igual flutter_modular
  /// Busca no injector PRINCIPAL que tem todos os módulos como sub-injectors
  static T get<T extends Object>({String? key}) {
    try {
      // ✅ IGUAL FLUTTER_MODULAR: buscar no injector principal (tracker.dart linha 21)
      // O injector principal tem todos os módulos registrados como sub-injectors
      final mainInjector = InjectionManager.instance.injector;
      return mainInjector.get<T>(key: key);
    } catch (e) {
      // Re-throw o erro com a mensagem detalhada
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
      // Ignorar erros de dispose - pode não existir
    }
  }

  /// Clear all binds - not recommended in production
  static void clearAll() {
    try {
      // Usar o método de limpeza do InjectionManager
      InjectionManager.instance.clearAllForTesting();
    } catch (e) {
      // Ignorar erros de cleanup
    }
  }

  /// Get all available keys - not supported by AutoInjector
  static List<String> getAllKeys() {
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
