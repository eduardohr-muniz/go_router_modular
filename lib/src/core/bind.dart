import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:go_router_modular/src/di/clean_bind.dart';
import 'package:go_router_modular/src/exceptions/exception.dart';
import 'package:go_router_modular/src/di/injector.dart';
import 'package:go_router_modular/src/core/injection_manager.dart';

/// Simplified Bind class that delegates to auto_injector
///
/// ## Interface Registration (Padrão auto_injector)
///
/// O auto_injector NÃO faz auto-resolution de interfaces automaticamente.
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
class Bind<T> {
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

  /// Register a bind using auto_injector - seguindo o padrão do flutter_modular
  static void register<T>(Bind<T> bind) {
    try {
      final injector = InjectionManager.instance.injector;
      final key = bind.key;

      // Verificar se já existe um bind para este tipo/key
      try {
        injector.get<T>(key: key);
        return; // Já existe, não registrar novamente
      } catch (e) {
        // Não existe, continuar com o registro
      }

      // IMPORTANTE: Seguir o padrão do flutter_modular
      // 1. uncommit() antes de adicionar novos binds
      injector.uncommit();

      // 2. Registrar o bind
      if (bind.isSingleton) {
        if (bind.isLazy) {
          injector.addLazySingleton<T>(
            () => bind.factoryFunction(Injector()),
            key: key,
          );
        } else {
          injector.addSingleton<T>(
            () => bind.factoryFunction(Injector()),
            key: key,
          );
        }
      } else {
        injector.add<T>(
          () => bind.factoryFunction(Injector()),
          key: key,
        );
      }

      // 3. commit() após registrar o bind
      injector.commit();

      // Auto-register interfaces if T is a concrete implementation
      // DESABILITADO: Criar instâncias temporárias causa problemas com contadores em testes
      // TODO: Implementar auto-resolution sem criar instâncias temporárias
      // _registerInterfacesForType<T>(bind);
    } catch (e) {
      log('❌ Failed to register bind for type ${T.toString()} - $e', name: "GO_ROUTER_MODULAR");
      throw GoRouterModularException('❌ Bind registration failed for type ${T.toString()}: $e');
    }
  }

  /// Auto-register interfaces for a concrete type
  /// Cria uma instância temporária para descobrir interfaces e as registra
  static void _registerInterfacesForType<T>(Bind<T> bind) {
    try {
      // Criar uma instância temporária para descobrir as interfaces
      final tempInstance = bind.factoryFunction(Injector());

      // Verificar interfaces conhecidas e registrá-las
      final injector = InjectionManager.instance.injector;

      // IService
      if (tempInstance is IService) {
        try {
          injector.get<IService>(key: bind.key);
        } catch (e) {
          injector.uncommit();
          if (bind.isSingleton) {
            // Para singletons, retornar sempre a mesma instância
            injector.addLazySingleton<IService>(
              () => injector.get<T>(key: bind.key) as IService,
              key: bind.key,
            );
          } else {
            injector.add<IService>(
              () => bind.factoryFunction(Injector()) as IService,
              key: bind.key,
            );
          }
          injector.commit();
          _interfaceImplementations[IService] = T;
        }
      }

      // IRepository
      if (tempInstance is IRepository) {
        try {
          injector.get<IRepository>(key: bind.key);
        } catch (e) {
          injector.uncommit();
          if (bind.isSingleton) {
            injector.addLazySingleton<IRepository>(
              () => injector.get<T>(key: bind.key) as IRepository,
              key: bind.key,
            );
          } else {
            injector.add<IRepository>(
              () => bind.factoryFunction(Injector()) as IRepository,
              key: bind.key,
            );
          }
          injector.commit();
          _interfaceImplementations[IRepository] = T;
        }
      }

      // IController
      if (tempInstance is IController) {
        try {
          injector.get<IController>(key: bind.key);
        } catch (e) {
          injector.uncommit();
          if (bind.isSingleton) {
            injector.addLazySingleton<IController>(
              () => injector.get<T>(key: bind.key) as IController,
              key: bind.key,
            );
          } else {
            injector.add<IController>(
              () => bind.factoryFunction(Injector()) as IController,
              key: bind.key,
            );
          }
          injector.commit();
          _interfaceImplementations[IController] = T;
        }
      }

      // IBindSingleton
      if (tempInstance is IBindSingleton) {
        try {
          injector.get<IBindSingleton>(key: bind.key);
        } catch (e) {
          injector.uncommit();
          if (bind.isSingleton) {
            injector.addLazySingleton<IBindSingleton>(
              () => injector.get<T>(key: bind.key) as IBindSingleton,
              key: bind.key,
            );
          } else {
            injector.add<IBindSingleton>(
              () => bind.factoryFunction(Injector()) as IBindSingleton,
              key: bind.key,
            );
          }
          injector.commit();
          _interfaceImplementations[IBindSingleton] = T;
        }
      }

      // Limpar a instância temporária se ela for Disposable
      if (tempInstance is Disposable) {
        try {
          tempInstance.dispose();
        } catch (_) {}
      }
    } catch (e) {
      // Ignorar erros de auto-registration - não é crítico
      if (kDebugMode) {
        log('⚠️ Failed to auto-register interfaces for ${T.toString()}: $e', name: "GO_ROUTER_MODULAR");
      }
    }
  }

