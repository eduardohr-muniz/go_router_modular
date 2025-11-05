import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/core/bind/bind.dart';

/// Interface somente leitura para acesso a dependências
/// Expõe apenas o método `get`, sem permitir registro de binds
abstract interface class InjectorReader {
  T get<T>({String? key});
}

class Injector implements InjectorReader {
  @override
  T get<T>({String? key}) => Bind.get<T>(key: key);

  // Lista temporária para coletar binds durante o registro
  final List<Bind<Object>> _registeringBinds = [];
  bool _isRegistering = false;

  /// Inicia o modo de registro de binds
  void startRegistering() {
    _registeringBinds.clear();
    _isRegistering = true;
  }

  /// Finaliza o registro e retorna os binds coletados
  List<Bind<Object>> finishRegistering() {
    _isRegistering = false;
    final binds = List<Bind<Object>>.from(_registeringBinds);
    _registeringBinds.clear();
    return binds;
  }

  /// Adiciona um bind factory (cria nova instância a cada chamada)
  void addFactory<T>(T Function(Injector i) factory, {String? key}) {
    if (!_isRegistering) {
      throw StateError('addFactory chamado fora do modo de registro. Chame startRegistering() primeiro.');
    }
    final bind = Bind<T>(factory, isSingleton: false, isLazy: false, key: key);
    _registeringBinds.add(bind as Bind<Object>);
  }

  /// Adiciona um bind factory (alias para addFactory)
  void add<T>(T Function(Injector i) factory, {String? key}) {
    addFactory<T>(factory, key: key);
  }

  /// Adiciona um bind singleton (instância única criada imediatamente)
  void addSingleton<T>(T Function(Injector i) factory, {String? key}) {
    if (!_isRegistering) {
      throw StateError('addSingleton chamado fora do modo de registro. Chame startRegistering() primeiro.');
    }
    final bind = Bind<T>(factory, isSingleton: true, isLazy: false, key: key);
    _registeringBinds.add(bind as Bind<Object>);
  }

  /// Adiciona um bind lazy singleton (instância única criada sob demanda)
  void addLazySingleton<T>(T Function(Injector i) factory, {String? key}) {
    if (!_isRegistering) {
      throw StateError('addLazySingleton chamado fora do modo de registro. Chame startRegistering() primeiro.');
    }
    final bind = Bind<T>(factory, isSingleton: true, isLazy: true, key: key);
    _registeringBinds.add(bind as Bind<Object>);
  }
}
