import 'package:go_router_modular/src/di/bind.dart';
import 'package:go_router_modular/src/di/bind_identifier.dart';

/// Read-only interface for dependency access.
abstract interface class InjectorReader {
  T get<T>({String? key});
}

class Injector implements InjectorReader {
  @override
  T get<T>({String? key}) {
    final instance = Bind.get<T>(key: key);
    final sink = _scopeRecordingSink;
    if (sink != null) {
      final type = (instance as Object).runtimeType;
      sink.add(BindIdentifier(type, key ?? type.toString()));
    }
    return instance;
  }

  /// Coletor de dependências resolvidas durante o commit, para validação de
  /// escopo por módulo. Ativo apenas entre [beginScopeRecording] e
  /// [endScopeRecording]; fora disso, `get` não grava nada.
  List<BindIdentifier>? _scopeRecordingSink;

  void beginScopeRecording() => _scopeRecordingSink = <BindIdentifier>[];

  List<BindIdentifier> endScopeRecording() {
    final recorded = _scopeRecordingSink ?? const <BindIdentifier>[];
    _scopeRecordingSink = null;
    return List<BindIdentifier>.of(recorded);
  }

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