  /// Get instance using auto_injector
  static T get<T>({String? key}) {
    try {
      return InjectionManager.instance.injector.get<T>(key: key);
    } catch (e) {
      // Tentar resolver pela implementação conhecida se T for uma interface
      if (_interfaceImplementations.containsKey(T)) {
        try {
          final injector = InjectionManager.instance.injector;

          // Tentar obter a implementação e convertê-la para a interface
          final implementation = injector.get(key: key);
          if (implementation is T) {
            return implementation;
          }
        } catch (_) {
          // Ignorar e lançar o erro original
        }
      }

      log('❌ Bind not found for type: ${T.toString()}${key != null ? ' with key: $key' : ''}', name: "GO_ROUTER_MODULAR");
      throw GoRouterModularException('❌ Bind not found for type ${T.toString()}${key != null ? ' with key: $key' : ''}');
    }
  }

  /// Dispose singleton by type using auto_injector
  static void dispose<T>() {
    if (T == Object) return;

    try {
      // Dispose usando auto_injector - ele retorna a instância se existir
      final disposed = InjectionManager.instance.injector.disposeSingleton<T>();
      if (disposed != null) {
        // Chamar CleanBind para fazer cleanup
        CleanBind.fromInstance(disposed);
      }
    } catch (e) {
      // Ignorar erros de dispose - pode não existir
      log('⚠️ Failed to dispose bind: ${T.toString()} - $e', name: "GO_ROUTER_MODULAR");
    }
  }

  /// Dispose singleton by key using auto_injector
  static void disposeByKey(String key) {
    try {
      // Dispose usando auto_injector - ele retorna a instância se existir
      final disposed = InjectionManager.instance.injector.disposeSingleton<dynamic>(key: key);
      if (disposed != null) {
        // Chamar CleanBind apenas uma vez
        CleanBind.fromInstance(disposed);
      }
    } catch (e) {
      // Ignorar erros de dispose - pode não existir
      log('⚠️ Failed to dispose bind with key: $key - $e', name: "GO_ROUTER_MODULAR");
    }
  }

  /// Dispose singleton by type using auto_injector
  static void disposeByType(Type type) {
    try {
      // Para disposeByType, precisamos tentar diferentes abordagens
      // já que auto_injector não tem um método direto para isso
      final disposed = InjectionManager.instance.injector.disposeSingleton<dynamic>();
      if (disposed != null && disposed.runtimeType == type) {
        // Chamar CleanBind apenas uma vez
        CleanBind.fromInstance(disposed);
      }
    } catch (e) {
      // Ignorar erros de dispose - pode não existir
      log('⚠️ Failed to dispose bind by type: $type - $e', name: "GO_ROUTER_MODULAR");
    }
  }

  /// Clear all binds - not recommended in production
  static void clearAll() {
    try {
      _interfaceImplementations.clear();

      // Usar o método de limpeza do InjectionManager
      InjectionManager.instance.clearAllForTesting();
      log('🧹 Cleared all binds using InjectionManager', name: "GO_ROUTER_MODULAR");
    } catch (e) {
      log('⚠️ clearAll() failed: $e', name: "GO_ROUTER_MODULAR");
    }
  }

  /// Get all available keys - not directly supported by auto_injector
  static List<String> getAllKeys() {
    log('⚠️ getAllKeys() is not directly supported with auto_injector', name: "GO_ROUTER_MODULAR");
    return [];
  }

  /// Factory methods for creating binds
  static Bind<T> singleton<T>(T Function(Injector i) builder, {String? key}) {
    return Bind<T>(builder, isSingleton: true, isLazy: true, key: key);
  }

  static Bind<T> factory<T>(T Function(Injector i) builder, {String? key}) {
    return Bind<T>(builder, isSingleton: false, isLazy: false, key: key);
  }

  static Bind<T> lazy<T>(T Function(Injector i) builder, {String? key}) {
    return Bind<T>(builder, isSingleton: true, isLazy: true, key: key);
  }
}

// Interfaces para os testes
abstract class IService {
  String get name;
  void doSomething();
}

abstract class IRepository {
  String get data;
  void save(String value);
}

abstract class IController {
  void handleRequest();
}

abstract class IBindSingleton {}
