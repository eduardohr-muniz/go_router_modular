import 'dart:developer';
import 'package:auto_injector/auto_injector.dart' as ai;
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/core/injection_manager/injection_manager.dart';

/// Injector com contexto de módulo - Segue o padrão do flutter_modular
/// Cada módulo tem seu próprio AutoInjector, que é adicionado ao injector principal
class ModuleInjector extends Injector {
  final ai.AutoInjector _moduleInjector;

  ModuleInjector(this._moduleInjector);

  @override
  void add<T extends Object>(dynamic builder, {String? key}) {
    log('📝 [ModuleInjector.add] T=$T, key=$key, builder type: ${builder.runtimeType}', name: "GO_ROUTER_MODULAR");
    if (builder is Function) {
      // Se T é Object, chamar sem tipo e deixar o auto_injector inferir
      if (T == Object) {
        log('⚠️ [ModuleInjector.add] T=Object! Sem tipagem, o auto_injector vai inferir o tipo da implementação concreta', name: "GO_ROUTER_MODULAR");
        log('⚠️ [ModuleInjector.add] Para resolução automática de interfaces, use: i.add<Interface>(Implementation.new)', name: "GO_ROUTER_MODULAR");
        // Registrar sem tipo e deixar o auto_injector inferir a implementação
        _moduleInjector.add(builder, key: key);
      } else {
        log('✅ [ModuleInjector.add] Tipando como $T', name: "GO_ROUTER_MODULAR");

        // INFERÊNCIA AUTOMÁTICA: Se T é uma interface e builder retorna uma implementação concreta,
        // registrar TAMBÉM a implementação concreta automaticamente APENAS SEM KEY
        // (para não causar conflito com keys da interface)
        try {
          final tempInstance = builder();
          final concreteType = tempInstance.runtimeType;

          log('🔍 [ModuleInjector.add] Inferindo tipo concreto: $concreteType', name: "GO_ROUTER_MODULAR");

          // Se T é uma interface abstrata e concreteType é diferente de T,
          // registrar TAMBÉM concreteType APENAS SEM KEY para permitir i.get<Concrete>()
          if (T != Object && T != concreteType && key == null) {
            log('✅ [ModuleInjector.add] Auto-registrando implementação concreta: $concreteType (apenas sem key)', name: "GO_ROUTER_MODULAR");
            try {
              // Tentar registrar a implementação concreta sem key
              _moduleInjector.add(builder);
            } catch (e) {
              // Se já existe, ignorar
              log('⚠️ [ModuleInjector.add] Implementação concreta já existe: $e', name: "GO_ROUTER_MODULAR");
            }
          }
        } catch (e) {
          log('⚠️ [ModuleInjector.add] Erro na inferência automática: $e', name: "GO_ROUTER_MODULAR");
        }

        // Passar o tipo explicitamente
        _moduleInjector.add<T>(builder, key: key);
      }
    } else {
      log('🔍 [ModuleInjector.add] Instância direta fornecida', name: "GO_ROUTER_MODULAR");
      _moduleInjector.add<T>(() => builder, key: key);
    }
  }

  @override
  void addSingleton<T extends Object>(dynamic builder, {String? key}) {
    if (builder is Function) {
      // Se T é Object, chamar sem tipo e deixar o auto_injector inferir
      if (T == Object) {
        _moduleInjector.addSingleton(builder, key: key);
      } else {
        _moduleInjector.addSingleton<T>(builder, key: key);
      }
    } else {
      _moduleInjector.addSingleton<T>(() => builder, key: key);
    }
  }

  @override
  void addLazySingleton<T extends Object>(dynamic builder, {String? key}) {
    if (builder is Function) {
      // Se T é Object, chamar sem tipo e deixar o auto_injector inferir
      if (T == Object) {
        _moduleInjector.addLazySingleton(builder, key: key);
      } else {
        _moduleInjector.addLazySingleton<T>(builder, key: key);
      }
    } else {
      _moduleInjector.addLazySingleton<T>(() => builder, key: key);
    }
  }

  @override
  T get<T extends Object>({String? key}) {
    // Rastrear a cadeia de dependências
    final dependencyChain = InjectionManager.instance.getCurrentDependencyChain();
    log('🔍 [ModuleInjector.get] Buscando T=$T, key=$key (chain: $dependencyChain)', name: "GO_ROUTER_MODULAR");

    try {
      final result = _moduleInjector.get<T>(key: key);
      log('✅ [ModuleInjector.get] Encontrado no injector do módulo', name: "GO_ROUTER_MODULAR");
      return result;
    } catch (e) {
      log('⚠️ [ModuleInjector.get] Não encontrou no injector do módulo: $e, tentando BindResolver...', name: "GO_ROUTER_MODULAR");

      // Se não encontrou no injector do módulo, tentar através do sistema de resolução
      // Isso permite acessar binds do AppModule
      // A cadeia de dependências já é rastreada em resolve(), então não precisa adicionar aqui
      return InjectionManager.instance.getWithModuleContext<T>(key: key);
    }
  }

  /// Registra uma implementação automaticamente sob a interface correspondente
  void addAs<TInterface extends Object, TImplementation extends TInterface>(
    TInterface Function() builder, {
    String? key,
  }) {
    // Registrar a implementação concreta
    _moduleInjector.add<TImplementation>(builder, key: key);

    // Registrar a interface apontando para a implementação
    _moduleInjector.add<TInterface>(() => _moduleInjector.get<TImplementation>(key: key) as TInterface, key: key);
  }

  /// Registra um singleton automaticamente sob a interface correspondente
  void addSingletonAs<TInterface extends Object, TImplementation extends TInterface>(
    TInterface Function() builder, {
    String? key,
  }) {
    // Registrar a implementação concreta
    _moduleInjector.addSingleton<TImplementation>(builder, key: key);

    // Registrar a interface apontando para a implementação
    _moduleInjector.addSingleton<TInterface>(() => _moduleInjector.get<TImplementation>(key: key) as TInterface, key: key);
  }

  /// Registra um lazy singleton automaticamente sob a interface correspondente
  void addLazySingletonAs<TInterface extends Object, TImplementation extends TInterface>(
    TInterface Function() builder, {
    String? key,
  }) {
    // Registrar a implementação concreta
    _moduleInjector.addLazySingleton<TImplementation>(builder, key: key);

    // Registrar a interface apontando para a implementação
    _moduleInjector.addLazySingleton<TInterface>(() => _moduleInjector.get<TImplementation>(key: key) as TInterface, key: key);
  }
}
