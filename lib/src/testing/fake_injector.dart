import 'package:go_router_modular/src/di/injector.dart';

/// Erro lançado quando [FakeInjector] não tem o tipo solicitado registrado.
///
/// Object Calisthenics:
///   - Uma única variável de instância (Regra 8)
class FakeInjectorMissingBindError extends Error {
  final Type missingType;

  FakeInjectorMissingBindError(this.missingType);

  @override
  String toString() =>
      'FakeInjectorMissingBindError: nenhum bind registrado para o tipo $missingType.\n'
      'Use FakeInjector.empty().add<$missingType>(instance) para registrá-lo.';
}

// ─────────────────────────────────────────────────────────────────────────────

/// Implementação falsa de [InjectorReader] para testes unitários.
///
/// Permite resolver dependências sem o container global de binds, tornando
/// testes de serviços, use cases e módulos rápidos e isolados.
///
/// Uso:
/// ```dart
/// final injector = FakeInjector.empty()
///     .add<PaymentGateway>(FakePaymentGateway())
///     .add<UserRepository>(FakeUserRepository());
///
/// final service = OrderService(
///   injector.get<PaymentGateway>(),
///   injector.get<UserRepository>(),
/// );
/// ```
///
/// Object Calisthenics:
///   - Uma única variável de instância (Regra 8)
///   - Imutável — `add` retorna novo injector (sem setters — Regra 9)
///   - Falha com erro descritivo em vez de retornar null (sem primitivos nus)
class FakeInjector implements InjectorReader {
  final Map<Type, dynamic> _instances;

  FakeInjector.empty() : _instances = const {};

  FakeInjector._withMap(Map<Type, dynamic> instances)
      : _instances = Map.unmodifiable(instances);

  /// Retorna um novo [FakeInjector] com [instance] registrada para o tipo [T].
  ///
  /// O injector original não é modificado.
  FakeInjector add<T>(T instance) {
    return FakeInjector._withMap({..._instances, T: instance});
  }

  /// Resolve a instância do tipo [T].
  ///
  /// Lança [FakeInjectorMissingBindError] se o tipo não foi registrado.
  @override
  T get<T>({String? key}) {
    final instance = _instances[T];
    if (instance == null) throw FakeInjectorMissingBindError(T);
    return instance as T;
  }
}
