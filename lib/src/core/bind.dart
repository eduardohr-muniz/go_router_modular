import 'dart:developer';
import 'package:get_it/get_it.dart';
import 'package:go_router_modular/src/di/clean_bind.dart';
import 'package:go_router_modular/src/exceptions/exception.dart';
import 'package:go_router_modular/src/di/injector.dart';
import 'package:go_router_modular/src/core/injection_manager.dart';

/// Simplified Bind class that delegates to GetIt
///
/// ## Interface Registration (Padrão GetIt)
///
/// O GetIt NÃO faz auto-resolution de interfaces automaticamente.
/// Para registrar uma interface, você deve registrar explicitamente:
///
/// ```dart
/// class MyModule extends Module {
///   @override
///   void binds(Injector i) {
///     // 1. Registrar a implementação concreta
///     i.addLazySingleton<MyServiceImpl>(() => MyServiceImpl());
///
///     // 2. Registrar a interface apontando para a mesma instância
///     i.addLazySingleton<IMyService>(() => i.get<MyServiceImpl>());
///   }
/// }
/// ```
///
/// Agora você pode usar tanto `Modular.get<IMyService>()` quanto `Modular.get<MyServiceImpl>()`.
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

  // Registro de interfaces para auto-resolution
  static final Map<Type, Type> _interfaceImplementations = {};

  /// Register a bind using GetIt
  static void register<T extends Object>(Bind<T> bind) {
    try {
      final getIt = InjectionManager.instance.injector;
      final key = bind.key;

      // Verificar se já existe um bind para este tipo/key
      if (getIt.isRegistered<T>(instanceName: key)) {
        return; // Já existe, não registrar novamente
      }

      // Registrar o bind no GetIt
      if (bind.isSingleton) {
        if (bind.isLazy) {
          getIt.registerLazySingleton<T>(
            () => bind.factoryFunction(Injector()),
            instanceName: key,
            dispose: (instance) {
              // Chamar CleanBind para fazer cleanup
              CleanBind.fromInstance(instance);
            },
          );
        } else {
          // GetIt não tem "eager singleton" com factory
          // Vamos criar a instância imediatamente e registrar
          final instance = bind.factoryFunction(Injector());
          getIt.registerSingleton<T>(
            instance,
            instanceName: key,
            dispose: (instance) {
              CleanBind.fromInstance(instance);
            },
          );
        }
      } else {
        // Factory
        getIt.registerFactory<T>(
          () => bind.factoryFunction(Injector()),
          instanceName: key,
        );
      }
    } catch (e) {
      log('❌ Failed to register bind for type ${T.toString()} - $e', name: "GO_ROUTER_MODULAR");
      throw GoRouterModularException('❌ Bind registration failed for type ${T.toString()}: $e');
    }
  }

  /// Get instance using GetIt with module context
  static T get<T extends Object>({String? key}) {
    try {
      return InjectionManager.instance.getWithModuleContext<T>(key: key);
    } catch (e) {
      // Tentar resolver pela implementação conhecida se T for uma interface
      if (_interfaceImplementations.containsKey(T)) {
        try {
          final result = InjectionManager.instance.getWithModuleContext(key: key);
          if (result is T) {
            return result;
          }
        } catch (_) {
          // Ignorar e lançar o erro original
        }
      }

      log('❌ Bind not found for type: ${T.toString()}${key != null ? ' with key: $key' : ''}', name: "GO_ROUTER_MODULAR");
      throw GoRouterModularException('❌ Bind not found for type ${T.toString()}${key != null ? ' with key: $key' : ''}');
    }
  }

  /// Dispose singleton by type using GetIt
  ///
  /// LIMITAÇÃO DO GETIT: Após dispose, o bind é completamente removido
  /// e não pode ser recriado automaticamente (diferente do auto_injector)
  static void dispose<T extends Object>() {
    if (T == Object) return;

    try {
      final getIt = InjectionManager.instance.injector;

      // Verificar se está registrado antes de tentar unregister
      if (!getIt.isRegistered<T>()) {
        return; // Não está registrado, nada a fazer
      }

      // GetIt.unregister chama o dispose callback automaticamente
      getIt.unregister<T>();
    } catch (e) {
      // Ignorar erros de dispose - pode não existir
      log('⚠️ Failed to dispose bind: ${T.toString()} - $e', name: "GO_ROUTER_MODULAR");
    }
  }

  /// Dispose singleton by key using GetIt
  /// IMPORTANTE: GetIt NÃO suporta unregister apenas por instanceName sem tipo
  /// Esta é uma limitação do GetIt comparada ao auto_injector
  static void disposeByKey(String key) {
    // GetIt requer o tipo para unregister, não é possível fazer apenas com key
    // Esta funcionalidade não é suportada pelo GetIt
    log('⚠️ disposeByKey não é suportado pelo GetIt (requer tipo)', name: "GO_ROUTER_MODULAR");
  }

  /// Clear all binds - not recommended in production
  static Future<void> clearAll() async {
    try {
      _interfaceImplementations.clear();

      // Usar o método de limpeza do InjectionManager
      await InjectionManager.instance.clearAllForTesting();
      log('🧹 Cleared all binds using InjectionManager', name: "GO_ROUTER_MODULAR");
    } catch (e) {
      log('⚠️ clearAll() failed: $e', name: "GO_ROUTER_MODULAR");
    }
  }

  /// Get all available keys - not directly supported by GetIt
  static List<String> getAllKeys() {
    // GetIt não expõe a lista de keys registradas
    log('⚠️ getAllKeys() não é suportado pelo GetIt', name: "GO_ROUTER_MODULAR");
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

  /// Register interface mapping
  static void registerAs<TInterface extends Object, TImplementation extends TInterface>(Bind<TImplementation> bind) {
    _interfaceImplementations[TInterface] = TImplementation;
    register<TImplementation>(bind);
  }
}
