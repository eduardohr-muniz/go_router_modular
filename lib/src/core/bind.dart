import 'dart:developer';

import 'package:auto_injector/auto_injector.dart' as ai;
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
    } catch (e) {
      throw GoRouterModularException('❌ Bind registration failed for type ${T.toString()}: $e');
    }
  }

  /// Get instance using auto_injector
  static T get<T>({String? key}) {
    try {
      final manager = InjectionManager.instance;
      final contextInjector = manager.getContextualInjector();

      // Tentar primeiro no injector contextual (módulo atual)
      // Sem fallback - falha rápido na primeira tentativa
      final result = contextInjector.get<T>(key: key);
      return result;
    } catch (e, s) {
      // Propagar o erro original imediatamente com o stack trace completo
      if (e is ai.UnregisteredInstance) {
        final className = e.classNames.last;
        log(
          '❌ Bind not found: $className\n'
          '📍 Make sure to register it in the module binds() method:\n'
          '   ⚠️  IMPORTANT: Always use explicit typing!\n'
          '   ✅ i.add<$className>($className.new);\n'
          '   or\n'
          '   ✅ i.add<$className>(() => $className());\n'
          '\n'
          '   ❌ DO NOT: i.add(() => $className()); // Missing type!',
          name: 'GO_ROUTER_MODULAR',
        );
      }

      Error.throwWithStackTrace(e, s);
    }
  }

  /// Dispose singleton by type using auto_injector
  static void dispose<T>() {
    if (T == Object) return;

    try {
      final disposed = InjectionManager.instance.injector.disposeSingleton<T>();
      if (disposed != null) {
        CleanBind.fromInstance(disposed);
      }
    } catch (e) {
      // Ignorar erros de dispose - pode não existir
    }
  }

  /// Dispose singleton by key using auto_injector
  static void disposeByKey(String key) {
    try {
      final disposed = InjectionManager.instance.injector.disposeSingleton<dynamic>(key: key);
      if (disposed != null) {
        CleanBind.fromInstance(disposed);
      }
    } catch (e) {
      // Ignorar erros de dispose - pode não existir
    }
  }

  /// Clear all binds - not recommended in production
  static void clearAll() {
    try {
      _interfaceImplementations.clear();
      InjectionManager.instance.clearAllForTesting();
    } catch (e) {
      // Ignorar erros
    }
  }

  /// Get all available keys - not directly supported by auto_injector
  static List<String> getAllKeys() {
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
