import 'package:go_router_modular/src/di/bind.dart';

/// Coleção imutável de registros de DI que será reaplicada a cada [setUp].
///
/// Permite configurar binds compartilhados entre todos os testes de um grupo
/// de forma fluente, antes da chamada de [setUp].
///
/// Uso:
/// ```dart
/// final template = BindTemplate.empty()
///     .withInstance<AppConfig>(AppConfig.test())
///     .withLazySingleton<ApiClient>(() => ApiClient());
///
/// // Na inicialização do scope:
/// template.registerAll(); // chamado pelo ModularTestScope.setUp()
/// ```
///
/// Object Calisthenics:
///   - Uma única variável de instância (Regra 8)
///   - Coleção de primeira classe de lambdas de registro (Regra 4)
///   - Imutável — cada `withXxx` retorna nova instância (sem setters — Regra 9)
class BindTemplate {
  // Each entry is a zero-argument function that calls Bind.register,
  // capturing the correct generic type T via closure.
  final List<void Function()> _registrations;

  BindTemplate.empty() : _registrations = const [];

  BindTemplate._(List<void Function()> registrations)
      : _registrations = registrations;

  /// Adiciona um singleton (instância já construída).
  BindTemplate withInstance<T>(T instance) {
    return BindTemplate._([
      ..._registrations,
      () => Bind.register(Bind.singleton<T>((_) => instance)),
    ]);
  }

  /// Adiciona uma factory (nova instância a cada resolução).
  BindTemplate withFactory<T>(T Function() factory) {
    return BindTemplate._([
      ..._registrations,
      () => Bind.register(Bind.add<T>((_) => factory())),
    ]);
  }

  /// Adiciona um lazy singleton (construído uma vez na primeira resolução).
  BindTemplate withLazySingleton<T>(T Function() factory) {
    return BindTemplate._([
      ..._registrations,
      () => Bind.register(Bind.lazySingleton<T>((_) => factory())),
    ]);
  }

  /// Registra todos os binds no container global.
  ///
  /// Chamado automaticamente por [ModularTestScope.setUp].
  void registerAll() {
    for (final register in _registrations) {
      register();
    }
  }
}
