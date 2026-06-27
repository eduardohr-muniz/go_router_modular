import 'package:go_router_modular/src/di/bind.dart';

/// Read-only interface for dependency access.
abstract interface class InjectorReader {
  T get<T>({String? key});
}

class Injector implements InjectorReader {
  @override
  T get<T>({String? key}) => Bind.get<T>(key: key);

  final List<Bind<Object>> _registeringBinds = [];
  bool _isRegistering = false;

  void startRegistering() {
    _registeringBinds.clear();
    _isRegistering = true;
  }

  List<Bind<Object>> finishRegistering() {
    _isRegistering = false;
    final binds = List<Bind<Object>>.from(_registeringBinds);
    _registeringBinds.clear();
    return binds;
  }

  void addFactory<T>(T Function(Injector i) factory, {String? key}) {
    if (!_isRegistering) {
      throw StateError('addFactory called outside registration mode. Call startRegistering() first.');
    }
    final bind = Bind<T>(factory, isSingleton: false, isLazy: false, key: key);
    _registeringBinds.add(bind as Bind<Object>);
  }

  void add<T>(T Function(Injector i) factory, {String? key}) {
    addFactory<T>(factory, key: key);
  }

  void addSingleton<T>(T Function(Injector i) factory, {String? key}) {
    if (!_isRegistering) {
      throw StateError('addSingleton called outside registration mode. Call startRegistering() first.');
    }
    final bind = Bind<T>(factory, isSingleton: true, isLazy: false, key: key);
    _registeringBinds.add(bind as Bind<Object>);
  }

  void addLazySingleton<T>(T Function(Injector i) factory, {String? key}) {
    if (!_isRegistering) {
      throw StateError('addLazySingleton called outside registration mode. Call startRegistering() first.');
    }
    final bind = Bind<T>(factory, isSingleton: true, isLazy: true, key: key);
    _registeringBinds.add(bind as Bind<Object>);
  }
}
